"""Shrine Pedestal — fixture for shrine-tagged dungeon rooms.

A stepped stone pedestal wrapped in briar twigs, with a glowing rune-disc
on top and a faceted gemstone above it. Soft warm emissive — reads as
"rune-pressing point" in the procgen + cartography ecosystem (the rune
mechanic is the cartography lvl 30+ feature; this prop foreshadows it).

The dungeon's runtime currently uses a procedural three.js version of this
in src/scene/dungeon.js so shrines work without the GLB. This script
produces models/shrine_pedestal.glb so the codex viewer can show it and
so a future commit can swap the procedural decor for an authored one.

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_shrine_pedestal.py

Output: models/shrine_pedestal.glb
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))

import bpy, mathutils
from _build_lib import (
    reset_scene, make_cube, apply_bevel_remove_doubles, export_glb,
)

# ---- design knobs ------------------------------------------------------
COL_STONE_LOW = (0.42, 0.36, 0.32)
COL_STONE_UP  = (0.48, 0.43, 0.38)
COL_BRIAR     = (0.18, 0.13, 0.09)
COL_RUNE      = (1.00, 0.78, 0.45)
COL_GEM       = (1.00, 0.69, 0.38)

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(1.4, -1.4, 0.9), cam_target=(0, 0, 0.4))

# Stepped base — two stone tiers.
make_cube('Pedestal_base_low', (0, 0, 0.09),
          (0.70, 0.70, 0.18), COL_STONE_LOW)
make_cube('Pedestal_base_up',  (0, 0, 0.25),
          (0.55, 0.55, 0.14), COL_STONE_UP)

# Briar twigs — four short bound stems at the corners of the lower tier.
# Slight rotation each so they read as wrapping the stone, not floating.
for i, (bx, bz) in enumerate([(-0.30, -0.30), (0.30, -0.30),
                              (-0.30, 0.30), (0.30, 0.30)]):
    obj = make_cube(f'Pedestal_briar_{i}', (bx, bz, 0.17),
                    (0.06, 0.06, 0.34), COL_BRIAR)
    # Splay them outward — rotate around Z by atan2(bz, bx) so the briar
    # leans away from the stone center.
    obj.rotation_euler = (0, 0, math.atan2(bz, bx))

# Rune disc — flat plate on top of the upper tier. Emissive so it reads
# as glowing even in dim dungeon light.
disc = make_cube('Pedestal_rune_disc', (0, 0, 0.34),
                 (0.40, 0.40, 0.04), COL_RUNE,
                 emission=COL_RUNE, emission_strength=1.4)

# Gemstone — octahedron (faceted) hovering just above the disc. Built
# manually since make_cube only does cubes.
bpy.ops.mesh.primitive_solid_add(source='Octahedron', size=0.18)
gem = bpy.context.active_object
gem.name = 'Pedestal_gem'
gem.location = (0, 0, 0.55)
gem.rotation_euler = (0, 0, math.pi / 4)
gem_mat = bpy.data.materials.new('Pedestal_gem_mat')
gem_mat.use_nodes = True
bsdf = gem_mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (*COL_GEM, 1.0)
bsdf.inputs['Roughness'].default_value = 0.20
bsdf.inputs['Emission Color'].default_value = (*COL_GEM, 1.0)
bsdf.inputs['Emission Strength'].default_value = 1.2
gem.data.materials.append(gem_mat)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

# Single Empty root so the GLB exports as one object.
root = bpy.data.objects.new('ShrinePedestal_Root', None)
root.empty_display_type = 'PLAIN_AXES'
bpy.context.scene.collection.objects.link(root)
for o in [obj for obj in bpy.data.objects if obj.type == 'MESH']:
    wm = o.matrix_world.copy()
    o.parent = root
    o.matrix_parent_inverse = root.matrix_world.inverted()
    o.matrix_world = wm

# Bevel + remove_doubles per the standard pipeline.
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/shrine_pedestal.glb')
export_glb(root, out)
print(f"shrine_pedestal — base 0.70m × 0.70m × 0.55m tall, {len(all_meshes)} parts")
