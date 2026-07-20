"""Deterministically build the temporary Pale Oath rootroad asset family.

Run through Blender's background Python runner.  All world props are low-poly,
Principled/toon-friendly GLBs with a named root; no Meshy source or credit is
claimed.  The production organic characters live in the separate deterministic
``build_pale_oath_characters_v1.py`` source so this prop kit cannot overwrite
them with a blockout.
"""

import math
from pathlib import Path
import bpy

ROOT = Path("/Users/bbroeking/projects/gj26/models")


def wipe():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for blocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        for block in list(blocks):
            if block.users == 0:
                blocks.remove(block)


def mat(name, color, emission=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = 0.92
    if emission:
        (b.inputs.get("Emission Color") or b.inputs.get("Emission")).default_value = (*emission, 1.0)
        b.inputs["Emission Strength"].default_value = 1.8
    return m


STONE = None
ROOT_BARK = None
MOSS = None
GOLD = None
PALE = None
BRASS = None
PAPER = None


def cube(name, pos, size, material, parent, bevel=0.035, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(material)
    if bevel:
        mod = o.modifiers.new("Storybook bevel", "BEVEL")
        mod.width = min(bevel, min(size) * 0.18)
        mod.segments = 2
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(30)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.parent = parent
    return o


def cylinder(name, pos, radius, depth, material, parent, verts=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=pos)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    o.parent = parent
    return o


def sphere(name, pos, scale, material, parent):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1, location=pos)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    o.parent = parent
    return o


def asset_root(name, placeholder=False):
    root = bpy.data.objects.new(name, None)
    root["wayfinder_asset"] = name
    if placeholder:
        root["status"] = "TEMPORARY_PROCEDURAL_SILHOUETTE_NOT_FINAL_MESHY_ORGANIC_ASSET"
    bpy.context.collection.objects.link(root)
    return root


def export(root, filename):
    # Debug-only assets may live in a nested folder; production callers continue
    # to pass a top-level filename.
    (ROOT / filename).parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in bpy.context.scene.objects:
        if o.parent == root:
            o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(ROOT / filename), export_format="GLB",
                              use_selection=True, export_yup=True, export_apply=True,
                              export_normals=True, export_materials="EXPORT",
                              export_animations=False, export_lights=False,
                              export_cameras=False)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def make_rootroad_roots():
    r = asset_root("RootroadModularKit")
    cube("RootroadFloor", (0, 0, 0.08), (1.45, 1.45, .08), ROOT_BARK, r, .06)
    for side in (-1, 1):
        for i in range(3):
            cube("RootRib_%s_%d" % (side, i), (side * (1.0 + .1 * i), -.55 + i * .55, .38 + .13 * i),
                 (.12, .60, .12), ROOT_BARK, r, .04, (0, side * .28, side * .15))
    export(r, "biome_rootroads_roots_v1.glb")


def make_pale_well():
    r = asset_root("PaleWell")
    for i in range(8):
        a = i * math.tau / 8
        cube("WellStone_%02d" % i, (math.cos(a) * .54, math.sin(a) * .54, .17), (.25, .16, .18), STONE, r, .035, (0, 0, a))
    cylinder("PaleWater", (0, 0, .30), .43, .05, PALE, r, 12)
    for i in range(3):
        sphere("GlowMote_%d" % i, (.18 * (i - 1), .16 * (i % 2), .48 + .1 * i), (.05, .05, .05), PALE, r)
    export(r, "landmark_pale_well_v1.glb")


def make_wellmoss():
    r = asset_root("WellmossPatch")
    for i in range(11):
        a = i * 2.399
        d = .14 + .055 * (i % 4)
        sphere("Wellmoss_%02d" % i, (math.cos(a) * d, math.sin(a) * d, .09), (.16, .12, .10), MOSS, r)
    export(r, "prop_wellmoss_patch_v1.glb")


def make_wildgold():
    r = asset_root("WildgoldVein")
    sphere("VeinRock", (0, 0, .32), (.62, .45, .42), STONE, r)
    for i in range(5):
        cube("Wildgold_%d" % i, (-.28 + i * .14, -.34 + .12 * (i % 2), .52), (.07, .06, .26), GOLD, r, .015, (.2, .3 * i, .1))
    export(r, "prop_wildgold_vein_v1.glb")


def make_bell(index):
    r = asset_root("OathBellpost%d" % index)
    cube("BellPost", (0, 0, .95), (.12, .12, .95), ROOT_BARK, r, .025)
    cube("BellArm", (.26, 0, 1.62), (.33, .10, .09), ROOT_BARK, r, .025)
    cylinder("OathBell", (.53, 0, 1.38), .23, .31, BRASS, r, 10)
    sphere("BellClapper", (.53, 0, 1.18), (.07, .07, .10), STONE, r)
    export(r, "prop_oath_bellpost_%d_v1.glb" % index)


def make_lift_and_stone():
    r = asset_root("RootroadLiftWellhouse")
    cube("LiftPlatform", (0, 0, .20), (1.05, 1.05, .12), ROOT_BARK, r, .05)
    for x in (-.82, .82):
        cube("WellhousePost", (x, 0, 1.10), (.10, .10, 1.1), ROOT_BARK, r)
    cube("Winch", (0, 0, 1.65), (.92, .15, .12), BRASS, r)
    cylinder("WinchWheel", (0, .15, 1.65), .25, .10, BRASS, r, 10)
    export(r, "landmark_rootroad_lift_wellhouse_v1.glb")
    r = asset_root("HodRestoredOathstone")
    cube("Oathstone", (0, 0, .72), (.40, .30, .72), STONE, r, .06)
    cube("OathRune", (0, -.305, .74), (.12, .012, .22), PALE, r, .006)
    export(r, "landmark_hod_oathstone_v1.glb")


def make_rubbing_and_display():
    r = asset_root("OathRubbing")
    cube("RubbingSlab", (0, 0, .44), (.45, .10, .62), STONE, r, .04, (.15, 0, 0))
    for i in range(4):
        cube("RubbingMark_%d" % i, (-.16 + i * .11, -.108, .42 + .07 * (i % 2)), (.035, .01, .12), PALE, r, .004)
    export(r, "prop_oath_rubbing_v1.glb")
    r = asset_root("PaleOathSettlementDisplay")
    cube("DisplayPlinth", (0, 0, .18), (.76, .52, .18), STONE, r, .04)
    sphere("ThreadCoil", (0, 0, .54), (.30, .30, .24), PALE, r)
    cube("OathNailDisplay", (.38, 0, .58), (.05, .05, .40), BRASS, r, .01, (0, .5, 0))
    export(r, "settlement_pale_oath_display_v1.glb")


def make_legacy_debug_blockouts():
    # Legacy diagnostic-only blockouts.  They are deliberately not called by
    # the production build and are not part of the Godot/Web asset registry.
    r = asset_root("BarrowJarlTemporarySilhouette", True)
    for name, p, s, m in [("Body", (0, 0, 1.05), (.55, .35, .82), STONE),
                           ("Head", (0, -.05, 1.92), (.36, .30, .34), STONE),
                           ("Crown", (0, -.04, 2.25), (.45, .34, .12), BRASS)]:
        cube(name, p, s, m, r, .06)
    export(r, "debug/boss_barrow_jarl_blockout_v0.glb")
    r = asset_root("OathboundTemporarySilhouette", True)
    cube("Body", (0, 0, .82), (.35, .26, .62), STONE, r, .05)
    cube("Head", (0, -.02, 1.42), (.24, .22, .25), PALE, r, .04)
    cube("Shield", (.34, 0, .86), (.06, .34, .44), BRASS, r, .02)
    export(r, "debug/enemy_oathbound_blockout_v0.glb")


wipe()
STONE = mat("RootroadStone", (.31, .36, .38))
ROOT_BARK = mat("OldRoot", (.22, .16, .12))
MOSS = mat("Wellmoss", (.31, .58, .38), (.12, .32, .18))
GOLD = mat("Wildgold", (.88, .64, .18), (.72, .42, .06))
PALE = mat("PaleLight", (.54, .76, .92), (.35, .65, 1.0))
BRASS = mat("OathBrass", (.68, .49, .20))
PAPER = mat("RubbingPaper", (.72, .68, .54))
make_rootroad_roots(); make_pale_well(); make_wellmoss(); make_wildgold()
for bell_number in (1, 2, 3): make_bell(bell_number)
make_lift_and_stone(); make_rubbing_and_display()
print({"status": "ok", "assets": "pale_oath_world_v1"})
