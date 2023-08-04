module Bezier
  class Track
    DEFAULT_DISTANCE  = 10
    FORWARD_EPSILON   = 0.01

    attr_reader :center, :right, :ratios

    ### INITIALIZATION :
    def initialize(center_anchors,right_anchors,should_close,should_balance,steps=DEFAULT_STEPS)
      @center = Bezier::Curve.new center_anchors, steps
      @right  = Bezier::Curve.new right_anchors,  steps

      close   if should_close
      balance if should_balance

      calculate_ratios
    end


    ### LOADING FROM FILE :
    def self.load(center_file,right_file,should_close,steps=DEFAULT_STEPS)
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

      Bezier::Track.new center_anchors, right_anchors, should_close, false, steps
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
    def calculate_ratios
      cumulated_length_center = 0.0
      cumulated_length_right  = 0.0
      @ratios = @center.sections.zip(@right.sections).map do |center_section,right_section|
                  ratio = { ratio:                    center_section.length /
                                                      right_section.length,
                            cumulated_length_center:  cumulated_length_center,
                            cumulated_length_right:   cumulated_length_right }

                  cumulated_length_center += center_section.length
                  cumulated_length_right  += right_section.length

                  ratio
                end
    end

    def coords_at(t0,distance=DEFAULT_DISTANCE)
      center  = @center.coords_at(t0)

      t1  = t0 + FORWARD_EPSILON
      t1  = t1 - 1.0  if t1 > 1.0
      forward   = @center.coords_at(t1)

      right   = @right.coords_at(t0)
      up      = calculate_up center, forward, right, distance

      [ center, right, up ]
    end

    def calculate_up(center,forward,right,distance)
      forward_delta = [ forward[0] - center[0],
                        forward[1] - center[1],
                        forward[2] - center[2] ]
      right_delta   = [ right[0] - center[0],
                        right[1] - center[1],
                        right[2] - center[2] ]
      up_delta      = Trigo.cross_product right_delta, forward_delta

      up_delta      = Bezier::Trigo.normalize_and_scale up_delta, distance

      [ center[0] + up_delta[0],
        center[1] + up_delta[1],
        center[2] + up_delta[2] ]
    end
  end
end
