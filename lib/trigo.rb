class Array
  def z
    at(2)
  end
end

module Bezier
  module Trigo
    def self.magnitude(point1,point2)
      Math::sqrt((point1.x - point2.x) ** 2 + (point1.y - point2.y) ** 2 + (point1.z - point2.z) ** 2)
    end

    def self.scale(v,a)
      [ a * v[0], a * v[1], a * v[2] ]
    end

    def self.normalize(v)
      m = Math::sqrt( v[0] ** 2 + v[1] ** 2 + v[2] ** 2 )
      [ v[0] / m, v[1] / m, v[2] / m ]
    end

    def self.normalize_and_scale(v,a)
      m = Math::sqrt( v[0] ** 2 + v[1] ** 2 + v[2] ** 2 )
      [ a * v[0] / m, a * v[1] / m, a * v[2] / m ]
    end

    def self.cross_product(v1,v2)
      [ v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0] ]
    end

    def self.angle_xy_of(p1,p2)
      angle_offset  = case
                      when p2.x >= p1.x && p2.y >= p1.y then  0.0
                      when p2.x <  p1.x                 then  Math::PI
                      when p2.x >= p1.x && p2.y <  p1.y then  2.0 * Math::PI
                      end

      if p1.x == p2.x && p1.y == p2.y then
        0.0
      else
        angle_offset + Math.atan( ( p2.y - p1.y ).to_f / ( p2.x - p1.x ).to_f )
      end
    end

    def self.angle_zx_of(p1,p2)
      angle_offset  = case
                      when p2.z >= p1.z && p2.x >= p1.x then  0.0
                      when p2.x <  p1.x                 then  Math::PI
                      when p2.x >= p1.x && p2.z <  p1.z then  2.0 * Math::PI
                      end

      if p1.x == p2.x && p1.z == p2.z then
        0.0
      else
        angle_offset + Math.atan( ( p2.x - p1.x ).to_f / ( p2.z - p1.z ).to_f )
      end
    end
  end
end
