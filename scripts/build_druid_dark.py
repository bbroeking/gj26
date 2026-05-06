"""Build druid_dark.glb (Night Druid) from concept art.

Run from Blender's Text Editor (Run Script ▶) or command line:
    blender --background --python scripts/build_druid_dark.py
"""
import bpy, math, os
import mathutils

# === Setup ===
bpy.ops.wm.read_homefile(use_empty=True, use_factory_startup=True)

sd = bpy.data.lights.new('Sun', 'SUN'); sd.energy = 2.5
s = bpy.data.objects.new('Sun', sd); s.rotation_euler = (0.7, 0, 0.5)
bpy.context.scene.collection.objects.link(s)

cd = bpy.data.cameras.new('Cam'); cam = bpy.data.objects.new('Cam', cd)
cam.location = (2.8, -2.8, 1.4)
cam.rotation_euler = (mathutils.Vector((0, 0, 1.0)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

bpy.context.scene.world = bpy.data.worlds.new('World')
bpy.context.scene.world.use_nodes = True
bpy.context.scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.92, 0.88, 0.78, 1.0)
bpy.context.scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 1.5
bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 800

def make_cube(name, loc, dims, color):
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=loc)
    obj = bpy.context.active_object; obj.name = name
    obj.scale = (dims[0]*0.5, dims[1]*0.5, dims[2]*0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mat = bpy.data.materials.new(name + '_mat'); mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.85
    obj.data.materials.append(mat); return obj

# === Palette ===
INDIGO     = (0.18, 0.16, 0.42)
DEEP_INDIGO= (0.10, 0.10, 0.30)
MIDNIGHT   = (0.14, 0.18, 0.36)
SILVER     = (0.86, 0.88, 0.92)
PALE_BLUE  = (0.55, 0.70, 0.95)
CHARCOAL   = (0.18, 0.18, 0.22)
SKIN       = (0.85, 0.70, 0.55)
DARK_HAIR  = (0.16, 0.13, 0.10)
BLACKTHORN = (0.20, 0.16, 0.12)

# === Meshes ===
make_cube('Body_torso', (0, 0, 0.95), (0.42, 0.32, 0.55), MIDNIGHT)
make_cube('Body_robe', (0, 0.04, 0.85), (0.55, 0.44, 0.85), INDIGO)
make_cube('Body_robe_lower', (0, 0.06, 0.30), (0.50, 0.42, 0.40), DEEP_INDIGO)
make_cube('Body_crescent', (0, -0.20, 0.40), (0.10, 0.02, 0.10), SILVER)

make_cube('Head_skull', (0, 0, 1.45), (0.32, 0.30, 0.30), SKIN)
make_cube('Head_hood_back', (0, 0.10, 1.55), (0.42, 0.34, 0.40), INDIGO)
make_cube('Head_hood_top', (0, 0.05, 1.72), (0.36, 0.30, 0.10), INDIGO)
make_cube('Head_hair', (0, -0.08, 1.40), (0.28, 0.10, 0.14), DARK_HAIR)
make_cube('Head_eye_L', (-0.07, -0.16, 1.45), (0.04, 0.04, 0.04), (0.05, 0.05, 0.05))
make_cube('Head_eye_R', ( 0.07, -0.16, 1.45), (0.04, 0.04, 0.04), (0.05, 0.05, 0.05))

make_cube('Arm_L', (-0.30, -0.05, 1.05), (0.16, 0.18, 0.55), INDIGO)
make_cube('Arm_R', ( 0.30, -0.05, 1.05), (0.16, 0.18, 0.55), INDIGO)
make_cube('Arm_L_wrap', (-0.30, -0.10, 0.78), (0.18, 0.16, 0.14), CHARCOAL)
make_cube('Arm_R_wrap', ( 0.30, -0.10, 0.78), (0.18, 0.16, 0.14), CHARCOAL)

make_cube('Leg_L', (-0.11, 0, 0.30), (0.20, 0.22, 0.55), CHARCOAL)
make_cube('Leg_R', ( 0.11, 0, 0.30), (0.20, 0.22, 0.55), CHARCOAL)
make_cube('Leg_L_boot', (-0.11, -0.02, 0.04), (0.22, 0.28, 0.13), (0.15, 0.13, 0.12))
make_cube('Leg_R_boot', ( 0.11, -0.02, 0.04), (0.22, 0.28, 0.13), (0.15, 0.13, 0.12))

make_cube('Arm_R_staff', (0.45, -0.18, 1.10), (0.06, 0.06, 1.30), BLACKTHORN)
glow = make_cube('Arm_R_moonstone', (0.45, -0.18, 1.85), (0.18, 0.18, 0.18), PALE_BLUE)
glow.data.materials[0].node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (0.55, 0.70, 0.95, 1.0)
glow.data.materials[0].node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 1.5

# === Rig ===
rig_pivots = {'Body':(0,0,0.74),'Head':(0,0,1.30),'Arm_L':(-0.28,0,1.30),'Arm_R':(0.28,0,1.30),'Leg_L':(-0.11,0,0.70),'Leg_R':(0.11,0,0.70)}
empties = {}
for name, loc in rig_pivots.items():
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = 'PLAIN_AXES'
    e.empty_display_size = 0.15
    e.location = loc
    bpy.context.scene.collection.objects.link(e)
    empties[name] = e

def parent_for(name):
    if name.startswith('Body_'): return 'Body'
    if name.startswith('Head_'): return 'Head'
    if name == 'Arm_L' or name.startswith('Arm_L_'): return 'Arm_L'
    if name == 'Arm_R' or name.startswith('Arm_R_'): return 'Arm_R'
    if name == 'Leg_L' or name.startswith('Leg_L_'): return 'Leg_L'
    if name == 'Leg_R' or name.startswith('Leg_R_'): return 'Leg_R'
    return None

mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
for obj in mesh_objs:
    pn = parent_for(obj.name)
    if pn and obj.name != pn:
        wm = obj.matrix_world.copy()
        obj.parent = empties[pn]
        obj.matrix_parent_inverse = empties[pn].matrix_world.inverted()
        obj.matrix_world = wm

root = bpy.data.objects.new('NightDruid_Root', None)
root.empty_display_type = 'PLAIN_AXES'
root.empty_display_size = 0.3
bpy.context.scene.collection.objects.link(root)
for empty in empties.values():
    wm = empty.matrix_world.copy()
    empty.parent = root
    empty.matrix_parent_inverse = root.matrix_world.inverted()
    empty.matrix_world = wm

# === remove_doubles + bevel ===
for obj in mesh_objs:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    dim_min = min(obj.dimensions)
    bw = min(0.025, dim_min * 0.08)
    bv = obj.modifiers.new('Bevel', 'BEVEL')
    bv.width = bw
    bv.segments = 2
    bv.limit_method = 'ANGLE'
    bv.angle_limit = math.radians(30)

# === Export ===
bpy.ops.object.select_all(action='DESELECT')
def select_recursive(o):
    o.select_set(True)
    for c in o.children:
        select_recursive(c)
select_recursive(root)
bpy.context.view_layer.objects.active = root

out_path = '/Users/bbroeking/projects/gj26/models/druid_dark.glb'
bpy.ops.export_scene.gltf(
    filepath=out_path,
    use_selection=True,
    export_yup=True,
    export_apply=True,
    export_animations=False,
    export_skins=False,
    export_format='GLB',
)

print(f"Exported {out_path} ({os.path.getsize(out_path)} bytes)")
