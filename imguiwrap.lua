require('common');
local imgui = require('imgui');

imguiWrap = {};

local PM = AshitaCore:GetPluginManager()
local Addons = PM:Get('addons')
local IntVer = Addons:GetInterfaceVersion()
local IntVerNew = 4.3

imguiWrap.isNewVer = IntVer >= IntVerNew

imguiWrap.ImageButton = function(id, texture_id, size, uv0, uv1, framePadding, bg_col, tint_col)
--ImageButton(const char* str_id, ImTextureRef tex_ref, const ImVec2& image_size, const ImVec2& uv0 = ImVec2(0, 0), const ImVec2& uv1 = ImVec2(1, 1), const ImVec4& bg_col = ImVec4(0, 0, 0, 0), const ImVec4& tint_col = ImVec4(1, 1, 1, 1)) = 0;
--ImageButton(ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0 = ImVec2(0, 0), const ImVec2& uv1 = ImVec2(1, 1), int frame_padding = -1, const ImVec4& bg_col = ImVec4(0, 0, 0, 0), const ImVec4& tint_col = ImVec4(1, 1, 1, 1)) = 0;

	if imguiWrap.isNewVer then
		--imgui.PushStyleVar(ImGuiStyleVar_FramePadding, {-1,-1})
		local result = imgui.ImageButton(id, texture_id, size, uv0, uv1, bg_col, tint_col)
		--imgui.PopStyleVar(1)
		return result
	else
		return imgui.ImageButton(texture_id, size, uv0, uv1, framePadding, bg_col, tint_col)
	end
end

imguiWrap.SetWindowFontScale = function(scale)

	if imguiWrap.isNewVer then
		local font = imgui.GetFont();
		local size = imgui.GetFontSize();
		--imgui.PushStyleVar(ImGuiStyleVar_FramePadding, {-1,-1})
		--imgui.SetWindowFontScale(allSettings.fontSettings.font_height/25)
		imgui.PushFont(font, size * scale)
		--imgui.PopStyleVar(1)
		return true
	else
		if imgui.SetWindowFontScale then
			imgui.SetWindowFontScale(scale)
		end
		return false
	end
end

imguiWrap.PushFont = function(font, scale)

	if imguiWrap.isNewVer then
		imgui.PushFont(font, font.LegacySize * scale)
		return 1
	else
		--local old_scale = font.Scale
		font.Scale = scale
		imgui.PushFont(font)
		return 1
	end
end

imguiWrap.BeginChild = function(id, size, border, window_flags, child_flags)
--BeginChild(const char* str_id, const ImVec2& size = ImVec2(0, 0), ImGuiChildFlags child_flags = 0, ImGuiWindowFlags window_flags = 0) = 0;
--BeginChild(const char* str_id, const ImVec2& size = ImVec2(0, 0), bool border = false, ImGuiWindowFlags flags = 0) = 0;
	if imguiWrap.isNewVer then
		return imgui.BeginChild(id, size, bit.bor(border and ImGuiChildFlags_Borders or ImGuiChildFlags_None,child_flags or 0), window_flags);
	else
		return imgui.BeginChild(id, size, border, window_flags);
	end

end

imguiWrap.Image = function(tex_id, size, uv0, uv1, tint_col, border_col)
--Image(ImTextureRef tex_ref, const ImVec2& image_size, const ImVec2& uv0 = ImVec2(0, 0), const ImVec2& uv1 = ImVec2(1,1))                                                                                                                   = 0;
--ImageWithBg(ImTextureRef tex_ref, const ImVec2& image_size, const ImVec2& uv0 = ImVec2(0, 0), const ImVec2& uv1 = ImVec2(1, 1), const ImVec4& bg_col = ImVec4(0, 0, 0, 0), const ImVec4& tint_col = ImVec4(1, 1, 1, 1))                     = 0;
--Image(ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0 = ImVec2(0, 0), const ImVec2& uv1 = ImVec2(1, 1), const ImVec4& tint_col = ImVec4(1, 1, 1, 1), const ImVec4& border_col = ImVec4(0, 0, 0, 0))                           = 0;

	if imguiWrap.isNewVer then
		if tint_col then
			imgui.ImageWithBg(tex_id, size, uv0, uv1, border_color or {0,0,0,0}, tint_col)
		else
			imgui.Image(tex_id, size, uv0, uv1)
		end
		
	else
		imgui.Image(tex_id, size, uv0, uv1, tint_col, border_col)
	end

end

imguiWrap.IsWindowHovered = function(flags)
	if imguiWrap.isNewVer then
		if flags == ImGuiHoveredFlags_RectOnly then
			local pos_x, pos_y = imgui.GetWindowPos()
			local size_x, size_y = imgui.GetWindowSize()
			local mouse_x, mouse_y = imgui.GetMousePos();
			if mouse_x > pos_x and mouse_x < pos_x + size_x and
			mouse_y > pos_y and mouse_y < pos_y + size_y
			then
				return true
			else
				return false
			end
		else
			return imgui.IsWindowHovered(flags)
		end
	else
		return imgui.IsWindowHovered(flags)
	end
end

return imguiWrap;