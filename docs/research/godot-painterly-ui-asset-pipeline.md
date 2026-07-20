# Godot 4.6 painterly UI asset pipeline

Date: 2026-07-17  
Scope: implementable raster-asset techniques for Wayfinder's Godot 4.6 UI. All engine claims below are sourced from official Godot 4.6 documentation.

## Recommendation

Use a hybrid skin, centralized in `wyrd/themes/wayfinder_theme.tres` and semantic theme type variations:

- `StyleBoxTexture` nine-slices for painterly panels, buttons, tabs, slots, tooltips, and scalable state frames.
- Plain `TextureRect` for fixed-aspect illustrations, crests, portraits, ornaments, and noninteractive overlays.
- `AtlasTexture` or `region_rect` for dense icon/component sheets, with padded regions and clipping to prevent bleed.
- Theme-defined `normal`, `hover`, `pressed`, `disabled`, and `focus` styles for interactive controls; keep the existing non-color focus pointer as a second cue.
- Lossless imports with `fix_alpha_border=true`; no mipmaps for UI that remains near authored size, with selective mipmaps only for artwork that is routinely reduced or scaled.

This fits the current project: `wayfinder_theme.tres` is mostly `StyleBoxFlat`, while `wyrd_ui.gd` already proves `StyleBoxTexture` frames/buttons and painterly child textures. The next pass should promote those assets into shared Theme resources/type variations instead of multiplying per-node overrides and runtime factories.

## Where Wayfinder's current fidelity gap comes from

- The new semantic Theme solves hierarchy and contrast, but its panel, button,
  tab, focus, and tooltip surfaces are almost entirely `StyleBoxFlat`; the
  references derive much of their depth from irregular painted edges, paper
  tooth, soft bevels, and restrained corner marks.
- Existing scalable assets are usable but belong to older visual directions:
  `panel_frame_v2_9p.png` is `434×439`, `maple/panel_9p.png` is `160×160`, and
  `maple/button_9p.png` is `132×66`. They are evidence that the pipeline works,
  not automatic matches for Field Journal.
- Several nominally small painted assets are oversized sources—`kit/button.png`
  is `443×344`, `kit/slot.png` is `534×554`, and item/Skill icons are commonly
  `96–256` square—yet all inspected imports have mipmaps disabled. Assets
  routinely rendered at `40–96` px are the first candidates for a controlled
  mipmap/downsample comparison.
- No `AtlasTexture` use was found. Assets are loaded individually or drawn from
  whole textures, and some state styling still constructs local resources in
  scripts. Moving stable plates, overlays, and icons into Theme-owned resources
  is more important than packing an atlas immediately.

The practical target is not a painted screenshot behind the controls. It is a
small reusable kit: one walnut shell nine-slice, one paper surface treatment,
one moss control family with state plates, one outline-only focus overlay, and
a compact ornament/icon sheet. Text and interaction remain native Controls.

## Nine-slice controls and theme boxes

### `NinePatchRect`

`NinePatchRect` divides the source into a 3×3 grid. `patch_margin_left/right/top/bottom` define how much source imagery belongs to each protected border; the four corners remain undistorted while edges and center stretch or tile. Margins may be asymmetric, which is useful for hand-painted frames whose ornaments are not geometrically uniform. `draw_center=false` renders only the border, allowing a separate paper/wash layer beneath it. The horizontal and vertical axis modes independently support stretch, tile, and tile-fit; tile requires seamless art, while tile-fit slightly rescales repeats so complete tiles fit. [Godot 4.6 `NinePatchRect`](https://docs.godotengine.org/en/4.6/classes/class_ninepatchrect.html)

`region_rect` restricts the sampled source rectangle and makes all patch settings relative to that region. Therefore one atlas can hold several nine-slices without first creating individual textures. An empty region uses the whole source. [Godot 4.6 `NinePatchRect.region_rect`](https://docs.godotengine.org/en/4.6/classes/class_ninepatchrect.html#class-ninepatchrect-property-region-rect)

Use `NinePatchRect` when the frame is a real layout node or needs an independently layered center. Its default mouse filter is ignore, so a decorative nine-patch does not need to block controls behind it. [Godot 4.6 `NinePatchRect`](https://docs.godotengine.org/en/4.6/classes/class_ninepatchrect.html)

### `StyleBoxTexture`

`StyleBoxTexture` is the theme-native equivalent. `texture_margin_*` defines the 3×3 border and also becomes the fallback content margin when the inherited `StyleBox.content_margin_*` is negative. Set explicit content margins when the painted frame has visual ornament extending farther than the safe text inset. `draw_center`, independent horizontal/vertical axis stretch modes, tint via `modulate_color`, and draw expansion via `expand_margin_*` are built in. [Godot 4.6 `StyleBoxTexture`](https://docs.godotengine.org/en/4.6/classes/class_styleboxtexture.html)

Its `region_rect` is explicitly equivalent to wrapping the texture in an `AtlasTexture` with that region; an empty rectangle uses the complete texture. [Godot 4.6 `StyleBoxTexture.region_rect`](https://docs.godotengine.org/en/4.6/classes/class_styleboxtexture.html#class-styleboxtexture-property-region-rect)

Prefer `StyleBoxTexture` for reusable control states because it integrates with Theme inheritance and content sizing. Prefer `NinePatchRect` for composed visuals such as “paper fill + frame-only border + crest” where each layer needs separate modulation or animation.

Wayfinder-specific checks:

- `panel_frame_v2_9p.png` passes the existing checker with margins `34/37/32/40`.
- `maple/panel_9p.png` passes at `28` on all sides.
- `maple/button_9p.png` is currently used at `30/20/30/22`, but fails the repository symmetry heuristic (22% spread). Treat it as a deliberate asymmetric asset only after visual testing across minimum, typical, and maximum widths; otherwise regenerate it with larger clean stretch corridors.
- Never let a target control become smaller than the sum of its opposing protected margins plus useful center pixels.

## Fixed artwork with `TextureRect`

`TextureRect.expand_mode` determines the control's minimum-size contribution, while `stretch_mode` determines how the image is drawn inside its actual bounds. `EXPAND_KEEP_SIZE` prevents shrinking below the texture's native size; `EXPAND_IGNORE_SIZE` lets Containers shrink it. The fit-width/height variants exist, but Godot marks their behavior in some Containers experimental. [Godot 4.6 `TextureRect`](https://docs.godotengine.org/en/4.6/classes/class_texturerect.html)

For Wayfinder:

- Icons/portraits/crests: `EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_CENTERED`.
- Full-bleed painted page or banner: `EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_COVERED`, accepting clipping on the long axis.
- Repeating paper grain: `STRETCH_TILE`, using a genuinely seamless and modest texture.
- Never use `STRETCH_SCALE` on linework or round ornaments unless distortion is intentional.

Decorative child `TextureRect`s placed above a `Button` should use `MOUSE_FILTER_IGNORE`; Godot's `Control` documentation calls this out for icons over buttons. [Godot 4.6 `Control`](https://docs.godotengine.org/en/4.6/classes/class_control.html)

## Filtering, mipmaps, and imports

`CanvasItem.texture_filter` is per use. Its default `TEXTURE_FILTER_PARENT_NODE` inherits from the closest CanvasItem parent, so one semantic UI root can establish linear filtering for all painterly descendants while exceptional pixel-art assets override locally. Nearest is crisp/pixelated; linear blends the nearest four pixels; linear-with-mipmaps additionally blends mip levels and is intended for non-pixel art viewed at reduced scale. Anisotropic modes are rarely useful in 2D. [Godot 4.6 `CanvasItem.TextureFilter`](https://docs.godotengine.org/en/4.6/classes/class_canvasitem.html#enum-canvasitem-texturefilter)

Filtering does not manufacture mip levels. Image import must enable `Mipmaps > Generate` before a mipmap filter can sample them. Mipmaps add roughly 33% memory, can remove graininess during substantial reduction, and may reduce sampling bandwidth; Godot recommends them in 2D only when the project visibly benefits. `Process > Fix Alpha Border` reduces dark outlines around filtered transparent edges and is enabled by default. [Godot 4.6 image imports, “Mipmaps” and “Fix Alpha Border”](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_images.html)

Recommended presets:

| Asset family | Filter | Mipmaps | Compression |
|---|---|---:|---|
| Nine-slice frames and buttons near authored scale | Linear | Off | Lossless |
| Icons shown across materially different sizes | Linear with mipmaps | On, after visual test | Lossless |
| Large opaque/photographic painted backdrops | Linear; mipmaps if reduced | Case-by-case | Lossy may be acceptable |
| Pixel art, if introduced | Nearest | Usually off | Lossless |

Godot describes Lossless as stored lossless WebP/PNG and Lossy as useful for large 2D assets with artifacts and smaller disk size; Lossy does not reduce video-memory use relative to Lossless/VRAM Uncompressed. [Godot 4.6 image import compression modes](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_images.html#compress-mode)

The current inspected Wayfinder `.import` files consistently use Lossless, `process/fix_alpha_border=true`, and mipmaps off. That is a sound baseline for crisp UI. Keep alpha-border fixing for filtered transparent ornaments, then selectively enable mipmaps only where screenshot tests show shimmer/grain during reduction. Do not globally enable mipmaps for every UI texture.

## Atlases and component sheets

`AtlasTexture` references an `atlas` texture and a `region`. `filter_clip=true` clips outside the region to avoid neighboring-pixel bleed; `margin` supports small placement/size adjustments. Godot warns that `AtlasTexture` does not tile properly in `TextureRect` or `Sprite2D`; enlarge/alter the region instead of using ordinary tiling. [Godot 4.6 `AtlasTexture`](https://docs.godotengine.org/en/4.6/classes/class_atlastexture.html)

Implement component sheets as named `AtlasTexture` subresources (icons, crests, dividers, corner flourishes) or use `region_rect` directly on nine-slices. Author at least a small transparent/edge-extruded gutter around each filtered cell, enable `filter_clip`, and keep atlas regions stable so UI scenes reference semantic resources rather than pixel coordinates scattered through scripts.

Atlasing can reduce texture changes, but do not assume it is a win without profiling. Godot's optimization guidance says to identify and measure actual bottlenecks, and notes that large transparent quads still spend fill work even where pixels are transparent. [Godot 4.6 general optimization](https://docs.godotengine.org/en/4.6/tutorials/performance/general_optimization.html) [Godot 4.6 2D mesh transparency cost](https://docs.godotengine.org/en/4.6/tutorials/2d/2d_meshes.html#optimizing-pixels-drawn)

Practical implication: atlas small frequently co-visible components; keep 1456×816 concept/reference screens out of runtime atlases, and crop large transparent ornaments tightly.

## Buttons, icons, and visual states

A standard `Button` exposes one `icon` property (with a Theme fallback icon), `expand_icon`, and Theme `icon_max_width`. Its Theme provides state-specific icon modulation colors—normal, hover, pressed, hover-pressed, focus, and disabled—and state-specific styleboxes including normal, hover, pressed, hover-pressed, disabled, focus, plus RTL mirrored variants. If state boxes have different margins, `align_to_largest_stylebox=true` bases sizing/alignment on the largest state and avoids state-driven layout shifts. [Godot 4.6 `Button`](https://docs.godotengine.org/en/4.6/classes/class_button.html)

Therefore:

- Use one painted glyph plus state color modulation when the silhouette is unchanged.
- Put painterly button plates in state `StyleBoxTexture`s, not in the icon.
- Use the focus StyleBox as an outline-only overlay; Godot draws a control's `focus` StyleBox over its normal/hover/pressed StyleBox, specifically to make it reusable. [Godot 4.6 `StyleBox`](https://docs.godotengine.org/en/4.6/classes/class_stylebox.html)
- If each state truly needs different raster artwork, use `TextureButton`, which has separate normal, pressed, hover, disabled, and focused textures, or explicitly swap a child texture. [Godot 4.6 `TextureButton`](https://docs.godotengine.org/en/4.6/classes/class_texturebutton.html)

For resizable text buttons, `Button` + `StyleBoxTexture` is preferable to a stretched round image. Reserve `TextureButton` for fixed-size icon controls such as close, paging, or radial-slot controls.

Define semantic Theme variations such as `FieldButton`, `QuietButton`, `DangerButton`, `InventorySlot`, `JournalPanel`, and `FocusRing`, then assign `theme_type_variation`. A variation extends a base Control type, overrides only selected Theme items, inherits the rest, and may itself be extended. This keeps state behavior and content margins consistent while allowing panels to remain ordinary semantic Controls. [Godot 4.6 Theme type variations](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_theme_type_variations.html)

## Hover and focus overlays

Two scalable patterns are supported:

1. Theme overlays: give `hover` a complete nine-slice state and `focus` an outline-only `StyleBoxTexture`/`StyleBoxFlat` with `draw_center=false` and modest expansion margins. Because focus is drawn over the active base state, it need not duplicate every button plate. [Godot 4.6 `StyleBox`](https://docs.godotengine.org/en/4.6/classes/class_stylebox.html)
2. Node overlays: add a mouse-ignoring `NinePatchRect` or `TextureRect` child for glows, corner leaves, or a pointer, and show/animate it on hover/focus. This is appropriate when an effect extends beyond the control, has independent animation, or must provide a non-color shape cue.

Do not communicate hover, focus, selection, or disabled state by color alone. Wayfinder's existing `UiFocusPointer` plus a 3 px focus ring is the right structure: focus remains visible over painterly state plates and includes a distinct shape.

Godot 4.6 only shows focus gained by keyboard/gamepad (or `grab_focus()`) by default, and provides explicit directional and Tab focus neighbors. It also exposes `accessibility_name`, `accessibility_description`, labeling/describing relationships, flow relationships, and live-region settings on `Control`. [Godot 4.6 `Control`](https://docs.godotengine.org/en/4.6/classes/class_control.html)

Acceptance requirements:

- Every action remains a real focusable `Control`, not a custom-drawn hit region.
- Focus order and directional neighbors are deterministic at 16:9, ultrawide, and minimum supported resolution.
- Icon-only controls have tooltips plus meaningful accessibility names; decorative overlays ignore input and accessibility flow.
- Hover, pressed, selected, disabled, and focused states remain distinguishable in grayscale and under the high-contrast palette.
- Focus art must not be clipped by parent Containers; budget expansion margins or place the overlay above the clipping ancestor.

## Asset authoring contract

For each scalable painterly component, deliver:

- PNG/WebP with transparency only where required; tightly cropped for ornaments.
- Authored reference size and minimum supported rendered size.
- Four nine-slice margins and a marked safe-content rectangle.
- Whether center draws, stretches, tiles, or is supplied by a separate layer.
- State intent: normal/hover/pressed/disabled/focus, noting whether states are separate plates or tint variants.
- Atlas region and gutter/extrusion size if packed.
- A contact sheet showing minimum, typical, and maximum dimensions over both paper and dark surfaces.

Run `wyrd/tools/check_ninepatch.py` on every frame-like asset, but treat the numerical check as a defect detector, not a substitute for in-engine review. Validate at actual target resolutions with linear filtering, and with/without mipmaps wherever an asset is substantially reduced.

## Suggested migration sequence

1. Create painterly Theme subresources/type variations for `JournalPanel`, `FieldButton`, `QuietButton`, `InventorySlot`, and the shared focus overlay.
2. Convert one representative dense screen (inventory) and one modal (dialogue/vendor) without changing behavior.
3. Capture all UI surfaces at minimum, 1080p, ultrawide, keyboard focus, gamepad focus, disabled, and long-text states.
4. Only after visual and navigation approval, migrate the remaining panels away from per-node style overrides.
5. Profile before introducing a broad atlas; use atlases first for stable, frequently co-visible small components.
