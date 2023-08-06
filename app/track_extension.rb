module Bezier
  class Track
    attr_accessor :vertices

    def self.build(center,right,should_close,should_balance,width,interval)
      track = Bezier::Track.new center, right, should_close, should_balance

      track.build_vertices track, width, interval

      track
    end

    def self.load_and_build(center_file,right_file,should_close,width,interval)
      track = Bezier::Track.load center_file, right_file, should_close

      track.build_vertices track, width, interval

      track
    end

    def build_vertices(track,width,interval)
      t0 = 1.0 / interval
      @vertices = interval.times.map do |i|
                    center, right, _ = track.coords_at t0 * i
                    right_delta = [ right[0] - center[0],
                                    right[1] - center[1],
                                    right[2] - center[2] ]

                    offset  = Bezier::Trigo.normalize_and_scale(right_delta, width / 2)

                    [ [ center[0] + offset[0],
                        center[1] + offset[1],
                        center[2] + offset[2] ],
                      [ center[0] - offset[0],
                        center[1] - offset[1],
                        center[2] - offset[2] ] ]
                  end
                  .flatten(1)
    end
  end
end
