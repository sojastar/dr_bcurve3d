require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'
require '/lib/track.rb'





### Constants :
DISTANCE          = 20
ANCHORS           = [ { center: [  100.0,    0.0,  100.0 ], right: [  100.0,    20.0,  100.0 ] },
                      { center: [  200.0,    0.0,    0.0 ], right: [  200.0,    20.0,    0.0 ] },
                      { center: [  100.0,    0.0, -100.0 ], right: [  100.0,    20.0, -100.0 ] },
                      { center: [ -100.0,  100.0,    0.0 ], right: [ -100.0,  100.0,    20.0 ] },
                      { center: [ -200.0,    0.0,    0.0 ], right: [ -200.0,    0.0,    20.0 ] },
                      { center: [ -100.0, -100.0,    0.0 ], right: [ -100.0, -100.0,    20.0 ] } ]
#ANCHORS           = [ { center: [  100.0,    0.0,    0.0 ], right: [    DISTANCE + 100.0,    0.0,                 0.0 ] },
#                      { center: [    0.0,    0.0,  100.0 ], right: [                 0.0,    0.0,    DISTANCE + 100.0 ] },
#                      { center: [ -100.0,    0.0,    0.0 ], right: [ -(DISTANCE + 100.0),    0.0,                 0.0 ] },
#                      { center: [    0.0,    0.0, -100.0 ], right: [                 0.0,    0.0, -(DISTANCE + 100.0) ] } ]

CENTER_COLOR    = [   0,   0, 255 ]
RIGHT_COLOR     = [   0, 255,   0 ]
TOP_COLOR       = [ 255,   0,   0 ]
TRACK_COLORS    = [ CENTER_COLOR + [ 255 ],
                    RIGHT_COLOR  + [ 255 ],
                    TOP_COLOR    + [ 255 ] ]
TRACK_COLORS025 = [ CENTER_COLOR + [ 1 ],
                    RIGHT_COLOR  + [ 1 ],
                    TOP_COLOR    + [ 64 ] ] 

RIGHT_ANGLE_COLOR   = [ 255, 255, 0, 255 ]
UP_ANGLE_COLOR      = [ 255, 127, 0, 255 ]

ANGLE_SCALE   = DISTANCE

RENDERING_STEPS   = 8
TRAVERSING_SPEED  = 0.01

CAMERA_DISTANCE   = 400





### Setup :
def setup(args)

  ## Use the track defined as a constant in the file :
  #center_anchors    = ANCHORS.map { |coords| Bezier::Anchor.new coords[:center] }
  #right_anchors     = ANCHORS.map { |coords| Bezier::Anchor.new coords[:right] }
  #args.state.track  = Bezier::Track.new center_anchors, right_anchors
  #args.state.track.close
  #args.state.track.balance

  ## Use the track imported from Blender :
  args.state.track  = Bezier::Track.load  '/blender/simple_center.json',
                                          '/blender/simple_right.json'
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

    ## Sections :
    track.curves.values.each.with_index do |curve,index|
      curve.sections.each do |section|
        draw_section(args, section, TRACK_COLORS[index], cos_a, sin_a)
      end
    end

    ## Angles :
    track.curves.values.map { |curve| curve.sections }
    .transpose
    .each do |sections|
      draw_angle(args, sections, RIGHT_ANGLE_COLOR, UP_ANGLE_COLOR, cos_a, sin_a)
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

def draw_angle(args,sections,color1,color2,cos_a,sin_a)
  t0  = 1.0 / RENDERING_STEPS
  RENDERING_STEPS.times.inject([]) do |angles,i|
    center  = sections[0].coords_at_linear(t0 * i)
    forward = sections[0].coords_at_linear(t0 * ( i + 1 ) )
    right   = sections[1].coords_at_linear(t0 * i)

    forward_delta = [ forward[0] - center[0],
                      forward[1] - center[1],
                      forward[2] - center[2] ]
    right_delta   = [ right[0] - center[0],
                      right[1] - center[1],
                      right[2] - center[2] ]
    up_delta      = Bezier::Trigo.cross_product forward_delta, right_delta
    up_delta      = Bezier::Trigo.normalize_and_scale up_delta, ANGLE_SCALE

    up  = [ center[0] + up_delta[0],
            center[1] + up_delta[1],
            center[2] + up_delta[2] ]

    angles << { center: center, right: right, up: up }
  end
  .each do |angle|
    center  = transform_3d(angle[:center],  cos_a, sin_a)
    right   = transform_3d(angle[:right],   cos_a, sin_a)
    up      = transform_3d(angle[:up],      cos_a, sin_a)

    draw_arrow(args, center, right, color1)
    draw_arrow(args, center, up,    color2)
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

def draw_arrow(args,p1,p2,color)
  args.outputs.lines << [ p1[0] + $gtk.args.grid.right / 2,
                          p1[1] + $gtk.args.grid.top / 2,
                          p2[0] + $gtk.args.grid.right / 2,
                          p2[1] + $gtk.args.grid.top / 2,
                          color ]
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
  [ -640 * coords[0] / ( coords[2] - CAMERA_DISTANCE ),
    -360 * coords[1] / ( coords[2] - CAMERA_DISTANCE ),
    coords[2] ]   # keeping z for other depth operations, like coloring
end

def transform_3d(coords,cos_a,sin_a)
  new_coords = rotate_x coords,     cos_a, sin_a
  new_coords = rotate_y new_coords, cos_a, sin_a
  #new_coords = rotate_y coords, cos_a, sin_a
  new_coords = rotate_z new_coords, cos_a, sin_a

  project new_coords
end
