"""Clean + slice + rig an AI-generated GLB (Meshy/Tripo/Rodin/Hunyuan)
for the gj26 painted-render pipeline.

What this script does:
  1. Imports the raw AI GLB.
  2. Centers laterally (x=0,y=0) and grounds at z=0.
  3. Decimates to TARGET_TRIS via the Decimate modifier (collapse mode).
  4. Shades smooth (fixes the faceted look on chunky decimate output).
  5. Renames the AI material to `<Name>_Body` so paintifyAuto can derive
     the painted lit/base/shadow palette from its base color.
  6. Slices the mesh into rig parts based on RIG_TYPE:
       - biped:    Head / Torso / Arm_L / Arm_R / Leg_L / Leg_R
       - quadruped: Head / Body / Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR
       - static:   single mesh, no slicing (just Body + Head empties)
  7. Wraps each slice in a named empty so the engine's procedural rig
     animator (animateGLBKnight / animateQuadruped) finds it by name.
  8. Exports with our standard GLB flags to models/<NAME>.glb.

Usage (headless Blender):
  python3 scripts/clean_ai_mesh.py \\
      --input ~/Downloads/Meshy_AI_Foo.glb \\
      --name foo_ai_v1 \\
      --rig biped \\
      --tris 30000

Or env-var driven (compat with the older invocation):
  GJ26_AI_INPUT=~/Downloads/foo.glb \\
  GJ26_AI_NAME=foo_ai_v1 \\
  GJ26_AI_RIG=biped \\
  GJ26_AI_TARGET_TRIS=30000 \\
  /Applications/Blender.app/Contents/MacOS/Blender --background \\
      --python scripts/clean_ai_mesh.py
"""

import sys, os, math, argparse
import bpy
import mathutils

# ---------------------------------------------------------------------------
# Args: support both --flag and env vars (env vars win since they're how
# headless Blender typically invokes us).
# ---------------------------------------------------------------------------

def parse_args():
    """Parse args from CLI and/or env vars. Env vars override defaults but
    CLI args win over env vars."""
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--input',  default=os.environ.get('GJ26_AI_INPUT', ''))
    parser.add_argument('--name',   default=os.environ.get('GJ26_AI_NAME', 'ai_character_v1'))
    parser.add_argument('--rig',    default=os.environ.get('GJ26_AI_RIG', 'biped'),
                        choices=['biped', 'quadruped', 'static'])
    parser.add_argument('--tris',   type=int,
                        default=int(os.environ.get('GJ26_AI_TARGET_TRIS', '30000')))
    parser.add_argument('--rotate-z', type=float,
                        default=float(os.environ.get('GJ26_AI_ROTATE_Z', '0')),
                        help='Degrees to rotate around Z. Use to align face if Meshy chose a different forward axis.')
    parser.add_argument('--head-cut-ratio', type=float,
                        default=float(os.environ.get('GJ26_AI_HEAD_CUT', '0.72')),
                        help='Z fraction for the head/torso cut (0..1, fraction of total height).')
    parser.add_argument('--legs-cut-ratio', type=float,
                        default=float(os.environ.get('GJ26_AI_LEGS_CUT', '0.45')),
                        help='Z fraction for the torso/legs cut.')
    parser.add_argument('--arm-cut-ratio', type=float,
                        default=float(os.environ.get('GJ26_AI_ARM_CUT', '0.30')),
                        help='X fraction of half-width for the arm cuts.')
    # Strip Blender's leading args
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    return parser.parse_args([a for a in argv if not a.startswith('-P') and not a.endswith('.py')])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def wipe_scene():
    """Idempotent — Force object mode, remove every object, GC orphans."""
    for o in bpy.data.objects:
        if o.mode != 'OBJECT':
            try:
                bpy.context.view_layer.objects.active = o
                bpy.ops.object.mode_set(mode='OBJECT')
            except Exception:
                pass
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images,
                  bpy.data.lights, bpy.data.cameras):
        for item in list(block):
            if item.users == 0:
                block.remove(item)

def world_bbox(obj):
    bmin = [float('inf')] * 3
    bmax = [float('-inf')] * 3
    for v in obj.bound_box:
        wv = obj.matrix_world @ mathutils.Vector(v)
        for i in range(3):
            bmin[i] = min(bmin[i], wv[i])
            bmax[i] = max(bmax[i], wv[i])
    return bmin, bmax

def bisect_keep_one_side(obj, plane_co, plane_no, keep_inner):
    """Bisect obj in edit mode and keep only one half. keep_inner=True keeps
    the side the normal points away from (clear_outer); False the opposite."""
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.bisect(plane_co=plane_co, plane_no=plane_no,
                        clear_inner=not keep_inner,
                        clear_outer=keep_inner,
                        use_fill=True)
    bpy.ops.object.mode_set(mode='OBJECT')

def duplicate_and_bisect(src, new_name, plane_co, plane_no, keep_inner):
    """Duplicate src, bisect to keep one half, return the new piece."""
    bpy.ops.object.select_all(action='DESELECT')
    src.select_set(True)
    bpy.context.view_layer.objects.active = src
    bpy.ops.object.duplicate()
    new_piece = bpy.context.active_object
    new_piece.name = new_name
    bisect_keep_one_side(new_piece, plane_co, plane_no, keep_inner)
    return new_piece

def add_empty(name, location, parent):
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=location)
    e = bpy.context.active_object
    e.name = name
    e.parent = parent
    e.matrix_parent_inverse = parent.matrix_world.inverted()
    return e

def parent_keep_transform(child, empty):
    bpy.ops.object.select_all(action='DESELECT')
    child.select_set(True)
    empty.select_set(True)
    bpy.context.view_layer.objects.active = empty
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    args = parse_args()
    if not args.input or not os.path.exists(os.path.expanduser(args.input)):
        print(f"ERROR: --input not set or file missing: {args.input}")
        sys.exit(1)

    NAME = args.name
    RIG = args.rig
    print(f"=== Cleaning AI mesh ===")
    print(f"  Input:  {args.input}")
    print(f"  Name:   {NAME}")
    print(f"  Rig:    {RIG}")
    print(f"  Target tris: {args.tris}")

    wipe_scene()

    # 1. Import
    bpy.ops.import_scene.gltf(filepath=os.path.expanduser(args.input))
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    if not meshes:
        print("ERROR: no meshes imported")
        sys.exit(1)

    # Join into single mesh if Meshy split it
    if len(meshes) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for m in meshes:
            m.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    mesh = bpy.context.view_layer.objects.active or next(o for o in bpy.data.objects if o.type == 'MESH')

    # 2. Apply transforms then re-orient if requested
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if abs(args.rotate_z) > 0.001:
        mesh.rotation_euler = (0, 0, math.radians(args.rotate_z))
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    # 3. Center XY, ground Z
    bmin, bmax = world_bbox(mesh)
    mesh.location.x -= (bmin[0] + bmax[0]) / 2
    mesh.location.y -= (bmin[1] + bmax[1]) / 2
    mesh.location.z -= bmin[2]
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

    # 4. Decimate to TARGET_TRIS
    current_tris = len(mesh.data.polygons)
    if current_tris > args.tris:
        ratio = args.tris / current_tris
        print(f"  Decimating {current_tris} → {args.tris} tris (ratio {ratio:.4f})")
        dec = mesh.modifiers.new('AI_Decimate', 'DECIMATE')
        dec.decimate_type = 'COLLAPSE'
        dec.ratio = ratio
        dec.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier='AI_Decimate')
    bpy.ops.object.shade_smooth()

    # 5. Material rename + neutral painted-ready material
    mesh.name = f'{NAME}_Body'
    mesh.data.materials.clear()
    mat = bpy.data.materials.new(f'{NAME}_Body')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (0.55, 0.55, 0.50, 1.0)
        bsdf.inputs['Roughness'].default_value = 0.88
    mesh.data.materials.append(mat)

    # 6. Re-bbox for rig dimensions
    bmin, bmax = world_bbox(mesh)
    H = bmax[2] - bmin[2]
    half_width = max(abs(bmin[0]), abs(bmax[0]))
    print(f"  Final tris: {len(mesh.data.polygons)}, height: {H:.2f}m, half-width X: {half_width:.2f}m")

    # 7. Root + Body + Head empties first (every rig type needs these)
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = f'{NAME}Root'

    if RIG == 'static':
        body_emp = add_empty('Body', (0, 0, H * 0.50), root)
        head_emp = add_empty('Head', (0, 0, H * 0.85), root)
        parent_keep_transform(mesh, body_emp)
        print("  Rig: static (Body + Head only)")

    elif RIG == 'biped':
        head_cut_z = bmin[2] + H * args.head_cut_ratio
        legs_cut_z = bmin[2] + H * args.legs_cut_ratio
        arm_cut_x  = half_width * args.arm_cut_ratio
        print(f"  Cuts: head_z={head_cut_z:.2f}, legs_z={legs_cut_z:.2f}, arm_x=±{arm_cut_x:.2f}")

        # Slice Head off the top
        head_mesh = duplicate_and_bisect(mesh, f'{NAME}_Head',
                                          (0, 0, head_cut_z), (0, 0, 1), keep_inner=False)
        bisect_keep_one_side(mesh, (0, 0, head_cut_z), (0, 0, 1), keep_inner=True)
        # Slice Legs off the bottom (mesh now contains torso+legs)
        legs_combined = duplicate_and_bisect(mesh, f'{NAME}_LegsCombined',
                                              (0, 0, legs_cut_z), (0, 0, 1), keep_inner=True)
        bisect_keep_one_side(mesh, (0, 0, legs_cut_z), (0, 0, 1), keep_inner=False)
        # Split legs at X=0 into L (+X) / R (-X)
        leg_l_mesh = duplicate_and_bisect(legs_combined, f'{NAME}_Leg_L',
                                            (0, 0, 0), (1, 0, 0), keep_inner=False)
        bisect_keep_one_side(legs_combined, (0, 0, 0), (1, 0, 0), keep_inner=True)
        legs_combined.name = f'{NAME}_Leg_R'
        leg_r_mesh = legs_combined
        # Slice Arms off the torso (mesh is now Torso+arms)
        arm_l_mesh = duplicate_and_bisect(mesh, f'{NAME}_Arm_L',
                                            (arm_cut_x, 0, 0), (1, 0, 0), keep_inner=False)
        bisect_keep_one_side(mesh, (arm_cut_x, 0, 0), (1, 0, 0), keep_inner=True)
        arm_r_mesh = duplicate_and_bisect(mesh, f'{NAME}_Arm_R',
                                            (-arm_cut_x, 0, 0), (1, 0, 0), keep_inner=True)
        bisect_keep_one_side(mesh, (-arm_cut_x, 0, 0), (1, 0, 0), keep_inner=False)
        mesh.name = f'{NAME}_Torso'

        # Apply the painted material to every new piece + shade smooth
        for m in (head_mesh, mesh, arm_l_mesh, arm_r_mesh, leg_l_mesh, leg_r_mesh):
            m.data.materials.clear()
            m.data.materials.append(mat)
            bpy.ops.object.select_all(action='DESELECT')
            m.select_set(True)
            bpy.context.view_layer.objects.active = m
            bpy.ops.object.shade_smooth()

        # Rig empties
        body_emp = add_empty('Body',  (0, 0, (head_cut_z + legs_cut_z) / 2), root)
        head_emp = add_empty('Head',  (0, 0, head_cut_z), root)
        arm_l_emp = add_empty('Arm_L', ( half_width * 0.40, 0, head_cut_z - 0.10), root)
        arm_r_emp = add_empty('Arm_R', (-half_width * 0.40, 0, head_cut_z - 0.10), root)
        leg_l_emp = add_empty('Leg_L', ( half_width * 0.20, 0, legs_cut_z), root)
        leg_r_emp = add_empty('Leg_R', (-half_width * 0.20, 0, legs_cut_z), root)

        # Parent each slice to its empty
        parent_keep_transform(head_mesh, head_emp)
        parent_keep_transform(mesh, body_emp)
        parent_keep_transform(arm_l_mesh, arm_l_emp)
        parent_keep_transform(arm_r_mesh, arm_r_emp)
        parent_keep_transform(leg_l_mesh, leg_l_emp)
        parent_keep_transform(leg_r_mesh, leg_r_emp)
        print("  Rig: biped (6 sliced parts)")

    elif RIG == 'quadruped':
        # Quadruped: head/tail at front/back; legs split front/back and L/R.
        # For a quadruped, "length" is the largest horizontal axis.
        length_axis_is_x = abs(bmax[0] - bmin[0]) > abs(bmax[1] - bmin[1])
        # We assume face is on +X (after the optional --rotate-z); legs split
        # by Y for L/R.
        head_cut = bmin[0] + (bmax[0] - bmin[0]) * 0.70
        tail_cut = bmin[0] + (bmax[0] - bmin[0]) * 0.15
        front_cut = (head_cut + tail_cut) / 2  # plane separating front/back legs
        leg_z_top = bmin[2] + H * 0.40  # above legs / below body
        print(f"  Quadruped cuts: head_x={head_cut:.2f}, tail_x={tail_cut:.2f}, "
              f"front/back_x={front_cut:.2f}, leg_z_top={leg_z_top:.2f}")

        # Head: front (+X) chunk above the leg plane
        head_mesh = duplicate_and_bisect(mesh, f'{NAME}_Head',
                                          (head_cut, 0, 0), (1, 0, 0), keep_inner=False)
        bisect_keep_one_side(mesh, (head_cut, 0, 0), (1, 0, 0), keep_inner=True)
        # Tail: back (-X) chunk
        tail_mesh = duplicate_and_bisect(mesh, f'{NAME}_Tail',
                                          (tail_cut, 0, 0), (1, 0, 0), keep_inner=True)
        bisect_keep_one_side(mesh, (tail_cut, 0, 0), (1, 0, 0), keep_inner=False)
        # Legs: bottom chunk
        legs_combined = duplicate_and_bisect(mesh, f'{NAME}_LegsCombined',
                                              (0, 0, leg_z_top), (0, 0, 1), keep_inner=True)
        bisect_keep_one_side(mesh, (0, 0, leg_z_top), (0, 0, 1), keep_inner=False)
        # Split legs front/back at front_cut, then L/R at y=0
        fl_legs = duplicate_and_bisect(legs_combined, f'{NAME}_FrontLegs',
                                        (front_cut, 0, 0), (1, 0, 0), keep_inner=False)
        bisect_keep_one_side(legs_combined, (front_cut, 0, 0), (1, 0, 0), keep_inner=True)
        bl_legs = legs_combined
        # Front L (+Y) / R (-Y)
        leg_fl_mesh = duplicate_and_bisect(fl_legs, f'{NAME}_Leg_FL',
                                             (0, 0, 0), (0, 1, 0), keep_inner=False)
        bisect_keep_one_side(fl_legs, (0, 0, 0), (0, 1, 0), keep_inner=True)
        fl_legs.name = f'{NAME}_Leg_FR'
        leg_fr_mesh = fl_legs
        # Back L/R
        leg_bl_mesh = duplicate_and_bisect(bl_legs, f'{NAME}_Leg_BL',
                                             (0, 0, 0), (0, 1, 0), keep_inner=False)
        bisect_keep_one_side(bl_legs, (0, 0, 0), (0, 1, 0), keep_inner=True)
        bl_legs.name = f'{NAME}_Leg_BR'
        leg_br_mesh = bl_legs
        mesh.name = f'{NAME}_Body'

        # Material + shade smooth on every piece
        for m in (head_mesh, mesh, tail_mesh,
                  leg_fl_mesh, leg_fr_mesh, leg_bl_mesh, leg_br_mesh):
            m.data.materials.clear()
            m.data.materials.append(mat)
            bpy.ops.object.select_all(action='DESELECT')
            m.select_set(True)
            bpy.context.view_layer.objects.active = m
            bpy.ops.object.shade_smooth()

        # Rig empties for quadruped
        body_emp = add_empty('Body', (0, 0, leg_z_top + 0.05), root)
        head_emp = add_empty('Head', (head_cut + 0.10, 0, leg_z_top + 0.15), root)
        tail_emp = add_empty('Tail', (tail_cut - 0.05, 0, leg_z_top + 0.05), root)
        leg_fl_emp = add_empty('Leg_FL', (front_cut + 0.15,  half_width * 0.40, leg_z_top), root)
        leg_fr_emp = add_empty('Leg_FR', (front_cut + 0.15, -half_width * 0.40, leg_z_top), root)
        leg_bl_emp = add_empty('Leg_BL', (front_cut - 0.15,  half_width * 0.40, leg_z_top), root)
        leg_br_emp = add_empty('Leg_BR', (front_cut - 0.15, -half_width * 0.40, leg_z_top), root)
        parent_keep_transform(head_mesh, head_emp)
        parent_keep_transform(mesh, body_emp)
        parent_keep_transform(tail_mesh, tail_emp)
        parent_keep_transform(leg_fl_mesh, leg_fl_emp)
        parent_keep_transform(leg_fr_mesh, leg_fr_emp)
        parent_keep_transform(leg_bl_mesh, leg_bl_emp)
        parent_keep_transform(leg_br_mesh, leg_br_emp)
        print("  Rig: quadruped (7 sliced parts)")

    # 8. Export
    project_root = os.environ.get('GJ26_PROJECT_ROOT',
                                  os.path.abspath(os.path.dirname(__file__) + '/..'))
    out_path = os.path.join(project_root, 'models', f'{NAME}.glb')
    bpy.ops.object.select_all(action='DESELECT')
    def select_subtree(o):
        o.select_set(True)
        for c in o.children: select_subtree(c)
    select_subtree(root)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=out_path, export_format='GLB', use_selection=True,
        export_yup=True, export_apply=True, export_normals=True,
        export_materials='EXPORT', export_animations=False, export_skins=False,
    )

    total_tris = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == 'MESH')
    size_kb = round(os.path.getsize(out_path) / 1024, 1)
    print(f"\n=== Exported {out_path} ===")
    print(f"  {sum(1 for o in bpy.data.objects if o.type == 'MESH')} mesh(es), "
          f"{total_tris} tris, {size_kb}KB")

main()
