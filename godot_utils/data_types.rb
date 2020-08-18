require_relative "../utils/iostream.rb"
require_relative "../utils/arraystream.rb"

module Godot
    class Vector2
        attr_accessor :x;
        attr_accessor :y;

        def initialize(x, y)
            @x = x;
            @y = y;
        end
    end

    class Vector3
        attr_accessor :x;
        attr_accessor :y;
        attr_accessor :z;

        def initialize(x, y, z)
            @x = x;
            @y = y;
            @z = z;
        end
    end

    class Rect2
        attr_accessor :position;
        attr_accessor :size;

        def initialize(pos, size)
            @position = pos;
            @size = size;
        end
    end

    class Transform2D
        attr_accessor :elements

        def initialize
            @elements = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]];
        end
    end

    class AABB
        attr_accessor :position;
        attr_accessor :size;

        def initialize(pos, size)
            @position = pos;
            @size = size;
        end
    end

    class Color
        attr_accessor :r;
        attr_accessor :g;
        attr_accessor :b;
        attr_accessor :a;

        def initialize(r, g, b, a)
            @r = r;
            @g = g;
            @b = b;
            @a = a;
        end
    end

    class NodePath
        attr_accessor :names
        attr_accessor :subnames
        attr_accessor :is_absolute

        def initialize(data)
            if (data.class != IOStream || data.class != ArrayStream) then
                raise Godot_BinSerial::Error.new("Argument must be of type IOStream or ArrayStream!");
            end

            @names = [];
            @subnames [];

            strlen = data.read_i32();
            if (strlen & 0x80000000) then
                namecount = (strlen &= 0x7FFFFFFF);
                subnamecount = data.read_i32();
                flags = data.read_i32();
                @is_absolute = (flags & 1) == 0 ? false : true;

                subnamecount += 1 if ((flags & 2) != 0);

                total = namecount + subnamecount;

                for i in 0...total do
                    str = data.read_bytes(data.read_i32());
                    if (i < namecount) then
                        @names.push(str)
                    else
                        @subnames.push(str)
                    end
                end
            else
                # old format, just a string
                raise "Old format, not supported anymore";
            end
        end

        def to_s()
            ret = "";
            ret = "/" if (@is_absolute);

            @names.each_with_index { |path,idx|
                ret += "/" if (idx > 0);
                ret += path.to_s();
            }

            @subnames.each { |path|
                ret += ":" + path.to_s();
            }

            return ret;
        end
    end

    class PoolArray
        POOL_UNKNOWN = 0;
        POOL_RAW     = 1; POOL_BYTE  = 1;
        POOL_INT     = 2;
        POOL_REAL    = 3; POOL_FLOAT = 3;
        POOL_STRING  = 4;
        POOL_VEC2    = 5;
        POOL_VEC3    = 6;
        POOL_VEC4    = 7; POOL_COLOR = 7;

        attr_accessor :data;
        attr_reader   :type;

        def initialize(data, type)
            @data = data;
            @type = type;
            if (type < 0 || type > 7) then
                raise Exception.new("PoolArray type is not in range: #{type}");
            end
        end
    end

end