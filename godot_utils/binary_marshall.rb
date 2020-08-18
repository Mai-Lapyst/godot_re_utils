# based on https://docs.godotengine.org/en/stable/tutorials/misc/binary_serialization_api.html

require_relative "../utils/iostream.rb"
require_relative "../utils/arraystream.rb"
require_relative "./data_types.rb"

module Godot
    module BinaryMarshall
        class Error < Exception
        end

        ENCODE_FLAG_64 = (1 << 16);

        def self.decode_pool_arrays(data, pool_type)
            if (data.class != ArrayStream && data.class != IOStream) then
                raise BinaryMarshall::Error.new("Argument must be of type ArrayStream or IOStream!");
            end

            count = data.read_i32();
            pooldata = [];

            for i in 0...count do
                case pool_type
                when POOL_BYTE
                    pooldata.push(data.read_i8());
                when POOL_INT
                    pooldata.push(data.read_i32());
                when POOL_REAL
                    pooldata.push(data.read_f32());
                when POOL_STRING
                    pooldata.push(data.read_bytes(data.read_i32()));
                when POOL_VEC2
                    pooldata.push(Vector2.new(data.read_f32(), data.read_f32()));
                when POOL_VEC3
                    pooldata.push(Vector3.new(data.read_f32(), data.read_f32(), data.read_f32()));
                when POOL_VEC4
                    pooldata.push(Color.new(data.read_f32(), data.read_f32(), data.read_f32(), data.read_f32()));
                else
                    raise Exception.new("Unknown PoolArray type: #{type}");
                end
            end

            return PoolArray.new(pooldata, pool_type);
        end

        # source https://github.com/godotengine/godot/blob/3.2/core/io/marshalls.cpp
        def self.decode_variant(data)

            if (data.class == Array || data.class == String) then
                data = ArrayStream.new(data);
            elsif (data.class != ArrayStream && data.class != IOStream) then
                raise BinaryMarshall::Error.new("Argument must be of type Array, String, ArrayStream or IOStream!");
            end
            
            type = data.read_i32();

            case (type & 0xFF)
            when 0   # null
                return nil;
            when 1   # bool
                return data.read_i32() == 0 ? false : true;
            when 2   # integer
                if ((type & ENCODE_FLAG_64) != 0) then
                    return data.read_i64();
                end
                return data.read_i32();
            when 3   # float
                if ((type & ENCODE_FLAG_64) != 0) then
                    return data.read_f64();
                end
                return data.read_f32();
            when 4   # string
                str_len = data.read_i32();
                str = data.read_bytes(str_len);
                return String.new(str);
            when 5   # vector2
                return Vector2.new(data.read_f32(), data.read_f32());
            when 6   # rect2
                return Rect2.new(
                    Vector2.new(data.read_f32(), data.read_f32()),
                    Vector2.new(data.read_f32(), data.read_f32())
                );
            when 7   # vector3
                return Vector3.new(data.read_f32(), data.read_f32(), data.read_f32());
            when 8   # transform2d
                if (data.size <= (4*6)) then
                    raise BinaryMarshall::Error.new("Invalid data!");
                end
                t2d = Transform2D.new();
                for i in 0...3 do
                    for j in 0...2 do
                        t2d.elements[i][j] = data.read_f32();
                    end
                end
                return t2d;
            when 9   # plane
                raise BinaryMarshall::Error.new("NIY: plane")
            when 10  # quat
                raise BinaryMarshall::Error.new("NIY: quat")
            when 11  # aabb
                return AABB.new(
                    Vector3.new(data.read_f32(), data.read_f32(), data.read_f32()),
                    Vector3.new(data.read_f32(), data.read_f32(), data.read_f32())
                );
            when 12  # basis
                raise BinaryMarshall::Error.new("NIY: basis")
            when 13  # transform
                raise BinaryMarshall::Error.new("NIY: transform")
            when 14  # color
                return Color.new(data.read_f32(), data.read_f32(), data.read_f32(), data.read_f32());
            when 15  # node path
                return NodePath.new(data);
            when 16  # rid
                raise BinaryMarshall::Error.new("NIY: rid")
            when 17  # object
                raise BinaryMarshall::Error.new("NIY: object")
            when 18  # dictionary
                dict_size = data.read_i32();
                # &0x80000000 was shared flag
                dict_size &= 0x7FFFFFFF;

                return {} if (dict_size == 0);

                dict = {};
                for i in 0...dict_size do
                    key = decode_variant(data);
                    val = decode_variant(data);
                    dict[key] = val;
                end
                return dict;
            when 19  # array
                array_size = data.read_i32();
                # &0x80000000 was shared flag
                array_size &= 0x7FFFFFFF;

                return [] if (array_size == 0);

                array = [];
                for i in 0...array_size do
                    val = decode_variant(data);
                    array.push(val);
                end
                return array;
            when 20  # raw array / pool byte array
                return self.decode_pool_arrays(data, POOL_BYTE);
            when 21  # (pool) int array
                return self.decode_pool_arrays(data, POOL_INT);
            when 22  # (pool) real array
                return self.decode_pool_arrays(data, POOL_REAL);
            when 23  # (pool) string array
                return self.decode_pool_arrays(data, POOL_STRING);
            when 24  # (pool) vector2 array
                return self.decode_pool_arrays(data, POOL_VEC2);
            when 25  # (pool) vector3 array
                return self.decode_pool_arrays(data, POOL_VEC3);
            when 26  # (pool) color array
                return self.decode_pool_arrays(data, POOL_VEC4);
            when 27  # max
                raise BinaryMarshall::Error.new("NIY: max");
            else
                raise BinaryMarshall::Error.new("Unknown variant type: #{type & 0xFF}");
            end
        end

    end
end