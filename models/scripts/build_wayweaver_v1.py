"""Build Wayweaver: a tiny textureless hero bow for Godot/Web export."""

import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_GLB = os.path.join(ROOT, "wayweaver_v1.glb")
PREVIEW = os.path.join(os.path.dirname(ROOT), "tmp", "wayweaver_preview.png")


def material(name, color, roughness=0.82, emission=None, energy=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.12 if "Waysteel" in name else 0.0
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = energy
    return mat


verts = []
faces = []
face_mats = []


def tube(points, radii, mat_index, sides=7):
    """Append a faceted tube along an XZ polyline; Y is its depth axis."""
    start = len(verts)
    count = len(points)
    for i, raw in enumerate(points):
        point = Vector(raw)
        if i == 0:
            tangent = Vector(points[1]) - point
        elif i == count - 1:
            tangent = point - Vector(points[i - 1])
        else:
            tangent = Vector(points[i + 1]) - Vector(points[i - 1])
        tangent.normalize()
        across = Vector((tangent.z, 0.0, -tangent.x)).normalized()
        depth = Vector((0.0, 1.0, 0.0))
        radius = radii[i] if isinstance(radii, (list, tuple)) else radii
        for side in range(sides):
            angle = math.tau * side / sides
            verts.append(tuple(point + across * math.cos(angle) * radius
                               + depth * math.sin(angle) * radius))
    for i in range(count - 1):
        a = start + i * sides
        b = start + (i + 1) * sides
        for side in range(sides):
            faces.append((a + side, a + (side + 1) % sides,
                          b + (side + 1) % sides, b + side))
            face_mats.append(mat_index)
    faces.append(tuple(start + side for side in reversed(range(sides))))
    face_mats.append(mat_index)
    end = start + (count - 1) * sides
    faces.append(tuple(end + side for side in range(sides)))
    face_mats.append(mat_index)


def reset():
    if bpy.context.object is not None and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                  bpy.data.cameras, bpy.data.lights):
        for datablock in list(block):
            if datablock.users == 0:
                block.remove(datablock)


reset()
os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)

materials = [
    material("Waysteel", (0.075, 0.15, 0.145), 0.68),
    material("RootSapCord", (0.68, 0.28, 0.075), 0.88),
    material("QuietTooth", (0.88, 0.79, 0.57), 0.74),
    material("LivingStrand", (0.27, 0.92, 0.62), 0.55,
             emission=(0.27, 0.92, 0.62), energy=2.6),
]

# One asymmetric crescent. The handle is the origin/pivot used by the hand socket.
limb = [
    (-0.19, 0.0, -1.16), (-0.07, 0.0, -0.91), (0.045, 0.0, -0.55),
    (0.105, 0.0, -0.20), (0.095, 0.0, 0.0), (0.055, 0.0, 0.24),
    (-0.045, 0.0, 0.57), (-0.19, 0.0, 0.91), (-0.37, 0.0, 1.18),
]
tube(limb, [0.055, 0.070, 0.082, 0.092, 0.102, 0.092, 0.080, 0.066, 0.050], 0, 8)

# Root-sap bowstring bends through the grip instead of reading as a loose cable.
tube([(-0.19, 0.0, -1.16), (-0.255, 0.0, -0.54), (-0.20, 0.0, 0.0)],
     [0.019, 0.022, 0.025], 1, 6)
tube([(-0.20, 0.0, 0.0), (-0.305, 0.0, 0.57), (-0.37, 0.0, 1.18)],
     [0.025, 0.022, 0.019], 1, 6)

# The one saturation peak: a short living strand, deliberately not a second bow.
tube([(-0.16, -0.012, -0.47), (-0.13, -0.012, -0.05),
      (-0.17, -0.012, 0.38), (-0.25, -0.012, 0.72)],
     [0.013, 0.016, 0.016, 0.012], 3, 6)

# Quiet-Tooth grip and small waysteel bindings keep the center readable at 64 px.
tube([(0.085, 0.0, -0.20), (0.12, 0.0, -0.075), (0.095, 0.0, 0.075),
      (0.055, 0.0, 0.19)], [0.122, 0.137, 0.132, 0.105], 2, 7)
tube([(0.12, 0.0, -0.12), (0.215, 0.0, -0.02)], [0.075, 0.008], 2, 6)
tube([(0.095, 0.0, 0.10), (0.18, 0.0, 0.18)], [0.060, 0.006], 2, 6)
tube([(0.075, 0.0, -0.25), (0.10, 0.0, -0.19)], 0.115, 0, 7)
tube([(0.07, 0.0, 0.19), (0.045, 0.0, 0.27)], 0.105, 0, 7)

mesh = bpy.data.meshes.new("WayweaverMesh")
mesh.from_pydata(verts, [], faces)
mesh.update()
obj = bpy.data.objects.new("Wayweaver", mesh)
bpy.context.collection.objects.link(obj)
for mat in materials:
    obj.data.materials.append(mat)
for polygon, mat_index in zip(obj.data.polygons, face_mats):
    polygon.material_index = mat_index
    polygon.use_smooth = True

bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0.0, 0.0, 0.0))
root = bpy.context.active_object
root.name = "WayweaverRoot"
obj.parent = root

# Export only the reusable asset hierarchy.
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True)
obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format='GLB',
    use_selection=True,
    export_yup=True,
    export_apply=False,
    export_normals=True,
    export_materials='EXPORT',
    export_animations=False,
    export_image_format='AUTO',
)

# Reproducible neutral preview.
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 720
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.film_transparent = True
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'Medium High Contrast'

bpy.ops.object.camera_add(location=(3.15, -5.4, 2.4))
camera = bpy.context.active_object
camera.name = "WayweaverPreviewCamera"
target = Vector((-0.08, 0.0, 0.02))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.lens = 58
scene.camera = camera

bpy.ops.object.light_add(type='AREA', location=(2.2, -3.0, 4.0))
key = bpy.context.active_object
key.name = "WayweaverPreviewKey"
key.data.energy = 720
key.data.shape = 'DISK'
key.data.size = 4.0
key.rotation_euler = (target - key.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.light_add(type='AREA', location=(-3.0, 1.4, 1.3))
fill = bpy.context.active_object
fill.data.energy = 420
fill.data.size = 3.0
fill.rotation_euler = (target - fill.location).to_track_quat('-Z', 'Y').to_euler()

scene.render.filepath = PREVIEW
bpy.ops.render.render(write_still=True)

print({
    "glb": OUT_GLB,
    "preview": PREVIEW,
    "bytes": os.path.getsize(OUT_GLB),
    "vertices": len(mesh.vertices),
    "triangles": sum(len(poly.vertices) - 2 for poly in mesh.polygons),
    "materials": len(materials),
})
