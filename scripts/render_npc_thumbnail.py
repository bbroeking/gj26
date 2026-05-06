"""Render a GLB to a PNG thumbnail for review.

Usage:
    blender --background --python scripts/render_npc_thumbnail.py -- \
        models/npc_maud_v2.glb docs/npc_v2_renders/maud.png

Sets up: 3/4-view camera, top-light + warm fill, transparent background,
512x640 portrait render. Eevee for speed.
"""
import sys, os, math
import bpy

# ---- parse argv after `--` ---------------------------------------------
argv = sys.argv
if '--' in argv:
    argv = argv[argv.index('--') + 1:]
else:
    argv = []
if len(argv) < 2:
    print("usage: render_npc_thumbnail.py -- <input.glb> <output.png> [front|back]")
    sys.exit(1)
glb_path, png_path = argv[0], argv[1]
view = argv[2] if len(argv) > 2 else 'front'

# ---- reset scene -------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)

# ---- import GLB --------------------------------------------------------
bpy.ops.import_scene.gltf(filepath=os.path.abspath(glb_path))

# Find the bounding box of all imported meshes for camera framing.
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
if not meshes:
    print("no meshes loaded"); sys.exit(2)

min_v = [ float('inf')] * 3
max_v = [-float('inf')] * 3
for o in meshes:
    o.update_tag(refresh={'OBJECT'})
for o in meshes:
    for v in o.bound_box:
        wv = o.matrix_world @ __import__('mathutils').Vector(v)
        for i in range(3):
            if wv[i] < min_v[i]: min_v[i] = wv[i]
            if wv[i] > max_v[i]: max_v[i] = wv[i]
center = [(a + b) / 2 for a, b in zip(min_v, max_v)]
size   = max(max_v[i] - min_v[i] for i in range(3))

# ---- camera ------------------------------------------------------------
cam_data = bpy.data.cameras.new('Cam')
cam = bpy.data.objects.new('Cam', cam_data)
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

# 3/4 angle. front = right-front-above, back = left-back-above so the
# back-mounted accessories (capes, satchels, raven) are visible.
dist = size * 2.0
if view == 'back':
    cam.location = (center[0] - dist * 0.5,
                    center[1] + dist * 1.0,
                    center[2] + size * 0.20)
else:
    cam.location = (center[0] + dist * 0.6,
                    center[1] - dist * 1.0,
                    center[2] + size * 0.20)
# Look at the model centroid (slightly above, so the head reads).
target = (center[0], center[1], center[2] + size * 0.10)
direction = __import__('mathutils').Vector(target) - cam.location
rot_quat = direction.to_track_quat('-Z', 'Y')
cam.rotation_euler = rot_quat.to_euler()
cam_data.lens = 50  # gentle telephoto, less perspective distortion

# ---- lights ------------------------------------------------------------
def add_light(name, kind, loc, energy, color=(1, 1, 1), size=2.0):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind == 'AREA':
        ld.size = size
    obj = bpy.data.objects.new(name, ld)
    obj.location = loc
    bpy.context.scene.collection.objects.link(obj)
    direction = __import__('mathutils').Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    return obj

# Lights are TUNED LOW. EEVEE_NEXT washes out saturated colors when
# lit too hard; for stylized review thumbnails we want the Principled
# BSDF base colors to read true, not get lifted toward white.
add_light('Key',  'AREA',
          (center[0] - size * 1.2, center[1] - size * 1.2, center[2] + size * 1.5),
          80, color=(1.0, 0.95, 0.90), size=size * 1.5)
add_light('Fill', 'AREA',
          (center[0] + size * 1.5, center[1] - size * 0.5, center[2] + size * 0.8),
          30, color=(0.85, 0.90, 1.0), size=size * 1.2)
add_light('Rim',  'AREA',
          (center[0], center[1] + size * 1.5, center[2] + size * 1.0),
          40, color=(1.0, 0.95, 0.90), size=size)

# ---- render settings ---------------------------------------------------
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in [
    e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items
] else 'BLENDER_EEVEE'
scene.render.resolution_x = 512
scene.render.resolution_y = 640
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.filepath = os.path.abspath(png_path)

# Soft world ambient so faces aren't pure black.
world = bpy.data.worlds.new('W'); scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes['Background']
bg.inputs[0].default_value = (0.18, 0.20, 0.24, 1.0)
bg.inputs[1].default_value = 0.15

# ---- render ------------------------------------------------------------
os.makedirs(os.path.dirname(os.path.abspath(png_path)) or '.', exist_ok=True)
bpy.ops.render.render(write_still=True)
print(f"rendered {png_path}")
