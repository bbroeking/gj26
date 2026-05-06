"""Shared utilities for Bramblewood GLB build scripts.

Conventions per ASSET_PIPELINE.md / feedback_blender_bevel_pipeline.md:
- size=2 cubes scaled by (sx/2, sy/2, sz/2) — bevel-pipeline compliant
- TRUE world position before parenting
- Principled BSDF materials (not just diffuse_color)
- remove_doubles before bevel (glTF imports faces with split verts)
- Bevel: limit_method='ANGLE' at 30°, width=min(0.025, dim*0.08), 2 segments
- Export: export_yup=True, export_apply=True, export_animations=False, export_skins=False
"""
import bpy, math, os
import mathutils

def reset_scene(cam_loc=(2.8, -2.8, 1.4), cam_target=(0, 0, 1.0), bg_color=(0.92, 0.88, 0.78, 1.0)):
    bpy.ops.wm.read_homefile(use_empty=True, use_factory_startup=True)
    sd = bpy.data.lights.new('Sun', 'SUN'); sd.energy = 2.5
    s = bpy.data.objects.new('Sun', sd); s.rotation_euler = (0.7, 0, 0.5)
    bpy.context.scene.collection.objects.link(s)
    cd = bpy.data.cameras.new('Cam'); cam = bpy.data.objects.new('Cam', cd)
    cam.location = cam_loc
    cam.rotation_euler = (mathutils.Vector(cam_target) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.collection.objects.link(cam); bpy.context.scene.camera = cam
    bpy.context.scene.world = bpy.data.worlds.new('World'); bpy.context.scene.world.use_nodes = True
    bpy.context.scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = bg_color
    bpy.context.scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 1.5
    bpy.context.scene.render.resolution_x = 800
    bpy.context.scene.render.resolution_y = 800

def _attach_principled_material(obj, name, color, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name + '_mat'); mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.85
    if emission and emission_strength > 0:
        bsdf.inputs['Emission Color'].default_value = (*emission, 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    obj.data.materials.append(mat); return obj

def make_cube(name, loc, dims, color, emission=None, emission_strength=0.0):
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=loc)
    obj = bpy.context.active_object; obj.name = name
    obj.scale = (dims[0]*0.5, dims[1]*0.5, dims[2]*0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _attach_principled_material(obj, name, color, emission, emission_strength)

def make_cone(name, loc, top_r, bot_r, height, color, verts=12,
              emission=None, emission_strength=0.0):
    """Truncated cone (frustum) — native taper, no stacked-cube stair-step.

    Centered vertically at loc. radius1 = bot_r (down-Z), radius2 = top_r (+Z).
    For a limb segment, top_r > bot_r and loc.z is the midpoint between joint
    pivots (e.g. shoulder + elbow). 12 verts is the chunky-low-poly default;
    6–8 reads more facetted, 16+ reads near-cylindrical.
    """
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=bot_r,
                                     radius2=top_r, depth=height, location=loc)
    obj = bpy.context.active_object; obj.name = name
    return _attach_principled_material(obj, name, color, emission, emission_strength)

def make_cylinder(name, loc, dims, color, verts=12,
                  emission=None, emission_strength=0.0):
    """Cylinder with cube-style dims = (full_x_diameter, full_y_diameter, height).

    Built from a unit-radius cylinder then scaled in X/Y so the same call site
    can produce round (dx == dy) or oval (dx != dy) cross-sections — handy for
    flat sandals (wide in Y, short in X). verts=8 reads octagonal; 12 reads
    rounded; 16 reads near-cylinder. Centered vertically at loc.
    """
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=1.0,
                                         depth=2.0, location=loc)
    obj = bpy.context.active_object; obj.name = name
    obj.scale = (dims[0]*0.5, dims[1]*0.5, dims[2]*0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _attach_principled_material(obj, name, color, emission, emission_strength)

def make_sphere(name, loc, dims, color, segments=16, rings=8,
                emission=None, emission_strength=0.0):
    """UV sphere with cube-style dims = (full_x, full_y, full_z).

    Built from a unit sphere then scaled per-axis so squished ovoids (eg head
    0.95H tall × 1.05H wide) work without a separate ellipsoid path. 16×8 is
    the chunky default — visible facets at this scale, smooth after subsurf.
    """
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings,
                                          radius=1.0, location=loc)
    obj = bpy.context.active_object; obj.name = name
    obj.scale = (dims[0]*0.5, dims[1]*0.5, dims[2]*0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _attach_principled_material(obj, name, color, emission, emission_strength)

def apply_cast_modifier(obj, factor=0.5, target='SPHERE'):
    """Cast modifier — pulls vertices toward a target shape (SPHERE / CYLINDER /
    CUBOID). Used in variant E to soften cube panels (factor 0.2) and beard
    cubes (factor 0.5) without replacing them with new primitives. Must run
    BEFORE Bevel + Subsurf in the modifier stack — since modifiers.new() appends
    to the stack tail, call this BEFORE apply_bevel_remove_doubles().
    """
    cast = obj.modifiers.new('Cast', 'CAST')
    cast.factor = factor
    cast.cast_type = target
    return cast

def rig_biped(rig_pivots, root_name, parent_for_fn, joint_parents=None):
    """Create empties + parent meshes by name prefix.
    rig_pivots: dict of {empty_name: (x,y,z) world position}
    parent_for_fn: function(mesh_name) -> empty_name | None
    joint_parents: optional {child_empty: parent_empty} chain map. If a
                   joint name appears here, its empty is parented to the
                   named parent empty (instead of root). Used for knee +
                   elbow secondary joints in segmented limbs.
    """
    joint_parents = joint_parents or {}
    # Pre-rename any mesh whose name collides with a planned empty name
    # (e.g. a build script that calls make_cube('Arm_L', ...) before
    # rig_biped — without this, the empty would be auto-suffixed to
    # 'Arm_L.001' and downstream getObjectByName('Arm_L') in the GLB
    # consumer would miss the rig joint).
    for obj in [o for o in bpy.data.objects if o.type == 'MESH']:
        if obj.name in rig_pivots:
            obj.name = obj.name + '_mesh'

    empties = {}
    for name, loc in rig_pivots.items():
        e = bpy.data.objects.new(name, None); e.empty_display_type = 'PLAIN_AXES'
        e.empty_display_size = 0.10; e.location = loc
        bpy.context.scene.collection.objects.link(e); empties[name] = e

    mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
    for obj in mesh_objs:
        # The pre-rename above turns colliding names like 'Arm_L' into
        # 'Arm_L_mesh', which still matches the existing 'Arm_L_*' branch
        # in biped_parent_for, so the lookup keeps working unchanged.
        pn = parent_for_fn(obj.name)
        if pn and pn in empties:
            wm = obj.matrix_world.copy()
            obj.parent = empties[pn]
            obj.matrix_parent_inverse = empties[pn].matrix_world.inverted()
            obj.matrix_world = wm

    root = bpy.data.objects.new(root_name, None)
    root.empty_display_type = 'PLAIN_AXES'; root.empty_display_size = 0.3
    bpy.context.scene.collection.objects.link(root)
    # Parent in two passes: primary joints to root, secondary joints to
    # their named parent. Two-pass ordering matters because a child
    # secondary joint relies on its parent already existing under root.
    for name, empty in empties.items():
        if name in joint_parents:
            continue
        wm = empty.matrix_world.copy()
        empty.parent = root
        empty.matrix_parent_inverse = root.matrix_world.inverted()
        empty.matrix_world = wm
    for name, parent_name in joint_parents.items():
        if name not in empties or parent_name not in empties:
            continue
        empty = empties[name]; pe = empties[parent_name]
        wm = empty.matrix_world.copy()
        empty.parent = pe
        empty.matrix_parent_inverse = pe.matrix_world.inverted()
        empty.matrix_world = wm
    return root, empties, mesh_objs

def apply_bevel_remove_doubles(mesh_objs, smooth=True, subsurf_level=2,
                               pre_subdivide=1, bevel=True):
    """Polish-pass for the build pipeline.

    Args:
      smooth         : enable shade-smooth so subdivided faces blend.
      pre_subdivide  : edit-mode subdivisions applied BEFORE bevel/subsurf.
                       Each cube face becomes 4 quads (level 1) or 16 quads
                       (level 2), giving the bevel + subsurf far more
                       topology to round, so the final silhouette reads as
                       "soft sculpted form" rather than "rounded cube".
      subsurf_level  : viewport + render levels for the subdivision-surface
                       modifier. 1 = soft, 2 = noticeably rounder, 3 =
                       nearly spherical (and heavy).
      bevel          : add the angle-limited bevel modifier. Set False on
                       primitives that are already smooth (UV sphere, high-
                       segment cylinder) — the bevel triggers on shallow
                       ring-edges and produces visible banding/poles.
    """
    for obj in mesh_objs:
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.remove_doubles(threshold=0.0001)
        if pre_subdivide > 0:
            bpy.ops.mesh.subdivide(number_cuts=pre_subdivide)
        bpy.ops.object.mode_set(mode='OBJECT')
        if bevel:
            dim_min = min(obj.dimensions); bw = min(0.05, dim_min * 0.20)
            bv = obj.modifiers.new('Bevel', 'BEVEL'); bv.width = bw; bv.segments = 4
            bv.limit_method = 'ANGLE'; bv.angle_limit = math.radians(30)
        if subsurf_level > 0:
            ss = obj.modifiers.new('Subsurf', 'SUBSURF')
            ss.levels = subsurf_level
            ss.render_levels = subsurf_level
        if smooth:
            for poly in obj.data.polygons:
                poly.use_smooth = True
            # Auto-smooth so non-coplanar faces don't get smoothed across
            # sharp design edges (e.g. the brim of a hat, the lip of a cuff).
            if hasattr(obj.data, 'use_auto_smooth'):
                obj.data.use_auto_smooth = True
                obj.data.auto_smooth_angle = math.radians(60)

def export_glb(root, out_path):
    bpy.ops.object.select_all(action='DESELECT')
    def sr(o):
        o.select_set(True)
        for c in o.children: sr(c)
    sr(root); bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=out_path, use_selection=True, export_yup=True,
                              export_apply=True, export_animations=False, export_skins=False,
                              export_format='GLB')
    print(f"Exported {out_path} ({os.path.getsize(out_path)} bytes)")

# Standard biped parent_for. Handles both single-cube limbs (Arm_L cube
# parented straight to Arm_L empty) and segmented limbs (UpperArm_L cube
# parented to Arm_L, Forearm_L cube parented to Elbow_L, Hand_L cube
# parented to Elbow_L, etc.) without ambiguity.
def biped_parent_for(name):
    # Segmented-limb prefixes — check before generic Arm_/Leg_ branches.
    if name.startswith('UpperArm_L'): return 'Arm_L'
    if name.startswith('UpperArm_R'): return 'Arm_R'
    if name.startswith('Forearm_L'):  return 'Elbow_L'
    if name.startswith('Forearm_R'):  return 'Elbow_R'
    if name.startswith('Hand_L'):     return 'Elbow_L'
    if name.startswith('Hand_R'):     return 'Elbow_R'
    if name.startswith('Thigh_L'):    return 'Leg_L'
    if name.startswith('Thigh_R'):    return 'Leg_R'
    if name.startswith('Shin_L'):     return 'Knee_L'
    if name.startswith('Shin_R'):     return 'Knee_R'
    if name.startswith('Foot_L'):     return 'Knee_L'
    if name.startswith('Foot_R'):     return 'Knee_R'
    # Original single-cube prefixes.
    if name.startswith('Body_'): return 'Body'
    if name.startswith('Head_'): return 'Head'
    if name == 'Arm_L' or name.startswith('Arm_L_'): return 'Arm_L'
    if name == 'Arm_R' or name.startswith('Arm_R_'): return 'Arm_R'
    if name == 'Leg_L' or name.startswith('Leg_L_'): return 'Leg_L'
    if name == 'Leg_R' or name.startswith('Leg_R_'): return 'Leg_R'
    return None

# Standard quadruped parent_for
def quad_parent_for(name):
    if name.startswith('Body_'): return 'Body'
    if name.startswith('Head_'): return 'Head'
    if name.startswith('Tail_') or name == 'Tail': return 'Tail'
    if name.startswith('Leg_FL') or name == 'Leg_FL': return 'Leg_FL'
    if name.startswith('Leg_FR') or name == 'Leg_FR': return 'Leg_FR'
    if name.startswith('Leg_BL') or name == 'Leg_BL': return 'Leg_BL'
    if name.startswith('Leg_BR') or name == 'Leg_BR': return 'Leg_BR'
    return None

BIPED_PIVOTS = {
    'Body':  (0, 0, 0.74),
    'Head':  (0, 0, 1.30),
    'Arm_L': (-0.28, 0, 1.30),
    'Arm_R': ( 0.28, 0, 1.30),
    'Leg_L': (-0.11, 0, 0.70),
    'Leg_R': ( 0.11, 0, 0.70),
}

QUAD_PIVOTS = {
    'Body':  (0, 0, 0.50),
    'Head':  (0, -0.55, 0.65),
    'Tail':  (0, 0.55, 0.55),
    'Leg_FL':(-0.20, -0.40, 0.30),
    'Leg_FR':( 0.20, -0.40, 0.30),
    'Leg_BL':(-0.20,  0.40, 0.30),
    'Leg_BR':( 0.20,  0.40, 0.30),
}
