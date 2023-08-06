require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'
require '/lib/track.rb'

require '/app/track_extension.rb'





### 1. Constants : #############################################################
DISTANCE        = 20
TRACK_WIDTH     = 30
TRACK_INTERVAL  = 48

## 1.1.1 Definition for a very simple track :
#ANCHORS           = [ { center: [  100.0,    0.0,    0.0 ], right: [    DISTANCE + 100.0,    0.0,                 0.0 ] },
#                      { center: [    0.0,    0.0,  100.0 ], right: [                 0.0,    0.0,    DISTANCE + 100.0 ] },
#                      { center: [ -100.0,    0.0,    0.0 ], right: [ -(DISTANCE + 100.0),    0.0,                 0.0 ] },
#                      { center: [    0.0,    0.0, -100.0 ], right: [                 0.0,    0.0, -(DISTANCE + 100.0) ] } ]

## 1.1.2 Definition for a more complex track :
ANCHORS           = [ { center: [  100.0,    0.0,  100.0 ], right: [  100.0,    20.0,  100.0 ] },
                      { center: [  200.0,    0.0,    0.0 ], right: [  200.0,    20.0,    0.0 ] },
                      { center: [  100.0,    0.0, -100.0 ], right: [  100.0,    20.0, -100.0 ] },
                      { center: [ -100.0,  100.0,    0.0 ], right: [ -100.0,  100.0,    20.0 ] },
                      { center: [ -200.0,    0.0,    0.0 ], right: [ -200.0,    0.0,    20.0 ] },
                      { center: [ -100.0, -100.0,    0.0 ], right: [ -100.0, -100.0,    20.0 ] } ]


## 1.2 Global View Constants :
TRACK_COLORS    = [ [ 0, 0, 255, 255 ],
                    [ 0, 255, 0, 255 ],
                    [ 255, 0, 0, 255 ] ]
TRACK_COLORS025 = [ [ 0, 0, 255, 63 ],
                    [ 0, 255, 0, 63 ],
                    [ 255, 0, 0, 63 ] ]

RIGHT_ANGLE_COLOR   = [ 255, 255, 0, 255 ]
UP_ANGLE_COLOR      = [ 255, 127, 0, 255 ]

ANGLE_SCALE   = DISTANCE

RENDERING_STEPS   = 32

CAMERA_DISTANCE   = 250


## 1.3 Camera View Constants :
CAMERA_HEIGHT     = 20
TRAVERSING_SPEED  = 0.002
FORWARD_OFFSET    = 0.001





### 2. Setup : #################################################################
def setup(args)

  ## 2.1 Create the Track : 

  ## 2.1.1 Use the track defined as a constant in the file :
  #center_anchors    = ANCHORS.map { |coords| Bezier::Anchor.new coords[:center] }
  #right_anchors     = ANCHORS.map { |coords| Bezier::Anchor.new coords[:right] }
  #args.state.track  = Bezier::Track.build center_anchors,
  #                                        right_anchors,
  #                                        true,            # closed track
  #                                        true,            # auto-balanced_track
  #                                        TRACK_WIDTH,
  #                                        TRACK_INTERVAL

  ## 2.1.2 Use the track imported from Blender :
  args.state.track  = Bezier::Track.load_and_build  '/blender/simple_center.json',
                                                    '/blender/simple_right.json',
                                                    true,
                                                    TRACK_WIDTH,
                                                    TRACK_INTERVAL


  ## 2.2 Setup for the Gobal View :
  args.state.angle  = 0.0


  ## 2.3 Setup for the Camera View :
  args.state.t0 = 0.5
  args.state.t1 = FORWARD_OFFSET


  ## 2.4 Miscellaneous :
  args.state.mode = :global_view

  args.state.setup_done = true
end





### 3. Main Loop : #############################################################
def tick(args)

  ## 3.1 Setup :
  setup(args) unless args.state.setup_done


  ## 3.2 User Input :
  if args.inputs.keyboard.key_down.tab
    args.state.mode = case args.state.mode
                      when :camera_view then :global_view
                      when :global_view then :camera_view
                      end
  end


  ### 3.3 Scene Update and Render :
  case args.state.mode
  when :global_view
    args.state.angle += 0.01  # rotating the curve

    draw_global_view args, args.state.track

  when :camera_view
    ## Moving along the track :
    args.state.t0 += TRAVERSING_SPEED
    args.state.t0  = 0.0 if args.state.t0 >= 1.0
    args.state.t1  = args.state.t0 + FORWARD_OFFSET
    args.state.t1  = 0.0 if args.state.t1 >= 1.0

    args.state.camera = update_camera args.state.track,
                                      args.state.t0,
                                      args.state.t1

    draw_camera_view args, args.state.track
  end
end





### 4. Drawing : ###############################################################
def draw_global_view(args,track)
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

    ## Curves :
    track.curves.values.each.with_index do |curve,index|
      draw_curve args, curve, TRACK_COLORS[index], cos_a, sin_a
    end

    ## Angles :
    draw_angle  args,
                track,
                RIGHT_ANGLE_COLOR, UP_ANGLE_COLOR,
                cos_a, sin_a
  end
end

def draw_camera_view(args,track)
  track.vertices.each_slice(4).with_index do |square,index|
    world_vertices  = [ local_to_world(args.state.camera, square[0]),
                        local_to_world(args.state.camera, square[1]),
                        local_to_world(args.state.camera, square[2]),
                        local_to_world(args.state.camera, square[3]) ]

    projected_vertices  = world_vertices.map do |world_vertex|
                            if world_vertex[2] < 0
                              project_camera_view world_vertex
                            else
                              nil
                            end
                          end

    if world_vertices[0][2] < 0 && world_vertices[1][2] < 0
      draw_square args, projected_vertices[0], [255, 0, 0, 255]
      draw_square args, projected_vertices[1], [255, 0, 0, 255]

      draw_line args, projected_vertices[0], projected_vertices[1], [ 0, 0, 255, 255 ]
    end

    if world_vertices[2][2] < 0 && world_vertices[3][2] < 0
      draw_square args, projected_vertices[2], [255, 0, 0, 255]
      draw_square args, projected_vertices[3], [255, 0, 0, 255]

      draw_line args, projected_vertices[2], projected_vertices[3], [ 0, 0, 255, 255 ]
    end

    if world_vertices[0][2] < 0 && world_vertices[2][2] < 0
      draw_line args, projected_vertices[0], projected_vertices[2], [ 0, 0, 255, 255 ]
    end

    if world_vertices[1][2] < 0 && world_vertices[3][2] < 0
      draw_line args, projected_vertices[1], projected_vertices[3], [ 0, 0, 255, 255 ]
    end
  end
end

def draw_curve(args,curve,color,cos_a,sin_a)
  t0  = 1.0 / RENDERING_STEPS
  (RENDERING_STEPS+1).times.inject([]) do |points,i|
    points << curve.coords_at(t0 * i)
  end
  .map do |point|
    transform_3d(point, cos_a, sin_a)
  end
  .each_cons(2) do |coords|
    args.outputs.lines << [ coords[0][0] + $gtk.args.grid.right / 2,
                            coords[0][1] + $gtk.args.grid.top   / 2,
                            coords[1][0] + $gtk.args.grid.right / 2,
                            coords[1][1] + $gtk.args.grid.top   / 2 ] + color
  end
end

def draw_angle(args,track,color1,color2,cos_a,sin_a)
  t0  = 1.0 / RENDERING_STEPS
  RENDERING_STEPS.times.inject([]) do |angles,i|
    center, right, up   = track.coords_at t0 * i, ANGLE_SCALE

    angles << { center: center, right: right, up: up }
  end
  .each do |angle|
    center  = transform_3d(angle[:center],  cos_a, sin_a)
    right   = transform_3d(angle[:right],   cos_a, sin_a)
    up      = transform_3d(angle[:up],      cos_a, sin_a)

    draw_line(args, center, right, color1)
    draw_line(args, center, up,    color2)
  end
end

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

def draw_line(args,p1,p2,color)
  args.outputs.lines << [ p1[0] + $gtk.args.grid.right / 2,
                          p1[1] + $gtk.args.grid.top / 2,
                          p2[0] + $gtk.args.grid.right / 2,
                          p2[1] + $gtk.args.grid.top / 2,
                          color ]
end





### 5. MATHS : #################################################################
def mat_mul(m1,m2)
  mul_coefficients = []
  4.times do |i|
    mul_row = []
    4.times do |j|
      mul_result = 0.0
      4.times do |s|
        mul_result += m1[i][s] * m2[s][j]
      end
      mul_row << mul_result
    end
    mul_coefficients << mul_row
  end

  mul_coefficients
end





### 6. 3D TRANSFORMATIONS : ####################################################

### 6.1 Global View :
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

def project_global_view(coords)
  [ -640 * coords[0] / ( coords[2] - CAMERA_DISTANCE ),
    -360 * coords[1] / ( coords[2] - CAMERA_DISTANCE ),
    coords[2] ]   # keeping z for other depth operations, like coloring
end

def transform_3d(coords,cos_a,sin_a)
  new_coords = rotate_x coords,     cos_a, sin_a
  new_coords = rotate_y new_coords, cos_a, sin_a
  new_coords = rotate_z new_coords, cos_a, sin_a

  project_global_view new_coords
end


### 6.2 Camera on Track View :
def update_camera(track,t0,t1)
  position, right, up  = track.coords_at t0
  forward,      _,  _  = track.coords_at t1

  right_delta   = [ right[0] - position[0],
                    right[1] - position[1],
                    right[2] - position[2] ]
  forward_delta = [ forward[0] - position[0],
                    forward[1] - position[1],
                    forward[2] - position[2] ]
  up_delta      = [ up[0] - position[0],
                    up[1] - position[1],
                    up[2] - position[2] ]

  right_delta   = Bezier::Trigo.normalize right_delta
  forward_delta = Bezier::Trigo.normalize forward_delta
  up_delta      = Bezier::Trigo.normalize up_delta

  rotation    = [ [  -right_delta[0],  -right_delta[1],  -right_delta[2], 0.0 ],
                  [      up_delta[0],      up_delta[1],      up_delta[2], 0.0 ],
                  [-forward_delta[0],-forward_delta[1],-forward_delta[2], 0.0 ],
                  [              0.0,              0.0,              0.0, 1.0 ] ]
  translation = [ [ 1.0, 0.0, 0.0, -position[0] ],
                  [ 0.0, 1.0, 0.0, -position[1] ],
                  [ 0.0, 0.0, 1.0, -position[2] - CAMERA_HEIGHT ],
                  [ 0.0, 0.0, 0.0, 1.0 ] ]

  mat_mul rotation, translation
end

def local_to_world(camera,coords)
  [ camera[0][0] * coords[0] + camera[0][1] * coords[1] + camera[0][2] * coords[2] + camera[0][3],
    camera[1][0] * coords[0] + camera[1][1] * coords[1] + camera[1][2] * coords[2] + camera[1][3],
    camera[2][0] * coords[0] + camera[2][1] * coords[1] + camera[2][2] * coords[2] + camera[2][3] ]
end

def project_camera_view(coords)
  [ -($gtk.args.grid.right / 2) * coords[0] / ( coords[2] ),
    -($gtk.args.grid.top / 2) * coords[1] / ( coords[2] ),
    coords[2] ]   # keeping z for other depth operations, like coloring
end
