require_relative "../utils/iostream.rb"
require_relative "../utils/arraystream.rb"
require_relative "./project_settings.rb"
require_relative "./binary_marshall.rb"
require_relative "./text_marshall.rb"

require 'digest'

module Godot
    class PckFile
        class Version
            attr_reader :major;
            attr_reader :minor;
            attr_reader :patch;
    
            def initialize(major, minor, patch)
                @major = major;
                @minor = minor;
                @patch = patch;
            end
    
            def revision
                return @patch;
            end

            def write(data)
                data.write_i32(@major);
                data.write_i32(@minor);
                data.write_i32(@patch);
            end

            def self.parse(str)
                data = str.split(".");
                if (data.size != 3) then
                    raise ArgumentError.new("Argument #1 must be in the format x.x.x!");
                end
                return Version.new(Integer(data[0]), Integer(data[1]), Integer(data[2]));
            end
        end
    
        class FileEntry
            attr_reader :path;
            attr_reader :offset;
            attr_reader :size;
            attr_reader :md5;
    
            def initialize(path, offset, size, md5, broken)
                @path = path;
                @offset = offset;
                @size = size;
                @md5 = md5;
                @broken = broken;
            end

            def broken?
                return @broken;
            end
        end
    
        class UnsupportedPckVersion < Exception
        end

        attr_accessor :format_version;
        attr_accessor :engine_version;
    
        def initialize(path, options = {})
            @pos = 0;

            get_option = ->(sym, default) {
                return options[sym] if (options[sym] != nil);
                return default;
            };

            @force_extraction = get_option.call(:force_extraction, false);
            @verbose = get_option.call(:verbose, false);
            @skip_broken = get_option.call(:skip_broken, true);
            @decode_projsettings = get_option.call(:decode_projsettings, true);
            @align_pck = get_option.call(:align_pck, true);
            @path = path;

            @format_version = 1;
            @engine_version = Version.new(3,2,2);
        end
    
        def pack(dir)
            @data = IOStream.new(File.open(@path, "wb"));
            
            @data.write_i32(0x43504447);
            @data.write_i32(@format_version);
            @engine_version.write(@data);

            for i in 0...16 do
                @data.write_i32(0);
            end

            file_paths = Dir.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).select { |file| File.file?(file) };
            file_paths.reject! { |file| File.basename(file) == "project.godot" };

            @file_count = file_paths.size;
            @data.write_i32(@file_count);

            offset = (4 + 4 + 12 + (16 * 4));
            for path in file_paths do
                _path = path.gsub("#{dir}/","res://");
                offset += 4 + _path.size;
                if (@align_pck) then
                    offset += (offset % 4)>0 ? 4-(offset % 4) : 0;
                end
                offset += 8 + 8 + 16;
            end
            if (@align_pck) then
                offset += (offset%16)>0 ? 16-(offset%16) : 0;
            end

            file_offsets = [];
            for i in 0 ... @file_count do
                path = file_paths[i].gsub("#{dir}/","res://");
                size = File.stat(file_paths[i]).size;
                puts("Pack: #{file_paths[i]} -> #{path} (#{calcSize(size)})");

                path_size = path.size;
                if (@align_pck) then
                    path_size += (path_size%4)>0 ? 4-(path_size%4) : 0;
                end
                @data.write_i32(path_size);

                @data.write_bytes(path);
                if (@align_pck) then
                    @data.write_bytes("\x00" * (path_size-path.size));
                end

                @data.write_i64(offset);
                file_offsets[i] = offset;
                
                offset += size;
                if (@align_pck) then
                    offset += (offset%16)>0 ? 16-(offset%16) : 0;
                end

                @data.write_i64(size);

                digest = Digest::MD5.digest( IO.read(file_paths[i], mode: "rb") );
                @data.write_bytes(digest);
            end

            for i in 0 ... @file_count do
                @data.pos = file_offsets[i];
                size = File.stat(file_paths[i]).size;
                @data.write_bytes(IO.read(file_paths[i], mode: "rb"));
                if (@align_pck) then
                    j = (size%16)>0 ? 16-(size%16) : 0;
                    @data.write_bytes("\x00" * j);
                end
            end
        end

        def parse()
            @data = IOStream.new(File.open(@path, "rb"));
            @data.pos = 0;

            magic = @data.read_i32();
            if (magic != 0x43504447) then
                raise IOError.new("Invalid .pck file, embedded pck files are NIY!");
            end
            
            @format_version = @data.read_i32();
            if (@format_version > 1) then
                raise UnsupportedPckVersion.new("Pack version unsupported: #{@format_version}");
            end
    
            @engine_version = Version.new(@data.read_i32(), @data.read_i32(), @data.read_i32());
           
            # skip 16 * 4 bytes... idk why
            for i in 0...16 do
                @data.read_i32();
            end
            
            @file_count = @data.read_i32();
            @files = [];
            #puts("[dbg] file_count #{@file_count}") if (@verbose);
            for i in 0 ... @file_count do
                #printf("[dbg] file #{i}: ") if (@verbose);

                path_len = @data.read_i32();
                path = @data.read_bytes(path_len);
                path.gsub!("\x00", "");

                #printf("#{path} ") if (@verbose);
    
                # -> replace some things in the path...
    
                offset = @data.read_i64();
                #printf("#{offset} ") if (@verbose);

                size   = @data.read_i64();
                #printf("#{size} \n") if (@verbose);

                md5    = @data.read_bytes(16);

                pos = @data.pos;
                @data.pos = offset;
                digest = Digest::MD5.digest(@data.read_bytes(size));
                @data.pos = pos;

                broken = (md5 != digest);

                @files.push(FileEntry.new(path, offset, size, md5, broken));
            end
        end
    
        private
        def calcSize(size)
            return "#{size} byte"  if (size <= 1);
            return "#{size} bytes" if (size <= 1024);
            ret = size;
            i = 0;
            while (ret > 1024 && i <= 3) do
                ret /= 1024;
                i += 1;
            end
            size_letters = ["","K","M","G","T"];
            return ret.to_s + " " + size_letters[i] + "B";
        end
    
        public
        def extract_all(path)
            if (!File.exists?(path)) then
                Dir.mkdir(path);
            end
            for f in @files do
                if (f.broken? && @skip_broken) then
                    puts("Skiping: \"#{f.path}\"");
                    next;
                end

                puts("Extract: \"#{f.path}\"");
    
                file_path_raw = f.path.gsub("res://", "");
                #puts("[dbg] file_path_raw = #{file_path_raw.inspect}");
    
                file_path = File.join(path, file_path_raw);
    
                if (File.exists?(file_path) && !@force_extraction) then
                    raise IOError.new("File \"#{file_path}\" already exists");
                end
    
                dir = File.dirname(file_path);
                Dir.mkdir(dir) unless File.exists?(dir);
    
                @data.pos = f.offset;
                file_data = @data.read_bytes(f.size);
                File.write(file_path, file_data, mode: "wb");
    
                if (File.basename(file_path) == "project.binary" && @decode_projsettings) then
                    puts("Decode: #{file_path} -> #{file_path.gsub(".binary", ".godot")}");

                    # decode the project.binary file...
                    file_data = IOStream.new(File.open(file_path, "rb"));
                    if (file_data.read_i32(true) != 0x47464345) then
                        puts(" - file is named \"project.binary\", but magic dosnt match; skip decoding...");
                    end

                    projsettings = Godot::ProjectSettings::parse(file_data);
                    projsettings.decode!(file_path.gsub(".binary", ".godot"));
                end
            end
        end
    
        public
        def print_out()
            puts("format version: #{@format_version}");
            puts("engine version: #{@engine_version.major}.#{@engine_version.minor}.#{@engine_version.patch}");
            puts("Files (#{@file_count}):");
            for f in @files do
                printf(" - \"#{f.path}\" (#{calcSize(f.size)})");
                if (f.broken?) then
                    printf(" (broken)");
                end
                puts("");

                if (@verbose) then
                    puts("    - offset: 0x#{f.offset.to_s(16).rjust(16, '0')}");
                    md5_str = f.md5.unpack("C"*16).map { |b| b.to_s(16).rjust(2, '0') }.join("");
                    puts("    - md5: #{md5_str}");
                end
            end
        end
    
        public
        def view_file(file)
            if (file.class == String) then
                begin
                    f = @files[Integer(file)];
                rescue
                    f = @files.find { |f|
                        f.path == file || f.path.gsub("res://","") == file
                    };
                    if (f == nil) then
                        puts("Could not find any files that match!");
                        exit(1);
                    end
                end
            else
                raise ArgumentError.new("Argument #1 needs to be a String");
            end
            puts("File: \"#{f.path}\" (#{calcSize(f.size)})");
            puts("--------------------------------------------------");
            @data.pos = f.offset;
            puts @data.read_bytes(f.size);
            puts("--------------------------------------------------");
        end
    end
end