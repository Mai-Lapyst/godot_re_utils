require_relative "./data_types.rb"

module Godot
    module TextMarshall
        class Error < Exception
        end

        # source https://github.com/godotengine/godot/blob/3.2/core/variant_parser.cpp
        def self.variant_to_str(val)
            case val
            when NilClass
                return "null";
            when TrueClass
                return "true";
            when FalseClass
                return "false";
            when Integer
                return val.to_s();
            when Float
                return val.to_s();
            when String
                return "\"#{val}\"";
            when Vector2
                return "Vector2( #{val.x}, #{val.y} )";
            when Rect2
                return "Rect2(  #{val.position.x}, #{val.position.x}, #{val.size.x}, #{val.size.y} )";
            when Vector3
                return "Vector3( #{val.x}, #{val.y}, #{val.z} )";
            when AABB
                return "AABB( #{val.position.x}, #{val.position.y}, #{val.position.z}, #{val.size.x}, #{val.size.y}, #{val.size.z} )";
            when Transform2D
                ret = "Transform2D( ";
                for i in 0...3 do
                    for j in 0...2 do
                        ret += ", " if (i!=0 || j!=0);
                        ret += "#{val.elements[i][j]}";
                    end
                end
                return ret + " )";
            when Color
                return "Color( #{val.r}, #{val.g}, #{val.b}, #{val.a} )";
            when NodePath
                return "NodePath( #{val.to_s()} )";
            when Hash
                ret = "{\n";
                val.each_with_index { |k,v,idx| 
                    ret += ",\n" if (idx >= 0);
                    ret += "#{variant_to_str(k)}: #{variant_to_str(v)}";
                }
                return ret + "\n}";
            when Array
                ret = "[ ";
                val.each_with_index { |v,idx|
                    ret += ", " if (idx >= 0);
                    ret += "#{variant_to_str(v)}";
                }
                return ret + " ]";
            when PoolArray
                poolnames = [ "Byte", "Int", "Real", "String", "Vector2", "Vector3", "Color" ];
                ret = "Pool#{poolnames[val.type]}Array( ";
                val.each_with_index { |v,idx|
                    ret += ", " if (idx >= 0);
                    case val.type
                    when POOL_BYTE
                        ret += "#{v}";
                    when POOL_INT
                        ret += "#{v}";
                    when POOL_REAL
                        ret += "#{v}";
                    when POOL_STRING
                        ret += "\"#{v}\"";
                    when POOL_VEC2
                        ret += "#{v.x}, #{v.y}";
                    when POOL_VEC3
                        ret += "#{v.x}, #{v.y}, #{v.z}";
                    when POOL_COLOR
                        ret += "#{v.r}, #{v.g}, #{v.g}, #{v.a}";
                    end
                }
                return ret + " )";
            else
                raise TextMarshall::Error.new("Unknown value type: #{val.class}");
            end
        end

    end
end