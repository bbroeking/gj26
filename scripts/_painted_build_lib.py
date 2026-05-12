"""Helpers shared by all painted-render rebuilds (v4 Eldra, v3 Hod, ...).

Authoring frame: face on +X, lateral on ±Y, up on +Z. The wrappers in this
module remap to Blender's -Y-forward convention at runtime, then export
with `export_yup=True` so the engine's procedural walk animator (which
expects local X = world +X = lateral) gets clean rotations on each limb.

Two box flavors:
  - add_box       — small bevel + remove_doubles. For most parts.
  - add_soft_box  — heavy bevel + 1 level of subdivision-surface for
                    cushiony cloth/leather pieces. Bigger triangle cost.

Material/rig conventions:
  - Per-part materials get author-named hexes; the painted_materials.js
    paintifyAuto path derives palette from material.color so any name works.
  - Empty rig: Body, Head, Arm_L, Arm_R, Leg_L, Leg_R as joint pivots.
    Sub-meshes parent to the matching empty so the procedural walk
    animator drives them.
"""

import bpy
import math
import os


def hex_rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16) / 255.0,
            int(h[2:4], 16) / 255.0,
            int(h[4:6], 16) / 255.0)


def make_material(name, color_hex, roughness=0.85, emissive_hex=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    if not bsdf:
        for n in mat.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                bsdf = n; break
    bsdf.inputs['Base Color'].default_value = (*hex_rgb(color_hex), 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = 0.0
    if emissive_hex and 'Emission Color' in bsdf.inputs:
        bsdf.inputs['Emission Color'].default_value = (*hex_rgb(emissive_hex), 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    elif emissive_hex and 'Emission' in bsdf.inputs:
        bsdf.inputs['Emission'].default_value = (*hex_rgb(emissive_hex), 1.0)
        if 'Emission Strength' in bsdf.inputs:
            bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat


def _parent_to(o, parent):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)


# ---- Authoring frame remap (face on +X → Blender world -Y) ----

def _xform_pos(p):    return (p[1], -p[0], p[2])
def _xform_dims(d):   return (d[1], d[0], d[2])
def _xform_rot(r):    return (r[1], -r[0], r[2])
def _xform_scale(s):  return (s[1], s[0], s[2])


def add_box(name, world_center, dims, mat, parent, bevel_width=0.020, rot=(0, 0, 0)):
    cx, cy, cz = _xform_pos(world_center)
    sx, sy, sz = _xform_dims(dims)
    rot = _xform_rot(rot)
    bpy.ops.mesh.primitive_cube_add(size=2, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx / 2, sy / 2, sz / 2)
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    mod = o.modifiers.new('Bevel', 'BEVEL')
    mod.width = min(bevel_width, min(sx, sy, sz) * 0.08)
    mod.segments = 2
    mod.limit_method = 'ANGLE'
    mod.angle_limit = math.radians(30)
    bpy.ops.object.shade_smooth()
    _parent_to(o, parent)
    return o


def add_soft_box(name, world_center, dims, mat, parent, rot=(0, 0, 0)):
    """Heavily-rounded box for clothing / body parts. Aggressive bevel +
    1 level of subdivision-surface so corners round into a clay-figurine
    pillow shape rather than reading as a stiff cuboid."""
    cx, cy, cz = _xform_pos(world_center)
    sx, sy, sz = _xform_dims(dims)
    rot = _xform_rot(rot)
    bpy.ops.mesh.primitive_cube_add(size=2, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx / 2, sy / 2, sz / 2)
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    bev = o.modifiers.new('Bevel', 'BEVEL')
    bev.width = min(sx, sy, sz) * 0.18
    bev.segments = 3
    bev.limit_method = 'NONE'
    sub = o.modifiers.new('Subsurf', 'SUBSURF')
    sub.levels = 1
    sub.render_levels = 1
    bpy.ops.object.shade_smooth()
    _parent_to(o, parent)
    return o


def add_sphere(name, world_center, radius, mat, parent, segments=12, rings=8, scale=(1, 1, 1)):
    cx, cy, cz = _xform_pos(world_center)
    sx, sy, sz = _xform_scale(scale)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, segments=segments,
                                          ring_count=rings, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    if (sx, sy, sz) != (1, 1, 1):
        o.scale = (sx, sy, sz)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.shade_smooth()
    _parent_to(o, parent)
    return o


def add_cylinder(name, world_center, radius, height, mat, parent, vertices=12, rot=(0, 0, 0)):
    cx, cy, cz = _xform_pos(world_center)
    rot = _xform_rot(rot)
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height,
                                         vertices=vertices, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    _parent_to(o, parent)
    return o


def add_cone(name, world_center, radius_base, radius_tip, height, mat, parent,
             vertices=8, rot=(0, 0, 0)):
    cx, cy, cz = _xform_pos(world_center)
    rot = _xform_rot(rot)
    bpy.ops.mesh.primitive_cone_add(
        radius1=radius_tip, radius2=radius_base, depth=height,
        vertices=vertices, location=(cx, cy, cz),
    )
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    _parent_to(o, parent)
    return o


def add_empty(name, location, parent=None, rot=(0, 0, 0)):
    loc = _xform_pos(location)
    rot = _xform_rot(rot)
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=loc)
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    if parent is not None:
        _parent_to(o, parent)
    return o


def wipe_by_prefix(prefixes):
    for o in list(bpy.data.objects):
        if o.name.startswith(prefixes):
            bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users == 0: bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        if m.users == 0: bpy.data.materials.remove(m)


def export_glb(root, out_path):
    bpy.ops.object.select_all(action='DESELECT')
    def select_subtree(obj):
        obj.select_set(True)
        for c in obj.children:
            select_subtree(c)
    select_subtree(root)
    bpy.context.view_layer.objects.active = root
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_normals=True,
        export_materials='EXPORT',
        export_animations=False,
        export_skins=False,
        export_image_format='AUTO',
    )
