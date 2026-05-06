"""Head-height-driven anchor template for Bramblewood character builds.

WHY: every prior build script hardcoded metric values (Body z = 0.74,
Arm z = 1.30 …). One tweak meant editing N scripts, and proportions
drifted between archetypes because nothing tied them together. This
template derives every joint from a single H = head_diameter, so the
whole rig rescales coherently and adding a new archetype is one row
in ARCHETYPE_HEIGHTS.

The locked design knobs are:
  - ARCHETYPE_HEIGHTS  — total height in heads, per archetype family
  - BODY_FRACTIONS     — joint Z position as fraction of total height
  - HORIZONTAL         — joint X offset in head-units
  - SOCKET_OFFSETS     — auxiliary attach points relative to a parent
                         joint, in head-units (so they scale with H)

Usage from a build script (Blender CLI):

    from scripts.blender.template import anchor_skeleton, make_anchor_empties

    H = 0.32                               # head diameter in meters
    rig = anchor_skeleton(H, 'knight')     # dict {name: (x,y,z)}

    # Standard 6 biped pivots — keys match _build_lib.BIPED_PIVOTS so
    # the existing rig_biped() helper reads them directly.
    biped_pivots = {k: rig[k] for k in
                    ('Body','Head','Arm_L','Arm_R','Leg_L','Leg_R')}

    # Socket Empties — used by aux-part code (beard, helmet, weapon)
    # to set object origins to attachment points instead of geometric
    # centers. This is the single biggest win against floating props.
    sockets = {k: rig[k] for k in rig if k.startswith('socket_')}
    socket_empties = make_anchor_empties(sockets)   # bpy.data.objects

A prop authored to be parented to socket_chin / socket_hand_R /
socket_helmet_top will rotate around the joint correctly when
src/anim/*.js animates the parent group — that's the contract that
keeps beards/plumes/swords from flying off.

Pure-data: importable without bpy. The bpy-touching helper
(make_anchor_empties) is guarded so the dict-only API works in any
environment that wants to introspect proportions.
"""

# ---- archetype heights (in heads tall) ---------------------------------
# Values picked from concept-art-driven research:
#   3.0 heads = adult NPC silhouette (Maud, Hod, Quill, Cricket, Eldra)
#   4.0 heads = player archetype (Knight, Druid, Wanderer, Archer) —
#               feels heroic but stays low-poly chibi
#   2.5 heads = small enemies (bramble-imp, skitterling, marsh rat)
#   4.5 heads = tall / boss (Withering with falcon, Hedgemother)
ARCHETYPE_HEIGHTS = {
    'adult':     3.0,
    'npc':       3.0,
    'knight':    4.0,
    'druid':     4.0,
    'wanderer':  4.0,
    'archer':    4.0,
    'goblin':    2.5,
    'imp':       2.5,
    'tall':      4.5,
    'boss':      4.5,
}

# ---- joint Z position as fraction of total body height -----------------
# Foot plane is at z=0; total = heads * H. These fractions are the
# standard human-figure-proportion canon (Loomis), nudged toward stylised:
#   - hips slightly higher (0.50) for chibi readability
#   - shoulders high (0.85) so arms read as separate from torso
#   - head center near top (0.92) so the head ISN'T floating above
BODY_FRACTIONS = {
    'leg_top_z':       0.48,    # hip joint (top of leg pivot)
    'body_center_z':   0.62,    # torso center — Body empty origin
    'shoulder_z':      0.82,    # shoulder height = Arm empty origin
    'head_center_z':   1.00,    # head center — Head empty origin
    # Tuned 2026-05-02: previous values (0.50/0.66/0.85/0.92) stacked the
    # head into the upper torso — every v2 NPC read as "headless body
    # with eyes on the chest". Bumping head_center_z to 1.00 (head center
    # at the nominal total-height line) AND nudging the rest of the body
    # down by ~0.04 of total gives a clean neck gap. Models now extend
    # slightly past 3 heads but the silhouette reads as a real person.
}

# ---- horizontal offsets in head-units (signed; rig sets symmetric) -----
HORIZONTAL = {
    'shoulder_offset': 0.85,    # half-width of shoulders, in heads
    'leg_offset':      0.30,    # half-width of stance, in heads
}

# ---- socket offsets ----------------------------------------------------
# (parent_joint, (dx, dy, dz)) all in head-units. Offsets are added to
# the parent joint's world position to get the socket position. Authoring
# rule for any prop attached to a socket: set the prop's origin to the
# socket's coords, NOT the prop's geometric center.
#
# - socket_chin: under-jaw, slightly forward (-Y is forward in Blender Y-up
#   conventions when shipped via export_yup; we keep it with -Y forward
#   in build space, which is consistent with all existing scripts).
# - socket_helmet_top: above the crown (+Z) — plumes / horns / antlers
# - socket_hand_R / _L: at end of arm (-Z because the arm pivot is the
#   shoulder; -1.0 head-units down = palm of an arm length 1.0)
# - socket_back: behind the torso (+Y) — quivers, capes
# - socket_belt_front: front of waist — pouches, scabbards
SOCKET_OFFSETS = {
    'socket_chin':       ('Head',  ( 0.00, -0.30, -0.45)),
    'socket_helmet_top': ('Head',  ( 0.00,  0.00,  0.55)),
    'socket_hand_R':     ('Arm_R', ( 0.00,  0.00, -1.00)),
    'socket_hand_L':     ('Arm_L', ( 0.00,  0.00, -1.00)),
    'socket_back':       ('Body',  ( 0.00,  0.30,  0.30)),
    'socket_belt_front': ('Body',  ( 0.00, -0.32,  0.00)),
}

# ---- secondary biped joints (knees + elbows) ---------------------------
# Optional segmented-limb joints. Add them via anchor_skeleton(..., segmented=True)
# to enable knee + elbow bending in the walk cycle. Each child joint is parented
# to its primary joint so when the primary rotates, the secondary follows.
SECONDARY_JOINTS = {
    # name      parent      offset (head-units, in the parent's local frame)
    'Knee_L':  ('Leg_L',  ( 0.00,  0.00, -0.75)),   # half-leg below hip
    'Knee_R':  ('Leg_R',  ( 0.00,  0.00, -0.75)),
    'Elbow_L': ('Arm_L',  ( 0.00,  0.00, -0.55)),   # ~half-arm below shoulder
    'Elbow_R': ('Arm_R',  ( 0.00,  0.00, -0.55)),
}

JOINT_PARENTS = {name: parent for name, (parent, _) in SECONDARY_JOINTS.items()}

# ---- public API --------------------------------------------------------

def total_height(H, archetype='knight'):
    """Total mesh height in meters: heads * H."""
    heads = ARCHETYPE_HEIGHTS.get(archetype, 4.0)
    return heads * H

def anchor_skeleton(H, archetype='knight', segmented=False):
    """Return a {name: (x,y,z)} dict with the 6 biped pivot keys plus
    every socket_* key. All positions are in build-space meters with
    foot plane at z=0.

    Parameters:
        H          head diameter in meters (typical 0.30 - 0.36)
        archetype  key into ARCHETYPE_HEIGHTS
        segmented  when True, also include Knee_L/R + Elbow_L/R secondary
                   joints. Pass these to rig_biped via biped_pivots_only()
                   AND parent them via the JOINT_PARENTS map so the walk
                   cycle can bend at knee + elbow.

    Compatible with `_build_lib.rig_biped(rig_pivots, ...)` — pass the
    biped subset and it will create the rig empties at the right spots.
    """
    total = total_height(H, archetype)
    F = BODY_FRACTIONS

    rig = {
        'Body':  (0, 0, F['body_center_z'] * total),
        'Head':  (0, 0, F['head_center_z'] * total),
        'Arm_L': (-HORIZONTAL['shoulder_offset'] * H, 0, F['shoulder_z'] * total),
        'Arm_R': ( HORIZONTAL['shoulder_offset'] * H, 0, F['shoulder_z'] * total),
        'Leg_L': (-HORIZONTAL['leg_offset'] * H, 0, F['leg_top_z'] * total),
        'Leg_R': ( HORIZONTAL['leg_offset'] * H, 0, F['leg_top_z'] * total),
    }

    if segmented:
        for joint, (parent, off) in SECONDARY_JOINTS.items():
            px, py, pz = rig[parent]
            rig[joint] = (px + off[0] * H, py + off[1] * H, pz + off[2] * H)

    for sock, (parent, off) in SOCKET_OFFSETS.items():
        px, py, pz = rig[parent]
        rig[sock] = (px + off[0] * H, py + off[1] * H, pz + off[2] * H)

    return rig


def biped_pivots_only(rig):
    """Subset of `rig` containing only the 6 keys `_build_lib.rig_biped`
    expects. Lets you hand the result to existing code unchanged."""
    return {k: rig[k] for k in
            ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R')}


def socket_dict(rig):
    """Subset of `rig` containing only socket_* keys."""
    return {k: v for k, v in rig.items() if k.startswith('socket_')}


# ---- bpy helpers (only run inside Blender) -----------------------------

def make_anchor_empties(positions, scene_collection=None, size=0.06,
                        empty_type='SPHERE', name_prefix=''):
    """Materialise each (name, position) as a Blender Empty object.
    Returns {name: bpy.types.Object}. Useful when authoring a build
    script to expose sockets as runtime nodes that the GLB exporter
    will preserve — three.js then sees them as `Object3D` nodes you can
    `getObjectByName('socket_hand_R')`.

    Empties are created at world-space `position`, with no parent. The
    caller typically reparents them to the corresponding rig pivot
    AFTER mesh creation (so their local transform stays at the offset).
    """
    import bpy
    coll = scene_collection or bpy.context.scene.collection
    out = {}
    for name, loc in positions.items():
        e = bpy.data.objects.new(name_prefix + name, None)
        e.empty_display_type = empty_type
        e.empty_display_size = size
        e.location = loc
        coll.objects.link(e)
        out[name_prefix + name] = e
    return out


def set_origin_to_attachment(obj, attach_world_pos):
    """Move `obj`'s origin to `attach_world_pos` without moving the
    geometry. This is the recipe that keeps props from floating: glTF
    preserves the origin as the rotation pivot, so a beard's origin
    must be at the chin contact, a plume's at the helmet socket, etc.

    Equivalent to placing the 3D cursor at attach_world_pos and running
    `bpy.ops.object.origin_set(type='ORIGIN_CURSOR')` with the object
    selected.
    """
    import bpy
    scene = bpy.context.scene
    saved = scene.cursor.location.copy()
    scene.cursor.location = attach_world_pos
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    scene.cursor.location = saved


def materialise_sockets(rig, rig_empties):
    """Given the dict from `anchor_skeleton()` and the empties dict
    returned by `_build_lib.rig_biped()`, create one Empty per
    `socket_*` key, parent each to its corresponding rig empty (so
    per-frame anim rotations carry sockets along), and return
    `{socket_name: bpy.types.Object}`.

    This is the contract every aux-part-bearing model needs: name + parent
    sockets in one place, then `attach_to_socket(...)` does the rest.
    """
    import bpy
    sockets = {}
    for sock_name, (parent_name, _off) in SOCKET_OFFSETS.items():
        if parent_name not in rig_empties:
            continue
        e = bpy.data.objects.new(sock_name, None)
        e.empty_display_type = 'SPHERE'
        e.empty_display_size = 0.04
        e.location = rig[sock_name]
        bpy.context.scene.collection.objects.link(e)
        parent_empty = rig_empties[parent_name]
        wm = e.matrix_world.copy()
        e.parent = parent_empty
        e.matrix_parent_inverse = parent_empty.matrix_world.inverted()
        e.matrix_world = wm
        sockets[sock_name] = e
    return sockets


def attach_to_socket(mesh_obj, socket_empty):
    """Pin `mesh_obj` to `socket_empty`: origin moves to socket world-pos,
    rotation/scale apply, then parent. After this the mesh's GLB rotation
    pivot is the socket, so `src/anim/*.js` rotating the parent rig joint
    carries the prop correctly.

    Idiomatic call:
        attach_to_socket(plume_mesh, sockets['socket_helmet_top'])
    """
    import bpy
    set_origin_to_attachment(mesh_obj, socket_empty.matrix_world.translation.copy())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    wm = mesh_obj.matrix_world.copy()
    mesh_obj.parent = socket_empty
    mesh_obj.matrix_parent_inverse = socket_empty.matrix_world.inverted()
    mesh_obj.matrix_world = wm
