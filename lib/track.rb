module Bezier
  class Track
    FORWARD_EPSILON = 0.01

    attr_reader :center, :right

    ### INITIALIZATION :
    def initilize(center,right,steps=DEFAULT_STEPS)
      @center = Bezier::Curve.new center,   steps
      @right  = Bezier::Curve.new right,  steps
    end


    ### ADDING ANCHOR POINTS :
    def <<(center_anchor,right_anchor)
      @center << center_anchor
      @right  << right_anchor
    end


    ### CLOSING AND OPENING :
    def close
      @center.close
      @right.close
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

      center          = @center.coords_at(t)
      center_forward  = @center.coords_at(t + FORWARD_EPSILON)
      right           = @right.corrds_at(t)

      forward_delta   = [ center_forward.x - center.x,
                          center_forward.y - center.y,
                          center_forward.z - center.z ]
      right_delta     = [ right_forward.x - center.x,
                          right_forward.y - center.y,
                          right_forward.z - center.z ]
      up_delta        = Trigo.cross_product forward_delta, right_delta

      up  = [ center.x + up_delta.x,
              center.y + up_delta.y,
              center.z + up_delta.z ]

      [ center, right, up ]
    end
  end
end
