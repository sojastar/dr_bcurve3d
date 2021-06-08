require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'





### Constants :
RENDERING_STEPS   = 24
TRAVERSING_SPEED  = 0.01

CAMERA_DISTANCE   = 400





### Setup :
def setup(args)
  anchors = [ [    0,  100,  100 ],
              [  100,    0,    0 ],
              [  200,    0, -100 ],
              [  100,    0, -200 ],
              [    0,    0, -100 ],
              [    0, -100,    0 ],
              [    0,    0,  100 ],
              [ -100,    0,  200 ],
              [ -200,    0,  100 ],
              [ -100,    0,    0 ] ]
  args.state.curve  = Bezier::Curve.new( anchors.map { |a| Bezier::Anchor.new(*a) } ) 

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
  unless args.state.curve.nil? then
    draw_curve args, args.state.curve
  end

  #args.outputs.labels << [20, 700, ""]

end





### Drawing :
def draw_curve(args,curve)
  ## Precalculate sin and cos values :
  cos_a = Math::cos(args.state.angle)
  sin_a = Math::sin(args.state.angle)

  ## Anchors :
  curve.anchors.each.with_index do |anchor,index|
    coords = transform_3d anchor.center.coords, cos_a, sin_a
    draw_square args, coords, [0, 0, 0, 255]
    args.outputs.labels << [ coords[0] + $gtk.args.grid.right / 2,
                             coords[1] + $gtk.args.grid.top   / 2,
                             index.to_s ]
  end

  if curve.anchors.length > 1 then
    ## Segments :
    curve.anchors.map do |anchor|
      transform_3d anchor.center.coords, cos_a, sin_a
    end
    .each_cons(2) do |coords|
      args.outputs.lines << [ coords[0][0] + $gtk.args.grid.right / 2,
                              coords[0][1] + $gtk.args.grid.top   / 2,
                              coords[1][0] + $gtk.args.grid.right / 2,
                              coords[1][1] + $gtk.args.grid.top   / 2 ] + [ 100, 100, 100, 255 ] 
    end

    ## Controls :
    curve.anchors.each.with_index do |anchor,index|
      # Left handle :
      if curve.is_closed || index > 0 then
        draw_square args, anchor.left_handle, [0, 0, 255, 255]
        args.outputs.lines << [ anchor.x, anchor.anchor.left_handle.x, anchor.left_handle.y, 200, 200, 255, 255 ]
      end

      # Right handle :
      if curve.is_closed || index < curve.anchors.length - 1 then
        draw_square args, anchor.right_handle, [255, 0, 0, 255]
        args.outputs.lines << [ anchor.x, anchor.y, anchor.right_handle.x, anchor.right_handle.y, 200, 200, 255, 255 ]
      end
    end

    ## Sections :
    curve.sections.each { |section| draw_section(args, section, [0, 0, 255, 255], cos_a, sin_a) }
  end
end

def draw_section(args,section,color,cos_a,sin_a)
  t0          = 1.0 / RENDERING_STEPS
  RENDERING_STEPS.times.inject([]) do |points,i|
    points << section.coords_at(t0 * i)
  end
  .map do |point|
    transform_3d point, cos_a, sin_a
  end
  .each_cons(2) do |coords|
    args.outputs.lines << [ coords[0][0] + $gtk.args.grid.right / 2,
                            coords[0][1] + $gtk.args.grid.top   / 2,
                            coords[1][0] + $gtk.args.grid.right / 2,
                            coords[1][1] + $gtk.args.grid.top   / 2 ] + color
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
