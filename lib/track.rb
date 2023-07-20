module Bezier
  class Track
    DEFAULT_DISTANCE  = 20
    FORWARD_EPSILON   = 0.01

    attr_reader :center, :right, :top

    ### INITIALIZATION :
    def initialize(center,right,distance=DEFAULT_DISTANCE,steps=DEFAULT_STEPS)
      @center = Bezier::Curve.new center, steps

      scaled_right  = center.zip(right).map do |c,r|
                        Bezier::Anchor.new calculate_right(c.coords, r.coords)
                      end
      @right        = Bezier::Curve.new scaled_right,  steps

      top   = @center.anchors.zip(@right.anchors).map do |c,r|
                delta_front = [ c.right_handle.coords.x - c.coords.x,
                                c.right_handle.coords.y - c.coords.y,
                                c.right_handle.coords.z - c.coords.z ]

                Bezier::Anchor.new calculate_top(c.coords, delta_front, r.coords)
              end
      @top  = Bezier::Curve.new top, steps
    end


    ### ACCESSORS :
    def curves
      { center: @center,
        right:  @right,
        top:    @top }
    end


    ### ANCHOR POINTS :
    def anchors
      { center: @center.anchors,
        right:  @right.anchors,
        top:    @top.anchors }
    end 

    def <<(center_anchor,right_anchor)
      @center << center_anchor
      @right  << right_anchor
    end

    def calculate_right(center,right)
      right_delta     = [ right[0] - center[0],
                          right[1] - center[1],
                          right[2] - center[2] ]
      unit_right_delta  = Trigo.normalize right_delta

      [ center[0] + DEFAULT_DISTANCE * unit_right_delta[0],
        center[1] + DEFAULT_DISTANCE * unit_right_delta[1],
        center[2] + DEFAULT_DISTANCE * unit_right_delta[2] ]
    end

    def calculate_top(center,center_forward,right)
      forward_delta = Trigo.normalize( [ center_forward[0] - center[0],
                                         center_forward[1] - center[1],
                                         center_forward[2] - center[2] ] )
      right_delta   = [ right[0] - center[0],
                        right[1] - center[1],
                        right[2] - center[2] ]
      up_delta      = Trigo.cross_product forward_delta, right_delta

      unit_up_delta = Trigo.normalize up_delta

      [ center[0] + DEFAULT_DISTANCE * unit_up_delta[0],
        center[1] + DEFAULT_DISTANCE * unit_up_delta[1],
        center[2] + DEFAULT_DISTANCE * unit_up_delta[2] ]
    end


    ### CLOSING AND OPENING :
    def close
      @center.close
      @right.close
      @top.close
    end

    def open
      @center.open
      @right.open
    end

    def is_closed?
      @center.is_closed? && @right.is_closed?
    end

    def is_open?
      !@center.is_closed && !@right.is_closed?
    end
  

    ### AUTOMATIC BALANCING AT ANCHOR POINTS :
    def balance
      @center.balance
      @right.balance
    end


    ### TRAVERSING :
    def coords_at(t)
      if t + FORWARD_EPSILON < 0 || t + FORWARD_EPSILON > 1.0
        raise "next t out of [0.0, 1.0] range (t=#{t+FORWARD_EPSILON})"
      end

      center  = @center.coords_at(t)
      right   = @right.coords_at(t)
      top     = @top.coords_at(t)

      [ center, right, up ]
    end
  end
end
