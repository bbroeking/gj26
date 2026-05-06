"""Build wanderer_bard.glb (Bard "Bridget") from concept art."""
import bpy, math, os
import mathutils

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

# Bard palette
DUSTY_PINK = (0.78, 0.50, 0.55)
SOFT_GOLD  = (0.86, 0.72, 0.40)
CREAM      = (0.93, 0.88, 0.74)
AUBURN     = (0.55, 0.28, 0.18)
SKY_BLUE   = (0.55, 0.74, 0.88)
GOLDEN_BR  = (0.55, 0.40, 0.22)
TAN        = (0.62, 0.46, 0.30)
SKIN       = (0.95, 0.82, 0.70)
WOOD       = (0.46, 0.30, 0.18)

# Body
make_cube('Body_torso', (0, 0, 0.95), (0.46, 0.34, 0.55), CREAM)  # cream blouse
make_cube('Body_jerkin', (0, -0.13, 0.92), (0.42, 0.10, 0.42), DUSTY_PINK)  # laced jerkin front
make_cube('Body_collar_trim', (0, -0.13, 1.18), (0.32, 0.06, 0.04), SOFT_GOLD)  # gold trim
# Trousers waist
make_cube('Body_trousers', (0, 0, 0.50), (0.42, 0.32, 0.30), GOLDEN_BR)

# Head
make_cube('Head_skull', (0, 0, 1.45), (0.32, 0.30, 0.30), SKIN)
# Auburn hair (braid + main mass)
make_cube('Head_hair', (0, 0.07, 1.50), (0.36, 0.20, 0.32), AUBURN)
# Bangs (covering forehead — fixes earlier hairline issue)
make_cube('Head_bangs', (0, -0.13, 1.55), (0.30, 0.06, 0.10), AUBURN)
# Side-braid hint
make_cube('Head_braid', (-0.18, -0.05, 1.30), (0.06, 0.06, 0.18), AUBURN)
# Hat (dusty-pink wool)
make_cube('Head_hat', (0, 0.04, 1.70), (0.40, 0.36, 0.16), DUSTY_PINK)
# Sky-blue feather
make_cube('Head_feather', (0.10, 0.18, 1.82), (0.04, 0.10, 0.18), SKY_BLUE)

# Eyes (warm dark)
make_cube('Head_eye_L', (-0.07, -0.16, 1.45), (0.04, 0.04, 0.04), (0.18, 0.10, 0.06))
make_cube('Head_eye_R', ( 0.07, -0.16, 1.45), (0.04, 0.04, 0.04), (0.18, 0.10, 0.06))
# Freckles (cream highlight on cheek — barely visible)
make_cube('Head_blush_L', (-0.10, -0.16, 1.40), (0.06, 0.02, 0.04), (0.92, 0.70, 0.65))
make_cube('Head_blush_R', ( 0.10, -0.16, 1.40), (0.06, 0.02, 0.04), (0.92, 0.70, 0.65))

# Arms
make_cube('Arm_L', (-0.30, -0.05, 1.10), (0.16, 0.18, 0.48), CREAM)
make_cube('Arm_R', ( 0.30, -0.05, 1.10), (0.16, 0.18, 0.48), CREAM)
# Gold-cord bracelet on right wrist
make_cube('Arm_R_bracelet', ( 0.30, -0.10, 0.86), (0.18, 0.16, 0.04), SOFT_GOLD)

# Legs (golden-brown trousers)
make_cube('Leg_L', (-0.11, 0, 0.30), (0.20, 0.22, 0.55), GOLDEN_BR)
make_cube('Leg_R', ( 0.11, 0, 0.30), (0.20, 0.22, 0.55), GOLDEN_BR)
# Tan boots
make_cube('Leg_L_boot', (-0.11, -0.02, 0.04), (0.22, 0.28, 0.13), TAN)
make_cube('Leg_R_boot', ( 0.11, -0.02, 0.04), (0.22, 0.28, 0.13), TAN)

# Lute slung across the back (visible from front as silhouette behind shoulder)
make_cube('Body_lute_body', (0.16, 0.20, 0.95), (0.28, 0.14, 0.32), WOOD)
make_cube('Body_lute_neck', (0.06, 0.18, 1.30), (0.06, 0.06, 0.50), WOOD)
make_cube('Body_lute_head', (0.04, 0.18, 1.62), (0.08, 0.06, 0.10), WOOD)
# Strap (braided crossbody)
make_cube('Body_strap', (0, 0.06, 1.20), (0.30, 0.04, 0.06), GOLDEN_BR)

# Hand-drum at hip (smaller cylinder approximated as flat disk)
make_cube('Body_drum', (-0.30, 0.10, 0.62), (0.16, 0.16, 0.10), WOOD)

# Song-coin pouch
make_cube('Body_pouch', (0.20, -0.18, 0.55), (0.10, 0.08, 0.10), TAN)

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

root = bpy.data.objects.new('Bard_Root', None)
root.empty_display_type = 'PLAIN_AXES'
root.empty_display_size = 0.3
bpy.context.scene.collection.objects.link(root)
for empty in empties.values():
    wm = empty.matrix_world.copy()
    empty.parent = root
    empty.matrix_parent_inverse = root.matrix_world.inverted()
    empty.matrix_world = wm

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

bpy.ops.object.select_all(action='DESELECT')
def select_recursive(o):
    o.select_set(True)
    for c in o.children:
        select_recursive(c)
select_recursive(root)
bpy.context.view_layer.objects.active = root

out_path = '/Users/bbroeking/projects/gj26/models/wanderer_bard.glb'
bpy.ops.export_scene.gltf(filepath=out_path, use_selection=True, export_yup=True, export_apply=True, export_animations=False, export_skins=False, export_format='GLB')
print(f"Exported {out_path} ({os.path.getsize(out_path)} bytes)")
