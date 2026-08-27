# Blender authoring files

These `.blend` files are non-runtime source files used to validate model scale,
rig sockets, pivots, and equipment alignment before exporting separate GLBs.

Rigid equipment remains a separate asset. Character rigs expose non-deforming
`Socket_*` bones; each item's origin or `Grip` marker is aligned to the matching
socket during authoring and attached with `BoneAttachment3D` in Godot.

Authoring files live here rather than under `models/` because `wyrd/models` is a
symlink into Godot's resource tree, where `.blend` files trigger an editor import.
