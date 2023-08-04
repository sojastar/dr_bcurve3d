module Bezier
  class Track
    DEFAULT_DISTANCE  = 10
    FORWARD_EPSILON   = 0.01

    attr_reader :center, :right

    ### INITIALIZATION :
    def initialize(center_anchors,right_anchors,steps=DEFAULT_STEPS)
      @center = Bezier::Curve.new center_anchors, steps
      @right  = Bezier::Curve.new right_anchors,  steps
    end


    ### LOADING FROM FILE :
    def self.load(center_file,right_file,steps=DEFAULT_STEPS)
      center_data     = $gtk.args.gtk.parse_json_file center_file 
      center_anchors  = center_data.map do |anchor|
                          Bezier::Anchor.new( anchor['point'],
                                              anchor['left_handle'],
                                              anchor['right_handle'] )
                        end

      right_data      = $gtk.args.gtk.parse_json_file right_file 
      right_anchors   = right_data.map do |anchor|
                          Bezier::Anchor.new( anchor['point'],
                                              anchor['left_handle'],
                                              anchor['right_handle'] )
                        end

      Bezier::Track.new center_anchors, right_anchors, steps
    end


    ### ACCESSORS :
    def curves
      { center: @center,
        right:  @right }
    end


    ### ANCHOR POINTS :
    def anchors
      { center: @center.anchors,
        right:  @right.anchors }
    end 

    def <<(center_anchor,right_anchor)
      @center << center_anchor
      @right  << right_anchor
    end

    def calculate_up(center,center_forward,right,distance)
      forward_delta = Trigo.normalize( [ center_forward[0] - center[0],
                                         center_forward[1] - center[1],
                                         center_forward[2] - center[2] ] )
      right_delta   = [ right[0] - center[0],
                        right[1] - center[1],
                        right[2] - center[2] ]
      up_delta      = Trigo.cross_product forward_delta, right_delta

      unit_up_delta = Trigo.normalize up_delta

      [ center[0] + distance * unit_up_delta[0],
        center[1] + distance * unit_up_delta[1],
        center[2] + distance * unit_up_delta[2] ]
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

      [ @center.coords_at(t),
        @right.coords_at(t) ]
    end
  end
end
