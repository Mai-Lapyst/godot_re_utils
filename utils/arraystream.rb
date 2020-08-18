class ArrayStream
    attr_accessor :pos

    def initialize(data)
        @pos = 0;
        @data = data;
    end

    def size
        return @data.size;
    end

    def read_bytes(len)
        if (@data.size <= (@pos+len-1)) then
            raise "ArrayStream: End of data";
        end
        ret = @data[@pos ... (@pos+len)];
        @pos += len;
        return ret;
    end

    def read_f32()
        return read_bytes(4).unpack("F")[0];
    end

    def read_f64()
        return read_bytes(8).unpack("D")[0];
    end

    def read_i8()
        if (@data.size <= @pos) then
            raise "ArrayStream: End of data";
        end
        ret = @data[@pos].ord;
        @pos += 1;
        return ret;
    end

    def read_i16()
        if (@data.size <= (@pos+1)) then
            raise "ArrayStream: End of data";
        end
        ret = @data[@pos].ord | (@data[@pos+1].ord << 8);
        @pos += 2;
        return ret;
    end

    def read_i32(peek = false)
        if (@data.size <= (@pos+3)) then
            raise "ArrayStream: End of data";
        end
        ret =   @data[@pos].ord | 
                (@data[@pos+1].ord << 8) |
                (@data[@pos+2].ord << 16) |
                (@data[@pos+3].ord << 24);
        @pos += 4 unless (peek);
        return ret;
    end

    def read_i64()
        if (@data.size <= (@pos+7)) then
            raise "ArrayStream: End of data";
        end
        ret =   @data[@pos].ord | 
                (@data[@pos+1].ord << 8) |
                (@data[@pos+2].ord << 16) |
                (@data[@pos+3].ord << 24) |
                (@data[@pos+4].ord << 32) |
                (@data[@pos+5].ord << 40) |
                (@data[@pos+6].ord << 48) |
                (@data[@pos+7].ord << 56);
        @pos += 8;
        return ret;
    end

end