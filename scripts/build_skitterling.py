"""Build skitterling.glb — small thorn-fae creature, knee-height."""
import bpy, math, os
import mathutils

bpy.ops.wm.read_homefile(use_empty=True, use_factory_startup=True)
sd = bpy.data.lights.new('Sun', 'SUN'); sd.energy = 2.5
s = bpy.data.objects.new('Sun', sd); s.rotation_euler = (0.7, 0, 0.5)
bpy.context.scene.collection.objects.link(s)
cd = bpy.data.cameras.new('Cam'); cam = bpy.data.objects.new('Cam', cd)
cam.location = (1.8, -1.8, 0.9)
cam.rotation_euler = (mathutils.Vector((0, 0, 0.5)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
bpy.context.scene.collection.objects.link(cam); bpy.context.scene.camera = cam
bpy.context.scene.world = bpy.data.worlds.new('World'); bpy.context.scene.world.use_nodes = True
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

# Skitterling — small ~0.6m tall total
MOSS  = (0.40, 0.50, 0.18)
DARK_THORN = (0.22, 0.18, 0.10)
GLASS_BLACK = (0.04, 0.04, 0.04)
LEAF_BROWN = (0.46, 0.32, 0.18)
SKIN  = (0.55, 0.62, 0.30)  # yellow-green moss

# Body
make_cube('Body_torso', (0, 0, 0.32), (0.18, 0.16, 0.20), SKIN)
# Prickle skin shoulders (thorn texture suggested by darker offset)
make_cube('Body_thorns', (0, 0.08, 0.36), (0.16, 0.04, 0.14), DARK_THORN)
# Belly belt (mossy)
make_cube('Body_belt', (0, -0.08, 0.30), (0.18, 0.04, 0.04), DARK_THORN)

# Head
make_cube('Head_skull', (0, 0, 0.50), (0.20, 0.18, 0.16), SKIN)
# Single dried leaf as a cap
make_cube('Head_leaf_cap', (0, 0, 0.62), (0.16, 0.16, 0.04), LEAF_BROWN)
# Glassy black eye beads (large)
make_cube('Head_eye_L', (-0.05, -0.10, 0.51), (0.05, 0.04, 0.05), GLASS_BLACK)
make_cube('Head_eye_R', ( 0.05, -0.10, 0.51), (0.05, 0.04, 0.05), GLASS_BLACK)
# Tiny fangs (cream)
make_cube('Head_fang_L', (-0.03, -0.10, 0.42), (0.02, 0.02, 0.04), (0.92, 0.86, 0.72))
make_cube('Head_fang_R', ( 0.03, -0.10, 0.42), (0.02, 0.02, 0.04), (0.92, 0.86, 0.72))

# Arms (clawed, hunched)
make_cube('Arm_L', (-0.13, -0.04, 0.35), (0.08, 0.10, 0.18), SKIN)
make_cube('Arm_R', ( 0.13, -0.04, 0.35), (0.08, 0.10, 0.18), SKIN)
make_cube('Arm_L_claw', (-0.13, -0.10, 0.22), (0.06, 0.04, 0.06), DARK_THORN)
make_cube('Arm_R_claw', ( 0.13, -0.10, 0.22), (0.06, 0.04, 0.06), DARK_THORN)

# Bramble stick (held in right hand)
make_cube('Arm_R_stick', (0.18, -0.12, 0.30), (0.04, 0.04, 0.30), DARK_THORN)

# Legs (short)
make_cube('Leg_L', (-0.06, 0, 0.10), (0.10, 0.10, 0.20), SKIN)
make_cube('Leg_R', ( 0.06, 0, 0.10), (0.10, 0.10, 0.20), SKIN)
# Feet
make_cube('Leg_L_foot', (-0.06, -0.04, 0.02), (0.12, 0.16, 0.04), DARK_THORN)
make_cube('Leg_R_foot', ( 0.06, -0.04, 0.02), (0.12, 0.16, 0.04), DARK_THORN)

# === Rig (biped, scaled-down pivots) ===
rig_pivots = {'Body':(0,0,0.22),'Head':(0,0,0.42),'Arm_L':(-0.11,0,0.42),'Arm_R':(0.11,0,0.42),'Leg_L':(-0.06,0,0.20),'Leg_R':(0.06,0,0.20)}
empties = {}
for name, loc in rig_pivots.items():
    e = bpy.data.objects.new(name, None); e.empty_display_type = 'PLAIN_AXES'
    e.empty_display_size = 0.05; e.location = loc
    bpy.context.scene.collection.objects.link(e); empties[name] = e

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

root = bpy.data.objects.new('Skitterling_Root', None)
root.empty_display_type = 'PLAIN_AXES'; root.empty_display_size = 0.1
bpy.context.scene.collection.objects.link(root)
for empty in empties.values():
    wm = empty.matrix_world.copy()
    empty.parent = root
    empty.matrix_parent_inverse = root.matrix_world.inverted()
    empty.matrix_world = wm

for obj in mesh_objs:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    dim_min = min(obj.dimensions); bw = min(0.025, dim_min * 0.08)
    bv = obj.modifiers.new('Bevel', 'BEVEL'); bv.width = bw; bv.segments = 2
    bv.limit_method = 'ANGLE'; bv.angle_limit = math.radians(30)

bpy.ops.object.select_all(action='DESELECT')
def sr(o):
    o.select_set(True)
    for c in o.children: sr(c)
sr(root); bpy.context.view_layer.objects.active = root
out = '/Users/bbroeking/projects/gj26/models/skitterling.glb'
bpy.ops.export_scene.gltf(filepath=out, use_selection=True, export_yup=True, export_apply=True, export_animations=False, export_skins=False, export_format='GLB')
print(f"Exported {out} ({os.path.getsize(out)} bytes)")
