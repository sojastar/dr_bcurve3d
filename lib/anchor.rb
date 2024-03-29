module Bezier
  class Point
    attr_accessor :x, :y, :z

    def initialize(x,y,z)
      @x, @y, @z = x, y, z
    end

    def coords() [@x, @y, @z] end

    def to_s
      "(#{@x.round(2)};#{@y.round(2)};#{@z.round(2)})"
    end
    alias inspect to_s
  end

  class Anchor
    attr_reader :center,
                :left_handle, :right_handle

    def initialize(position,left_handle=nil,right_handle=nil)
      @center       = Point.new(*position)
      @left_handle  = left_handle.nil? ? Point.new(x - 30, y - 30, z - 30) : Point.new(*left_handle)
      @right_handle = right_handle.nil? ? Point.new(x + 30, y + 30, z + 30) : Point.new(*right_handle)
    end

    def x() @center.x end
    def y() @center.y end
    def z() @center.z end
    def coords() [ @center.x, @center.y, @center.z ] end

    def x=(new_x) @center.x = new_x end
    def y=(new_y) @center.y = new_y end
    def z=(new_z) @center.z = new_z end

    def serialize
      {x: @center.x, y: @center.y, z: @center.z }
    end

    def inspect
      serialize.to_s
    end
    alias to_s inspect
  end
end
