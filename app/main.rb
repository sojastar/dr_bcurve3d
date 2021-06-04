require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'





### Constants :
RENDERING_STEPS   = 25
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
  ## Anchors :
  curve.anchors.each { |anchor| draw_square args, anchor.center, [0, 0, 0, 255] }

  if curve.anchors.length > 1 then
    ## Segments :
    curve.anchors.each_cons(2) do |anchors|
      args.outputs.lines << [ anchors[0].x + $gtk.args.grid.right / 2,
                              anchors[0].y + $gtk.args.grid.top   / 2,
                              anchors[1].x + $gtk.args.grid.right / 2,
                              anchors[1].y + $gtk.args.grid.top   / 2 ] + [ 100, 100, 100, 255 ] 
    end

  #  ## Controls :
  #  curve.anchors.each.with_index do |anchor,index|
  #    # Left handle :
  #    if curve.is_closed || index > 0 then
  #      draw_square args, anchor.left_handle, [0, 0, 255, 255]
  #      args.outputs.lines << [ anchor.x, anchor.y, anchor.left_handle.x, anchor.left_handle.y, 200, 200, 255, 255 ]
  #    end

  #    # Right handle :
  #    if curve.is_closed || index < curve.anchors.length - 1 then
  #      draw_square args, anchor.right_handle, [255, 0, 0, 255]
  #      args.outputs.lines << [ anchor.x, anchor.y, anchor.right_handle.x, anchor.right_handle.y, 200, 200, 255, 255 ]
  #    end
  #  end

    ## Sections :
    curve.sections.each { |section| draw_section(args, section, [0, 0, 255, 255]) }
  end
end

def draw_section(args,section,color)
  t0          = 1.0 / RENDERING_STEPS
  key_points  = RENDERING_STEPS.times.inject([]) { |p,i| p << section.coords_at(t0 * i) }
  key_points.each_cons(2) do |points|
    args.outputs.lines << [ points[0][0] + $gtk.args.grid.right / 2,
                            points[0][1] + $gtk.args.grid.top   / 2,
                            points[1][0] + $gtk.args.grid.right / 2,
                            points[1][1] + $gtk.args.grid.top   / 2 ] + color
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

def draw_square(args,point,color)
  args.outputs.solids << [ point.x - 2 + $gtk.args.grid.right / 2,
                           point.y - 2 + $gtk.args.grid.top   / 2,
                           5, 5 ] + color
end


## Rotation :
def rotate_x(x,y,z,a)
  [ x,
    y * Math::cos(a) - z * Math::sin(a),
    y * Math::sin(a) + z * Math::cos(a) ]
end

def rotate_y(x,y,z,a)
  [ x * Math::cos(a) + z * Math::sin(a),
    y,
    z * Math::cos(a) - x * Math::sin(a) ]
end

def rotate_z(x,y,z,a)
  [ x * Math::cos(a) - y * Math::sin(a),
    x * Math::sin(a) + y * Math::cos(a),
    z ]
end


## Projection :
def project(x,y,z)
  [ x / ( z - CAMERA_DISTANCE ), y / ( z - CAMERA_DISTANCE ) ]
end
