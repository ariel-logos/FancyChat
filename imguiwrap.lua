require('common');
local imgui = require('imgui');

imguiWrap = {};

local PM = AshitaCore:GetPluginManager()
local Addons = PM:Get('addons')
local IntVer = Addons:GetInterfaceVersion()
local IntVerNew = 4.3

imguiWrap.isNewVer = IntVer >= IntVerNew

imguiWrap.ImageButton = function(id, texture_id, size, uv0, uv1, framePadding, bg_col, tint_col)

	if imguiWrap.isNewVer then	
		local result = imgui.ImageButton(id, texture_id, size, uv0, uv1, bg_col, tint_col)
		return result
	else
		return imgui.ImageButton(texture_id, size, uv0, uv1, framePadding, bg_col, tint_col)
	end
end

imguiWrap.SetWindowFontScale = function(scale)

	if imguiWrap.isNewVer then
		local font = imgui.GetFont();
		local size = imgui.GetFontSize();
		imgui.PushFont(font, size * scale)
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
		font.Scale = scale
		imgui.PushFont(font)
		return 1
	end
end

imguiWrap.BeginChild = function(id, size, border, window_flags, child_flags)
	if imguiWrap.isNewVer then
		return imgui.BeginChild(id, size, bit.bor(border and ImGuiChildFlags_Borders or ImGuiChildFlags_None,child_flags or 0), window_flags);
	else
		return imgui.BeginChild(id, size, border, window_flags);
	end

end

imguiWrap.Image = function(tex_id, size, uv0, uv1, tint_col, border_col)
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

imguiWrap.GetKeyDown = function(key)
	if imguiWrap.isNewVer then
		return imgui.GetIO().KeysData[key].Down	
	else
		return imgui.GetIO().KeysDown[key]
	end
end

imguiWrap.TextLinkOpenURL = function(text, link)
	if imguiWrap.isNewVer then
		return imgui.TextLinkOpenURL(text, link)
	else
		
		local linkHoverColor = imgui.GetColorU32({0.4, 0.6, 0.8, 1})
		local normalColor = imgui.GetColorU32({1.0, 1.0, 1.0, 0})
		
		local draw = imgui.GetWindowDrawList()
		local cposX, cposY = imgui.GetCursorScreenPos()
		local sizeX, sizeY = imgui.CalcTextSize(text);
		local rect = {{cposX , cposY + imgui.GetFontSize()},{cposX + sizeX, cposY + imgui.GetFontSize()}}


		imgui.Text(text)
		local isHovered = imgui.IsItemHovered()
		local color = normalColor
		if isHovered and imgui.IsMouseClicked(0) then
			color = linkHoverColor
			ashita.misc.open_url(link);
		elseif isHovered then
			color = linkHoverColor
			imgui.SetCursorScreenPos({cposX, cposY})
			imgui.TextColored({0.4, 0.6, 0.8, 1}, text)
		end
		
		draw:AddLine(rect[1], rect[2], color, 1.0)

		return 
	end
	
end

return imguiWrap;