# dr_bcurve3d
3D Bézier tracks.

![DemoGlobalView](/dr_bcurve3D_global_view_24fps.mov)
![DemoCameraView](/dr_bcurve3D_camera_view_24fps.mov)

## What is it?
**dr_bcurve3d** is a library for the [DragonRuby](https://dragonruby.itch.io/dragonruby-gtk) game engine. The library's primary function is to create and traverse 3D tracks/curves. Tracks are built by aggregating 2 3D Bézier curves.
The first curve is called the _center_ curve. Whatever you want to do with the track, spawn objects, attach a camera or extrude, it should be done along that track.
The second track is called the _right_ track. It gives the _center_ track its orientation in space.

## You can create tracks programmatically:

Just feed it a list of coordinates for the _center_ and _right_ curves (they must have the same number of points/anchors!).

```ruby
ANCHORS           = [ { center: [  100.0,    0.0,  100.0 ], right: [  100.0,    20.0,  100.0 ] },
                      { center: [  200.0,    0.0,    0.0 ], right: [  200.0,    20.0,    0.0 ] },
                      { center: [  100.0,    0.0, -100.0 ], right: [  100.0,    20.0, -100.0 ] },
                      { center: [ -100.0,  100.0,    0.0 ], right: [ -100.0,  100.0,    20.0 ] },
                      { center: [ -200.0,    0.0,    0.0 ], right: [ -200.0,    0.0,    20.0 ] },
                      { center: [ -100.0, -100.0,    0.0 ], right: [ -100.0, -100.0,    20.0 ] } ]
TRACK_PRECISION   = 64

center_anchors    = ANCHORS.map { |coords| Bezier::Anchor.new coords[:center] }
right_anchors     = ANCHORS.map { |coords| Bezier::Anchor.new coords[:right] }
args.state.track  = Bezier::Track.new center_anchors,
                                        right_anchors,
                                        true,            # closed track ?
                                        true,            # auto-balanced_track ?
                                        TRACK_PRECISION
```

Some useful methods:
- open or close the track with `Bezier::Track#open/close`
- add anchors with `Bezier::Track#<<`
- auto-balance the track with `Bezier::Track#balance`
- get all anchors with `Bezier::Track#anchors`

## You can export tracks from blender:

The `blender` directory contains a blender operator that exports Bézier curves as a json file. Draw 2 curves in Blander, export them with the operator then load them with `Bezier::Track.load`.

```ruby
args.state.track  = Bezier::Track.load_and_build  '/blender/simple_center.json',
                                                  '/blender/simple_right.json',
                                                  true,
                                                  TRACK_PRECISION
```

## Traversing the track:

You can get the coordinates for the _center_, _right_, and _up_ curves at any given point along the track by using  `Bezier::Track#coords_at`. The _up_ curve is a "virtual" curve that is pointing up from the direction defined by the _right_ curve and is calculated on the fly. The `Bezier::Track#coords_at` method takes 2 arguments. The first argument _t_ defines the position of the desired 3D coordinates along the track on a scale from 0.0 to 1.0. The second optional arguments _distance_ defines the distance at which the _up_ curve lies from the _center_ track.

```ruby
center, right, up = args.state.track.coords_at(0.5, 10) # get coords at the middle of the track
```
In this example, the distance between `center` and `up` is 10.
