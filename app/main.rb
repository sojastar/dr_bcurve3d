require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'
require '/lib/track.rb'





### Constants :
ANCHORS           = [ { center: [  100.0,    0.0,  100.0 ], right: [  100.0,    20.0,  100.0 ] },
                      { center: [  200.0,    0.0,    0.0 ], right: [  200.0,    20.0,    0.0 ] },
                      { center: [  100.0,    0.0, -100.0 ], right: [  100.0,    20.0, -100.0 ] },
                      { center: [ -100.0,  100.0,    0.0 ], right: [ -100.0,  100.0,    20.0 ] },
                      { center: [ -200.0,    0.0,    0.0 ], right: [ -200.0,    0.0,    20.0 ] },
                      { center: [ -100.0, -100.0,    0.0 ], right: [ -100.0, -100.0,    20.0 ] } ]

CENTER_COLOR    = [   0,   0, 255 ]
RIGHT_COLOR     = [   0, 255,   0 ]
TOP_COLOR       = [ 255,   0,   0 ]
TRACK_COLORS    = [ CENTER_COLOR + [ 255 ],
                    RIGHT_COLOR  + [ 255 ],
                    TOP_COLOR    + [ 255 ] ]
TRACK_COLORS025 = [ CENTER_COLOR + [ 1 ],
                    RIGHT_COLOR  + [ 1 ],
                    TOP_COLOR    + [ 64 ] ] 

RENDERING_STEPS   = 12#24
TRAVERSING_SPEED  = 0.01

CAMERA_DISTANCE   = 500





### Setup :
def setup(args)
  center_anchors    = ANCHORS.map { |anchor| Bezier::Anchor.new anchor[:center] }
  right_anchors     = ANCHORS.map { |anchor| Bezier::Anchor.new anchor[:right] }
  args.state.track  = Bezier::Track.new center_anchors, right_anchors
  args.state.track.close

  args.state.angle      = 0.0
  args.state.t          = 0.5

  args.state.setup_done = true
end





### Main Loop :
def tick(args)

  ## Setup :
  setup(args) unless args.state.setup_done


  ## Rotating the curve :
  args.state.angle += 0.01


  # Render :
  unless args.state.track.nil? then
    draw_track args, args.state.track
  end

  #args.outputs.labels << [20, 700, ""]

end





### Drawing :
def draw_track(args,track)
  ## Precalculate sin and cos values :
  cos_a = Math::cos(args.state.angle)
  sin_a = Math::sin(args.state.angle)

  ## Anchors :
  all_anchors = track.anchors.values

  all_anchors.each.with_index do |anchors,index|
    anchors.each do |anchor|
      coords = transform_3d anchor.coords, cos_a, sin_a
      draw_square args, coords, TRACK_COLORS[index]
    end
  end

  if all_anchors[0].length > 1 then
    ## Segments :
    all_anchors.each.with_index do |anchors,index|
      anchors.map { |anchor| transform_3d anchor.coords, cos_a, sin_a }
      .each_cons(2) { |coords|
        args.outputs.lines << [ coords[0][0] + $gtk.args.grid.right / 2,
                                coords[0][1] + $gtk.args.grid.top   / 2,
                                coords[1][0] + $gtk.args.grid.right / 2,
                                coords[1][1] + $gtk.args.grid.top   / 2 ] + TRACK_COLORS025[index]
      }
    end

    ## Handles :
    all_anchors.each.with_index do |anchors,index|
      anchors.each do |anchor|
  #  #  anchor_coords = transform_3d anchor.coords, cos_a, sin_a

  #  #  # Left handle :
  #  #  if curve.is_closed || index > 0 then
  #  #    left_handle_coords = transform_3d anchor.left_handle.coords, cos_a, sin_a
  #  #    draw_square args, left_handle_coords, [0, 0, 255, 255]
  #  #    args.outputs.lines << [ anchor_coords[0] + $gtk.args.grid.right / 2,
  #  #                            anchor_coords[1] + $gtk.args.grid.top   / 2,
  #  #                            left_handle_coords[0] + $gtk.args.grid.right / 2,
  #  #                            left_handle_coords[1] + $gtk.args.grid.top   / 2,
  #  #                            200, 200, 255, 255 ]
  #  #  end

  #  #  # Right handle :
  #  #  if curve.is_closed || index < curve.anchors.length - 1 then
  #  #    right_handle_coords = transform_3d anchor.right_handle.coords, cos_a, sin_a
  #  #    draw_square args, right_handle_coords, [255, 0, 0, 255]
  #  #    args.outputs.lines << [ anchor_coords[0] + $gtk.args.grid.right / 2,
  #  #                            anchor_coords[1] + $gtk.args.grid.top   / 2,
  #  #                            right_handle_coords[0] + $gtk.args.grid.right / 2,
  #  #                            right_handle_coords[1] + $gtk.args.grid.top   / 2,
  #  #                            255, 200, 200, 255 ]
      end
    end

    ## Sections :
    track.curves.values.each.with_index do |curve,index|
      curve.sections.each do |section|
        draw_section(args, section, TRACK_COLORS[index], cos_a, sin_a)
      end
    end
  end
end

def draw_section(args,section,section_color,cos_a,sin_a)
  t0  = 1.0 / RENDERING_STEPS
  (RENDERING_STEPS+1).times.inject([]) do |points,i|
    points << section.coords_at_linear(t0 * i)
  end
  .map do |point|
    transform_3d(point, cos_a, sin_a)
  end
  .each_cons(2) do |coords|
    args.outputs.lines << [ coords[0][0] + $gtk.args.grid.right / 2,
                            coords[0][1] + $gtk.args.grid.top   / 2,
                            coords[1][0] + $gtk.args.grid.right / 2,
                            coords[1][1] + $gtk.args.grid.top   / 2 ] + section_color
  end
end





### Tools :

## Drawing :
def draw_cross(args,coords,color)
  args.outputs.lines << [ coords[0] - 10 + $gtk.args.grid.right / 2,
                          coords[1] + 10 + $gtk.args.grid.top   / 2,
                          coords[0] + 11 + $gtk.args.grid.right / 2,
                          coords[1] - 11 + $gtk.args.grid.top   / 2 ] + color
  args.outputs.lines << [ coords[0] - 10 + $gtk.args.grid.right / 2,
                          coords[1] - 10 + $gtk.args.grid.top   / 2,
                          coords[0] + 11 + $gtk.args.grid.right / 2,
                          coords[1] + 11 + $gtk.args.grid.top   / 2 ] + color
end

def draw_small_cross(args,coords,color)
  args.outputs.lines << [ coords[0] - 1 + $gtk.args.grid.right / 2,
                          coords[1]     + $gtk.args.grid.top   / 2,
                          coords[0] + 2 + $gtk.args.grid.right / 2,
                          coords[1]     + $gtk.args.grid.top   / 2 ] + color
  args.outputs.lines << [ coords[0]     + $gtk.args.grid.right / 2,
                          coords[1] - 1 + $gtk.args.grid.top   / 2,
                          coords[0]     + $gtk.args.grid.right / 2,
                          coords[1] + 2 + $gtk.args.grid.top   / 2 ] + color
end

def draw_square(args,coords,color)
  args.outputs.solids << [ coords[0] - 2 + $gtk.args.grid.right / 2,
                           coords[1] - 2 + $gtk.args.grid.top   / 2,
                           5, 5 ] + color
end


## 3D Transformations :
def rotate_x(coords,cos_a,sin_a)
  [ coords[0],
    coords[1] * cos_a - coords[2] * sin_a,
    coords[1] * sin_a + coords[2] * cos_a ]
end

def rotate_y(coords,cos_a,sin_a)
  [ coords[0] * cos_a + coords[2] * sin_a,
    coords[1],
    coords[2] * cos_a - coords[0] * sin_a ]
end

def rotate_z(coords,cos_a,sin_a)
  [ coords[0] * cos_a - coords[1] * sin_a,
    coords[0] * sin_a + coords[1] * cos_a,
    coords[2] ]
end

def project(coords)
  [ 640 * coords[0] / ( coords[2] - CAMERA_DISTANCE ),
    360 * coords[1] / ( coords[2] - CAMERA_DISTANCE ),
    coords[2] ]   # keeping z for other depth operations, like coloring
end

def transform_3d(coords,cos_a,sin_a)
  new_coords = rotate_x coords,     cos_a, sin_a
  new_coords = rotate_y new_coords, cos_a, sin_a
  new_coords = rotate_z new_coords, cos_a, sin_a

  project new_coords
end
