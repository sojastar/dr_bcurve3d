import bpy
import json

from bpy_extras.io_utils import ExportHelper

class BezierToJSONOperator(bpy.types.Operator, ExportHelper):
    """Tooltip"""
    bl_idname = "curve.bezier_to_json_operator"
    bl_label = "Bezier to JSON Export"

    
    # ExportHelper mixin class uses this
    filename_ext = ".json"

    filter_glob: StringProperty(
        default="*.json",
        options={'HIDDEN'},
        maxlen=255,  # Max internal buffer length, longer would be clamped.
    )

    @classmethod
    def poll(cls, context):
        # Ensure that we have only one curve selected :
        return  bpy.context.mode == 'OBJECT' and len(bpy.context.selected_objects) == 1 and bpy.context.selected_objects[0].type == 'CURVE'

    def bezier_point_to_dictionary(self,bezier_point):
        bezier_dictionary = { 'center': (bezier_point.co.x, bezier_point.co.y, bezier_point.co.z),
                              'left_handle': (bezier_point.handle_left.x, bezier_point.handle_left.y, bezier_point.handle_left.z),
                              'right_handle': (bezier_point.handle_right.x, bezier_point.handle_right.y, bezier_point.handle_right.z) }
                             
        return bezier_dictionary

    def execute(self, context):
        anchors = bpy.context.selected_objects[0].data.splines[0].bezier_points
        dict_anchors = [ self.bezier_point_to_dictionary(anchor) for anchor in anchors ]
        json_anchors = json.dumps(dict_anchors, indent=2)
        
        return {'FINISHED'}


def menu_func(self, context):
    self.layout.operator(BezierToJSONOperator.bl_idname, text=BezierToJSONOperator.bl_label)


def register():
    bpy.utils.register_class(BezierToJSONOperator)
    bpy.types.VIEW3D_MT_object.append(menu_func)


def unregister():
    bpy.utils.unregister_class(BezierToJSONOperator)
    bpy.types.VIEW3D_MT_object.remove(menu_func)


if __name__ == "__main__":
    register()
