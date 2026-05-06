"""Skinned-rig helpers for Bramblewood character builds.

Why this exists: the original pipeline (`_build_lib.rig_biped`) produces a
rig of EMPTIES — each limb cube is parented to an empty, and animation in
src/anim/*.js rotates the empties per-frame. Cubes themselves are rigid,
so joints visibly seam. This module provides the alternative:

  - `add_mixamo_armature()`  — real Blender Armature with Mixamo-named bones.
  - `bind_pieces_to_bones()` — for each authored mesh piece, create a
                                vertex group named after the matching bone,
                                assign all verts weight=1.0 (rigid skinning),
                                add an Armature modifier.
  - `add_walk_action()`      — bake a simple sin-based walk cycle into the
                                armature's pose-bone keyframes.
  - `export_glb_skinned()`   — export with export_skins=True and
                                export_animations=True. Modifiers are
                                applied at export EXCEPT Armature (the
                                glTF exporter interprets Armature as the
                                skin definition and preserves it).

Phase 1 = rigid weights only — same per-piece visual as today's empty rig
but driven by a real armature so we can use AnimationMixer + retarget
Mixamo / Quaternius animation libraries. Joint fluidity (Phase 2) requires
joining pieces + weight-painting near-joint vertex regions.
"""
import bpy, math, os, mathutils

# Mixamo bone names — using the standard prefix means animations from
# Mixamo / Quaternius Universal Animation Library can retarget straight in.
HIPS = 'mixamorig:Hips'
SPINE = 'mixamorig:Spine'
HEAD = 'mixamorig:Head'
ARM_L = 'mixamorig:LeftArm'
FOREARM_L = 'mixamorig:LeftForeArm'
HAND_L = 'mixamorig:LeftHand'
ARM_R = 'mixamorig:RightArm'
FOREARM_R = 'mixamorig:RightForeArm'
HAND_R = 'mixamorig:RightHand'
UPLEG_L = 'mixamorig:LeftUpLeg'
LEG_L = 'mixamorig:LeftLeg'
FOOT_L = 'mixamorig:LeftFoot'
UPLEG_R = 'mixamorig:RightUpLeg'
LEG_R = 'mixamorig:RightLeg'
FOOT_R = 'mixamorig:RightFoot'


def add_mixamo_armature(rig_pivots, H, root_name='Armature'):
    """Create a real Blender Armature with 14 Mixamo-named bones positioned
    by the existing rig_pivots dict.

    Bone hierarchy (simplified Mixamo — no fingers, no spine subdivision):

        Hips
        ├── Spine
        │   ├── Head
        │   ├── LeftArm → LeftForeArm → LeftHand
        │   └── RightArm → RightForeArm → RightHand
        ├── LeftUpLeg → LeftLeg → LeftFoot
        └── RightUpLeg → RightLeg → RightFoot

    Bone TAILS sit at the next joint down — `use_connect=True` keeps the
    chain rigid, so rotating the parent automatically swings the chain.
    """
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = root_name
    arm_obj.data.name = root_name + '_data'

    bones = arm_obj.data.edit_bones
    # Strip the default 'Bone' that armature_add creates.
    while bones:
        bones.remove(bones[0])

    def add(name, head, tail, parent=None, connect=False):
        b = bones.new(name)
        b.head = mathutils.Vector(head)
        b.tail = mathutils.Vector(tail)
        if parent and parent in bones:
            b.parent = bones[parent]
            b.use_connect = connect
        return b

    body_z  = rig_pivots['Body'][2]
    head_z  = rig_pivots['Head'][2]
    arm_L   = rig_pivots['Arm_L']; arm_R   = rig_pivots['Arm_R']
    elbow_L = rig_pivots['Elbow_L']; elbow_R = rig_pivots['Elbow_R']
    leg_L   = rig_pivots['Leg_L']; leg_R   = rig_pivots['Leg_R']
    knee_L  = rig_pivots['Knee_L']; knee_R  = rig_pivots['Knee_R']

    hips_z   = body_z - 0.30 * H        # below Body pivot, near actual hip
    spine_top_z = body_z + 0.40 * H     # top of chest
    wrist_L_z = elbow_L[2] - 0.45 * H
    wrist_R_z = elbow_R[2] - 0.45 * H
    ankle_z   = 0.10                    # ground-ish

    # --- spine column ---
    add(HIPS,  (0, 0, hips_z),       (0, 0, body_z))
    add(SPINE, (0, 0, body_z),       (0, 0, spine_top_z),
        parent=HIPS, connect=True)
    add(HEAD,  (0, 0, spine_top_z),  (0, 0, head_z + 0.45 * H),
        parent=SPINE, connect=False)

    # --- arms (head sits at shoulder pivot, tail at elbow / wrist / hand) ---
    add(ARM_L, arm_L, (arm_L[0], arm_L[1], elbow_L[2]),
        parent=SPINE)
    add(FOREARM_L, (arm_L[0], arm_L[1], elbow_L[2]),
        (arm_L[0], arm_L[1], wrist_L_z),
        parent=ARM_L, connect=True)
    add(HAND_L, (arm_L[0], arm_L[1], wrist_L_z),
        (arm_L[0], arm_L[1], wrist_L_z - 0.20 * H),
        parent=FOREARM_L, connect=True)

    add(ARM_R, arm_R, (arm_R[0], arm_R[1], elbow_R[2]),
        parent=SPINE)
    add(FOREARM_R, (arm_R[0], arm_R[1], elbow_R[2]),
        (arm_R[0], arm_R[1], wrist_R_z),
        parent=ARM_R, connect=True)
    add(HAND_R, (arm_R[0], arm_R[1], wrist_R_z),
        (arm_R[0], arm_R[1], wrist_R_z - 0.20 * H),
        parent=FOREARM_R, connect=True)

    # --- legs ---
    add(UPLEG_L, leg_L, (leg_L[0], leg_L[1], knee_L[2]),
        parent=HIPS)
    add(LEG_L, (leg_L[0], leg_L[1], knee_L[2]),
        (leg_L[0], leg_L[1], ankle_z),
        parent=UPLEG_L, connect=True)
    add(FOOT_L, (leg_L[0], leg_L[1], ankle_z),
        (leg_L[0], leg_L[1] - 0.30, 0.04),
        parent=LEG_L, connect=True)

    add(UPLEG_R, leg_R, (leg_R[0], leg_R[1], knee_R[2]),
        parent=HIPS)
    add(LEG_R, (leg_R[0], leg_R[1], knee_R[2]),
        (leg_R[0], leg_R[1], ankle_z),
        parent=UPLEG_R, connect=True)
    add(FOOT_R, (leg_R[0], leg_R[1], ankle_z),
        (leg_R[0], leg_R[1] - 0.30, 0.04),
        parent=LEG_R, connect=True)

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj


def bind_pieces_to_bones(mesh_objs, armature, name_to_bone):
    """For each mesh in `mesh_objs`, look up its target bone via
    `name_to_bone(mesh.name)`, create a vertex group with that bone name,
    assign all verts weight 1.0 (RIGID skinning), and add an Armature
    modifier on the mesh that targets `armature`. Also re-parents the
    mesh to the armature object so transforms compose correctly.

    Rigid skinning means each piece rotates as a single unit with its
    bone — visually equivalent to today's empty-parented rig. Phase 2
    (fluid joints) requires joining pieces and blending weights at
    near-joint vertices; this function intentionally does NOT do that.
    """
    bound = 0
    for mesh in mesh_objs:
        bone_name = name_to_bone(mesh.name)
        if not bone_name:
            continue
        # Vertex group named after the bone, all verts at full weight.
        vg = mesh.vertex_groups.get(bone_name)
        if vg is None:
            vg = mesh.vertex_groups.new(name=bone_name)
        vg.add([v.index for v in mesh.data.vertices], 1.0, 'REPLACE')

        # Re-parent to armature, preserving world transform.
        wm = mesh.matrix_world.copy()
        mesh.parent = armature
        mesh.matrix_parent_inverse = armature.matrix_world.inverted()
        mesh.matrix_world = wm

        # Armature modifier — make sure it sits at the BOTTOM of the
        # stack (last to evaluate) so any geometry-shaping modifiers
        # (Cast, Bevel, Subsurf) bake first and the deformation reads
        # the smoothed mesh.
        mod = mesh.modifiers.new('Armature', 'ARMATURE')
        mod.object = armature
        bound += 1
    return bound


def add_walk_action(armature, frames=24, fps=24, name='Walk',
                    leg_swing_deg=30, arm_swing_deg=20,
                    knee_bend_deg=40, elbow_bend_deg=25,
                    hip_bob=0.04):
    """Bake a simple sin-based walk cycle into the armature's pose-bones.

    Returns the new bpy.types.Action (also assigned as the armature's
    active action so the GLB exporter picks it up). The cycle is `frames`
    frames long at `fps` fps — `frames=24, fps=24` = exactly 1 second per
    cycle, matches the convention used by Mixamo / Quaternius.

    Each bone is animated only on rotation_euler / location. No bone-
    name lookups for missing bones — if a bone doesn't exist (e.g. a
    simplified rig without elbows), that body part just doesn't move.
    """
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode='POSE')

    if not armature.animation_data:
        armature.animation_data_create()
    action = bpy.data.actions.new(name=name)
    armature.animation_data.action = action

    bpy.context.scene.render.fps = fps
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = frames

    leg_swing  = math.radians(leg_swing_deg)
    arm_swing  = math.radians(arm_swing_deg)
    knee_bend  = math.radians(knee_bend_deg)
    elbow_bend = math.radians(elbow_bend_deg)
    pose = armature.pose.bones

    def set_xyz(bone_name, frame, rx=0, ry=0, rz=0):
        b = pose.get(bone_name)
        if not b:
            return
        b.rotation_mode = 'XYZ'
        b.rotation_euler = (rx, ry, rz)
        b.keyframe_insert('rotation_euler', frame=frame)

    def set_loc(bone_name, frame, x=0, y=0, z=0):
        b = pose.get(bone_name)
        if not b:
            return
        b.location = (x, y, z)
        b.keyframe_insert('location', frame=frame)

    for f in range(1, frames + 1):
        bpy.context.scene.frame_set(f)
        # phase covers a full 0..2π over the cycle.
        ph = (f - 1) / frames * math.pi * 2
        s = math.sin(ph)
        s2 = math.sin(ph * 2)

        # Hips bob vertically twice per cycle (once per leg-plant).
        set_loc(HIPS, f, z=s2 * hip_bob)

        # Legs counter-swing on X (forward / back), knee bends only
        # during the FORWARD half of the swing — same trick
        # animateGLBKnight uses today.
        set_xyz(UPLEG_L, f, rx=-s * leg_swing)
        set_xyz(UPLEG_R, f, rx= s * leg_swing)
        set_xyz(LEG_L, f, rx=max(0, -s) * knee_bend)
        set_xyz(LEG_R, f, rx=max(0,  s) * knee_bend)

        # Arms counter-swing the legs (opposite phase to same-side leg).
        # Elbow bends as the arm swings forward.
        set_xyz(ARM_L, f, rx= s * arm_swing)
        set_xyz(ARM_R, f, rx=-s * arm_swing)
        set_xyz(FOREARM_L, f, rx=max(0,  s) * elbow_bend)
        set_xyz(FOREARM_R, f, rx=max(0, -s) * elbow_bend)

        # Spine wags slightly twice per cycle for a hint of torso bob.
        set_xyz(SPINE, f, rx=s2 * math.radians(2))

    # Note: in Blender 5+, fcurves moved to action.layers[0].strips[0].slots
    # — the old action.fcurves attribute is gone. We don't need to set
    # extrapolation manually anyway: keyframe_insert defaults to BEZIER
    # interpolation, and the GLB exporter samples the action across its
    # frame range so cycle-extrapolation isn't needed for export. The
    # consumer (THREE.AnimationMixer) sets its own loop mode at clipAction
    # creation time (LoopRepeat by default).

    bpy.ops.object.mode_set(mode='OBJECT')
    return action


def export_glb_skinned(root, out_path):
    """Export the armature + all skinned children as a single GLB with
    embedded skins + animations.

    `export_apply=True` bakes every modifier EXCEPT Armature (the glTF
    exporter is hard-coded to preserve Armature as the skin definition),
    so Cast/Bevel/Subsurf get baked into the geometry while bone weights
    survive.
    """
    bpy.ops.object.select_all(action='DESELECT')
    def sr(o):
        o.select_set(True)
        for c in o.children:
            sr(c)
    sr(root)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_animations=True,
        export_skins=True,
        export_format='GLB',
    )
    print(f"Exported {out_path} ({os.path.getsize(out_path)} bytes)")


def eldra_mesh_to_bone(name):
    """Map an Eldra v2 mesh name (cube/cone/cylinder produced by
    build_npc_eldra_v2.py) to its Mixamo bone for rigid skinning.

    Edge cases handled by ordering — segmented-limb prefixes
    (UpperArm_/Forearm_/Hand_/Thigh_/Shin_/Foot_) are checked BEFORE
    the catch-all 'Body_'/'Aux_' branches so a hip-cap named
    'Body_hip_L' lands on LeftUpLeg, not Spine.
    """
    n = name
    # Head + everything that rides with the head.
    if n.startswith('Head_'):           return HEAD
    if n.startswith('Aux_hair'):        return HEAD
    if n.startswith('Aux_beard'):       return HEAD
    if n.startswith('Aux_mustache'):    return HEAD
    # Arm chain (segmented).
    if n.startswith('UpperArm_L'):      return ARM_L
    if n.startswith('UpperArm_R'):      return ARM_R
    if n.startswith('Forearm_L'):       return FOREARM_L
    if n.startswith('Forearm_R'):       return FOREARM_R
    if n.startswith('Hand_L'):          return HAND_L
    if n.startswith('Hand_R'):          return HAND_R
    # Shoulder caps belong to the arm bone in skinned rig (so rotating
    # the arm carries the cap with it; the joint seam moves to the
    # body-side, hidden by the shawl).
    if n == 'Body_shoulder_L':          return ARM_L
    if n == 'Body_shoulder_R':          return ARM_R
    # Hip caps belong to the upper-leg bone for the same reason.
    if n == 'Body_hip_L':               return UPLEG_L
    if n == 'Body_hip_R':               return UPLEG_R
    # Leg chain (segmented).
    if n.startswith('Thigh_L'):         return UPLEG_L
    if n.startswith('Thigh_R'):         return UPLEG_R
    if n.startswith('Shin_L'):          return LEG_L
    if n.startswith('Shin_R'):          return LEG_R
    if n.startswith('Foot_L'):          return FOOT_L
    if n.startswith('Foot_R'):          return FOOT_R
    # Held items in right hand (staff + lanterns hanging from it).
    if n.startswith('Aux_staff'):       return HAND_R
    if n.startswith('Aux_lant1'):       return HAND_R
    if n.startswith('Aux_lant2'):       return HAND_R
    # Everything else (torso panels, satchel, back bundle, herbs,
    # belt, body grass) rides the Spine bone.
    return SPINE
