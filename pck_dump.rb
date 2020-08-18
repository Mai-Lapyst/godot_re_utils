#! /usr/bin/ruby

require "optparse"
require_relative "./godot_utils/pckfile.rb"

$options = {
    :extract_path => nil,
    :force_extraction => false,
    :skip_broken => true,
    :verbose => false,
    :align_pck => true,
};
$optparse = OptionParser.new do |opts|
    opts.banner =   "Usage: pck_tool.rb [options] <operation> ...\n\n" +
                    "Operations:\n" +
                    "\te <pckfile> <dir>\textract files from the given pck file into the given directory\n" +
                    "\tp <pckfile> <dir>\tpack the files in the given directory into the given pckfile\n" +
                    "\tl <pckfile>\t\tlist content\n" +
                    "\tv <pckfile> <path>\tview the given file that is packed in the given pckfile\n" +
                    "\nOptions:\n";

    opts.on("-f", "--force", "Force extraction") do
        $options[:force_extraction] = true;
    end

    opts.on("--[no-]skip-broken", "Skips broken files (on extraction and list)") do |flag|
        $options[:skip_broken] = flag;
    end

    opts.on("--engine-version=VERSION", "Sets the engine version for the generated pck file") do |version|
        $options[:engine_version] = Godot::PckFile::Version::parse(version);
    end

    opts.on("--[no-]align", "Enables/Disables alignment of the pck file when packaging") do |flag|
        $options[:align_pck] = flag;
    end

    opts.on("--[no-]decode", "Dont decode any binary files") do |flag|
        $options[:decode_projsettings] = flag;
    end

    opts.on("-v", "--verbose", "Prints more output") do
        $options[:verbose] = true;
    end
end
$optparse.parse!

if (ARGV.size < 1) then
    puts($optparse);
    exit(1);
end

def print_error(e)
    puts("Error: #{e}");
    if ($options[:verbose]) then
        puts("Traceback (most recent call last):");
        last = e.backtrace.shift();
        e.backtrace.reverse.each_with_index { |line,idx|
            puts("\t#{e.backtrace.size-idx}: from #{line}")
        };
        puts("#{last}");
    end
end

case ARGV[0]
when "e"
    if (ARGV.size < 3) then
        puts($optparse);
        exit(1);
    end
    $pck = Godot::PckFile.new(ARGV[1], $options);
    $pck.parse();
    begin
        $pck.extract_all(ARGV[2]);
    rescue Exception => e
        print_error(e);
        exit(1);
    end
when "p"
    if (ARGV.size < 3) then
        puts($optparse);
        exit(1);
    end
    pp $options
    $pck = Godot::PckFile.new(ARGV[1], $options);
    $pck.engine_version = $options[:engine_version] if ($options[:engine_version]);
    begin
        $pck.pack(ARGV[2]);
    rescue Exception => e
        print_error(e);
        exit(1);
    end
when "l"
    if (ARGV.size < 2) then
        puts($optparse);
        exit(1);
    end
    $pck = Godot::PckFile.new(ARGV[1], $options);
    $pck.parse();
    $pck.print_out();
when "v"
    if (ARGV.size < 3) then
        puts($optparse);
        exit(1);
    end
    $pck = Godot::PckFile.new(ARGV[1], $options);
    $pck.parse();
    begin
        $pck.view_file(ARGV[2]);
    rescue Exception => e
        print_error(e);
        exit(1);
    end
else
    puts("Unknown operation, abort!");
    exit(1);
end
