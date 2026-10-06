--[[
Copyright 2023 Thorny

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--

local d3d = require('d3d8');
local ffi = require('ffi');
local default_settings = {
    width = 40,
    height = 150,
    corner_rounding = 0,
    outline_color = 0xFF000000,
    outline_width = 0,
    fill_color = 0x80000000,
    gradient_style = 0,
    gradient_color = 0x00000000,

    -- Arbitrary image support.  When image_path points at a loadable
    -- file (PNG/JPG/BMP/TGA/DDS - anything D3DX can decode), the
    -- object draws that image INSTEAD of the GDI+ generated rect;
    -- everything else (position, visibility, z-order) behaves the
    -- same.  Empty string = no image (must be '' and not nil: new()
    -- iterates default_settings, so a nil default would make the key
    -- invisible and silently drop a caller-supplied value).
    --   image_fit  'stretch' - scale the image to width x height,
    --                          distorting it if the aspect ratios differ
    --              'cover'   - keep the image's proportions, scale it to
    --                          FILL width x height and centre-crop the
    --                          overflow (done in texture space via the
    --                          source RECT, so no pixels are wasted and
    --                          nothing is squashed)
    --              'topband' - take a band off the TOP-LEFT of the
    --                          texture exactly as tall as the plate in
    --                          PIXELS (no vertical scaling, rows map
    --                          1:1) and stretch only the width to fit
    --              'native'  - draw at the image's own pixel size
    --   image_tint ARGB modulation applied at draw time.  0xFFFFFFFF
    --              leaves the image untouched; lowering the alpha
    --              fades it, and the RGB channels multiply, so a
    --              white-ish source can be recoloured for free.
    image_path = '',
    image_fit = 'stretch',
    image_tint = 0xFFFFFFFF,

    position_x = 0,
    position_y = 0,
    visible = true,
    z_order = 0,
};

-- Convert a 32-bit colour value that's stored as a signed Lua number
-- (i.e. high alpha byte makes the Lua double negative) to its positive
-- uint32 equivalent.  Works around a LuaJIT FFI JIT-trace bug where the
-- first negative-signed input to a trace that previously only saw
-- positive ints can be silently converted to 0 when assigned to a
-- uint32_t field.  The Lua-double range comfortably holds all of
-- [0, 2^32-1], so going through positive numbers avoids the bug.
-- Detection point: during FancyChat's auto-hide fade-in, the alpha
-- modulation walks from 0 upward.  All alphas below 0x80 land in
-- positive Lua-number territory and JIT the trace for "non-negative
-- int -> uint32".  The FIRST cross into 0x80+ (negative Lua number)
-- mis-converts to 0, blanking the plate texture for one frame and
-- producing the "plate vanishes after fade-in completes" symptom.
local function uint32_of(n)
    if n < 0 then return n + 4294967296 end
    return n
end

-- ===================================================================
-- Image loading for image-backed rect objects.
--
-- Textures are cached per absolute path and shared by every object
-- that references the same file, so N objects using one image cost
-- one texture.  A failed load is cached as `false` so a missing or
-- corrupt file isn't retried on every single frame.
--
-- Everything here comes from the d3d8 library this file already
-- requires - no new FFI declarations and no DLL changes.
-- ===================================================================
local image_cache = {};

-- Bumped by clear_image_cache().  Per-object memos in get_image()
-- carry the generation they were resolved under, so a cache clear
-- (which RELEASES the textures) can never leave an object drawing a
-- freed texture from a stale memo.
local image_generation = 0;

-- Cache key: Windows paths are case-insensitive and accept either
-- slash, so normalise before keying or the same file reached by two
-- spellings would decode and hold two separate textures.
local function cache_key(path)
    return path:lower():gsub('\\', '/');
end

local function load_image(path)
    local key = cache_key(path);
    local cached = image_cache[key];
    if (cached ~= nil) then
        return cached;
    end

    -- Let D3DX pick the surface size (D3DX_DEFAULT).  Supplying the
    -- file's own dimensions instead would be rejected outright on a
    -- device that requires power-of-two textures, and D3DX is free to
    -- adjust caller-supplied sizes anyway (POT rounding, clamping to
    -- the device's maximum), so the created surface is read back
    -- below rather than assumed.  Mirrors utils.LoadTextureFromFile,
    -- the proven loader already used by this addon for zone maps.
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local hr = ffi.C.D3DXCreateTextureFromFileExA(
        d3d.get_device(), path,
        ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 1, 0,
        ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED,
        ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT,
        0, nil, nil, texture_ptr);
    if (hr ~= ffi.C.S_OK) or (texture_ptr[0] == nil) then
        image_cache[key] = false;
        return false;
    end

    local texture = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));

    -- Authoritative surface size.  The source RECT and the draw-time
    -- scale must both be based on what D3DX ACTUALLY created - using
    -- the file's dimensions would push the sprite's UVs outside the
    -- texture (smeared / cropped output) whenever D3DX adjusted it.
    local desc_hr, desc = texture:GetLevelDesc(0);
    local img_w, img_h;
    if (desc_hr == ffi.C.S_OK) and (desc ~= nil) then
        img_w = tonumber(desc.Width);
        img_h = tonumber(desc.Height);
    end
    if (img_w == nil) or (img_h == nil) or (img_w <= 0) or (img_h <= 0) then
        image_cache[key] = false;
        return false;
    end

    local entry = {
        texture = texture,
        rect    = ffi.new('RECT', { 0, 0, img_w, img_h }),
        width   = img_w,
        height  = img_h,
    };
    image_cache[key] = entry;
    return entry;
end

local function CreateRectData(settings)
    local data = ffi.new('GdiRectData_t');
    data.Width         = settings.width;
    data.Height        = settings.height;
    data.Diameter      = settings.corner_rounding;
    data.OutlineColor  = uint32_of(settings.outline_color);
    data.OutlineWidth  = settings.outline_width;
    data.FillColor     = uint32_of(settings.fill_color);
    data.GradientStyle = settings.gradient_style;
    data.GradientColor = uint32_of(settings.gradient_color);
    return data;
end

local object = {};

function object:get_texture()
    if (self.is_dirty == true) then
        self.is_dirty = false;
        self.texture = nil;
        self.rect = nil;
        local tx = self.renderer.CreateRectTexture(self.interface, CreateRectData(self.settings));
        if (tx.Texture == nil) or (tx.Width == 0) or (tx.Height == 0) then
            return;
        else
            self.texture = d3d.gc_safe_release(tx.Texture);
            self.rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
        end
    end

    return self.texture, self.rect;
end

function object:new(args, settings)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.is_dirty = true;
    o.interface = args.Interface;
    o.renderer = args.Renderer;
    o.sort = args.Sort;
    o.settings = {};
    for key,value in pairs(default_settings) do
        if (type(settings) == 'table') and (settings[key] ~= nil) then
            o.settings[key] = settings[key];
        else
            o.settings[key] = value;
        end
    end
    return o;
end

local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local d3dwhite = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);
-- Resolve this object's image, or nil when it has none / the file
-- could not be loaded (in which case the caller falls back to the
-- normal GDI+ generated rect rather than drawing nothing).
function object:get_image()
    local path = self.settings.image_path;
    -- Type-check rather than trust: this runs inside the sprite batch
    -- (see render below), and handing a non-string to the loader's C
    -- call would raise from a place where a throw is unrecoverable.
    if (type(path) ~= 'string') or (path == '') then
        return nil;
    end
    -- Per-object memo: this runs every frame from inside gdifonts'
    -- render loop, and load_image's key normalisation uses
    -- string.lower/gsub, neither of which LuaJIT can compile - going
    -- through it each frame would abort the trace covering the whole
    -- loop (every font and rect object, not just image-backed ones).
    -- Resolve only when the path actually changes.
    if (self.img_memo_path == path) and (self.img_memo_gen == image_generation) then
        return self.img_memo or nil;
    end
    -- pcall belt-and-braces: a decode failure must degrade to the
    -- GDI+ rect, never escape into the render batch.
    local ok, entry = pcall(load_image, path);
    if (not ok) or (entry == false) then
        self.img_memo_path = path;
        self.img_memo_gen = image_generation;
        self.img_memo = false;
        return nil;
    end
    self.img_memo_path = path;
    self.img_memo_gen = image_generation;
    self.img_memo = entry;
    return entry;
end

function object:render(sprite)
    if (self.settings.visible ~= true) then
        return;
    end

    -- Image-backed rect: draw the cached texture instead of the GDI+
    -- one.  vec_scale and the colour argument are module-level values
    -- shared by every rect object's draw, so both are set explicitly
    -- here AND restored before returning - otherwise the next object
    -- in the render list would inherit this one's scale/tint.
    local img = self:get_image();
    if (img ~= nil) then
        -- Everything that could fail is computed BEFORE the shared
        -- vec_scale is touched, so no error can leave it stale (an
        -- error escaping here would also abort include.lua's
        -- sprite:Begin()/End() batch and kill all gdifonts drawing).
        local scale_x, scale_y = 1.0, 1.0;
        local src_rect = img.rect;
        local fit = self.settings.image_fit;
        -- The plate size is TRUNCATED to whole pixels here, once, for
        -- every fit mode - because that is what the plain-colour path
        -- gets.  A rect's width/height can be fractional (fancychat's
        -- plate is chars x font_height x 0.59, e.g. 1019.52 x 292.80),
        -- and the DLL receives it as `int width = data.Width`, so the
        -- GDI+ texture is 1019 x 292.  Scaling an image to the
        -- fractional size instead ends the quad 0.52px into the next
        -- column and D3D fills a partial extra pixel: the image-backed
        -- plate came out one pixel wider AND taller than the colour
        -- plate it replaces.  Same convention as the DLL: floor.
        local plate_w = tonumber(self.settings.width);
        local plate_h = tonumber(self.settings.height);
        if (plate_w ~= nil) then plate_w = math.floor(plate_w); end
        if (plate_h ~= nil) then plate_h = math.floor(plate_h); end
        if (fit == 'cover') then
            -- Pick the window of the TEXTURE that already has the
            -- plate's aspect ratio and draw only that, so one uniform
            -- scale covers the plate: the artwork keeps its proportions
            -- and the excess is trimmed evenly off the two long edges
            -- instead of being squashed into frame.
            local target_w, target_h = plate_w, plate_h;
            if (target_w ~= nil) and (target_h ~= nil)
                and (target_w > 0) and (target_h > 0)
                and (img.width > 0) and (img.height > 0) then
                local src_w, src_h = img.width, img.height;
                -- Cross-multiplied so the comparison stays in integers.
                if ((img.width * target_h) > (img.height * target_w)) then
                    src_w = math.floor((img.height * target_w / target_h) + 0.5);
                    if (src_w < 1) then src_w = 1; end
                else
                    src_h = math.floor((img.width * target_h / target_w) + 0.5);
                    if (src_h < 1) then src_h = 1; end
                end
                local off_x = math.floor((img.width  - src_w) / 2);
                local off_y = math.floor((img.height - src_h) / 2);
                -- Own RECT per object, rebuilt only when the crop
                -- actually changes: this runs every frame inside the
                -- sprite batch, and img.rect is shared by every object
                -- using the same file, so it must not be mutated.
                if (self.img_crop_w ~= src_w) or (self.img_crop_h ~= src_h)
                    or (self.img_crop_x ~= off_x) or (self.img_crop_y ~= off_y) then
                    if (self.img_crop_rect == nil) then
                        self.img_crop_rect = ffi.new('RECT');
                    end
                    self.img_crop_rect.left   = off_x;
                    self.img_crop_rect.top    = off_y;
                    self.img_crop_rect.right  = off_x + src_w;
                    self.img_crop_rect.bottom = off_y + src_h;
                    self.img_crop_w, self.img_crop_h = src_w, src_h;
                    self.img_crop_x, self.img_crop_y = off_x, off_y;
                end
                src_rect = self.img_crop_rect;
                scale_x = target_w / src_w;
                scale_y = target_h / src_h;
            end
        elseif (fit == 'topband') then
            -- Draw the top `height` rows of the texture and stretch only
            -- the width, so a tall source keeps its rows 1:1 and is never
            -- resampled downward.
            -- A texture SHORTER than the plate has no rows left to give,
            -- so it is stretched vertically to cover the plate rather
            -- than leaving a bare strip along the bottom.
            local target_w, target_h = plate_w, plate_h;
            if (target_w ~= nil) and (target_h ~= nil)
                and (target_w > 0) and (target_h > 0)
                and (img.width > 0) and (img.height > 0) then
                local src_h = math.floor(target_h + 0.5);
                if (src_h > img.height) then src_h = img.height; end
                if (src_h < 1) then src_h = 1; end
                local src_w = img.width;
                if (self.img_crop_w ~= src_w) or (self.img_crop_h ~= src_h)
                    or (self.img_crop_x ~= 0) or (self.img_crop_y ~= 0) then
                    if (self.img_crop_rect == nil) then
                        self.img_crop_rect = ffi.new('RECT');
                    end
                    self.img_crop_rect.left   = 0;
                    self.img_crop_rect.top    = 0;
                    self.img_crop_rect.right  = src_w;
                    self.img_crop_rect.bottom = src_h;
                    self.img_crop_w, self.img_crop_h = src_w, src_h;
                    self.img_crop_x, self.img_crop_y = 0, 0;
                end
                src_rect = self.img_crop_rect;
                scale_x = target_w / src_w;
                -- Only a source too short to fill the plate is scaled
                -- vertically; anything tall enough stays at exactly 1.0
                -- so its rows still land on screen unresampled.
                if (src_h < target_h) then
                    scale_y = target_h / src_h;
                else
                    scale_y = 1.0;
                end
            end
        elseif (fit ~= 'native') then
            local target_w, target_h = plate_w, plate_h;
            if (target_w ~= nil) and (target_w > 0) and (img.width > 0) then
                scale_x = target_w / img.width;
            end
            if (target_h ~= nil) and (target_h > 0) and (img.height > 0) then
                scale_y = target_h / img.height;
            end
        end
        local tint = tonumber(self.settings.image_tint);
        if (tint == nil) then
            tint = 0xFFFFFFFF;
        end
        tint = uint32_of(tint);

        vec_position.x = self.settings.position_x or 0;
        vec_position.y = self.settings.position_y or 0;
        vec_scale.x = scale_x;
        vec_scale.y = scale_y;
        sprite:Draw(img.texture, src_rect, vec_scale, nil, 0.0, vec_position, tint);
        -- Restore the shared scale for every following object.
        vec_scale.x = 1.0;
        vec_scale.y = 1.0;
        return;
    end

    local texture, rect = self:get_texture();
    if (texture ~= nil) then
        vec_position.x = self.settings.position_x;
        vec_position.y = self.settings.position_y;
        sprite:Draw(texture, rect, vec_scale, nil, 0.0, vec_position, d3dwhite);
    end
end

function object:set_width(width)
    if (width ~= self.settings.width) then
        self.is_dirty = true;
    end

    self.settings.width = width;
end

function object:set_height(height)
    if (height ~= self.settings.height) then
        self.is_dirty = true;
    end

    self.settings.height = height;
end

function object:set_corner_rounding(rounding)
    if (rounding ~= self.settings.corner_rounding) then
        self.is_dirty = true;
    end

    self.settings.corner_rounding = rounding;
end

function object:set_fill_color(color)
    if (color ~= self.settings.fill_color) then
        self.is_dirty = true;
    end

    self.settings.fill_color = color;
end

function object:set_gradient_color(color)
    if (color ~= self.settings.gradient_color) then
        self.is_dirty = true;
    end

    self.settings.gradient_color = color;
end

function object:set_gradient_style(style)
    if (style ~= self.settings.gradient_style) then
        self.is_dirty = true;
    end

    self.settings.gradient_style = style;
end

function object:set_outline_color(color)
    if (color ~= self.settings.outline_color) then
        self.is_dirty = true;
    end

    self.settings.outline_color = color;
end

function object:set_outline_width(width)
    if (width ~= self.settings.outline_width) then
        self.is_dirty = true;
    end

    self.settings.outline_width = width;
end

-- Point this rect at an image file (absolute path recommended).  Pass
-- '' or nil to go back to the GDI+ generated rect.  No dirty flag is
-- needed: images are resolved through the shared cache at draw time.
function object:set_image_path(path)
    if (type(path) ~= 'string') then
        path = '';
    end
    self.settings.image_path = path;
end

-- 'stretch' (fill width x height) or 'native' (image's own size).
-- Anything else is treated as 'stretch'.
function object:set_image_fit(fit)
    if (fit == 'native') or (fit == 'cover') or (fit == 'topband') then
        self.settings.image_fit = fit;
    else
        self.settings.image_fit = 'stretch';
    end
end

-- ARGB modulation applied to the image at draw time.  Normalised here
-- (and again at draw time) so a bad value can never raise from inside
-- the sprite batch.
function object:set_image_tint(color)
    self.settings.image_tint = tonumber(color) or 0xFFFFFFFF;
end

-- Drop cached image textures so edited/replaced files are picked up.
-- Static: call as rectobject.clear_image_cache() or via the library's
-- gdi:clear_image_cache().  Textures are released explicitly rather
-- than waiting on the gc_safe_release finalizer, so a reload loop
-- (theme editing) can't stack several full-size copies in VRAM; the
-- finalizer is detached first so the release happens exactly once.
function object.clear_image_cache()
    local old = image_cache;
    image_cache = {};
    -- Invalidate every per-object memo before the textures below are
    -- released, so no object can draw a freed texture.
    image_generation = image_generation + 1;
    for _, entry in pairs(old) do
        if (type(entry) == 'table') and (entry.texture ~= nil) then
            pcall(function()
                ffi.gc(entry.texture, nil);
                entry.texture:Release();
            end);
        end
    end
end

function object:set_position_x(x)
    self.settings.position_x = x;
end

function object:set_position_y(y)
    self.settings.position_y = y;
end

function object:set_visible(visible)
    self.settings.visible = visible;
end

function object:set_z_order(z_order)
    if (type(z_order) == 'number') and (z_order ~= self.settings.z_order) then
        self.settings.z_order = z_order;
        self.sort();
    end
end

return object;