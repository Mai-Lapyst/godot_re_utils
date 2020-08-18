class IOStream

    def initialize(io)
        if (io.class != File) then
            raise ArgumentError.new("Argument #1 needs to be an File object");
        end
        @io = io;
    end

    def pos=(new_pos)
        @io.seek(new_pos, IO::SEEK_SET);
        return nil;
    end

    def pos
        return @io.tell;
    end

    def size
        return @io.size;
    end

    def read_bytes(len, peek = false)
        ret = @io.read(len);
        @io.seek(-len, IO::SEEK_CUR) if (peek);
        return ret;
    end

    def write_bytes(bytes)
        @io.write(bytes);
    end

    def read_f32()
        return read_bytes(4).unpack("F")[0];
    end

    def read_f64(peek = false)
        return read_bytes(8, peek).unpack("D")[0];
    end

    def read_i8(peek = false)
        return read_bytes(1, peek).unpack("c")[0];
    end

    def read_i16(peek = false)
        return read_bytes(2, peek).unpack("s")[0];
    end

    def read_i32(peek = false)
        return read_bytes(4, peek).unpack("l")[0];
    end

    def write_i32(val)
        write_bytes([val].pack("l"));
    end

    def read_i64(peek = false)
        return read_bytes(8, peek).unpack("q")[0];
    end

    def write_i64(val)
        write_bytes([val].pack("q"));
    end

end