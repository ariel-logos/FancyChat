require('common');
local imgui = require('imgui');
local imguiWrap = require('imguiWrap')

help = {
		opened = T{false},
		overviewSize = 1,
		searchBuff = T{''},
		longestword = '',
		collapseAll = false,
		foundParent = T{},
		foundAnything = false,
		};

--help.overviewText = 'This is a built-in manul for this addon.\nHere you can find most of the info you need to take advantage of all the addon features.\nThe manual is split in different sections to help you find what you are looking for.';
help.overviewText = {
						{
							'Intro',
							'This is a built-in manual for this addon.',
							'Here you can find most of the info you need to take advantage of all the addon features.',
							'The manual is split in different sections to help you find what you are looking for.'
						}
					};
help.loremText=		{
						{
							'Disclaimer',
							'This project is the result of a hobby, a hobby in which I ended up throwing dozens of hundred of hours. While it was my goal to get close as perfection as I could, in the end, I had to decide a development state that was good enough. If you are reading this, this is such state.',
							'While I\'ll do my best to maintain this addon to fix bugs, here\'s a list of the things you should not expect:',
							'- Compatibility with other addons.\nWhat works works.\nI have no intention on reviewing over and over my text handling function to make every addon\'s type of message compatible.',
							'- Compatibility with handheld devices and unusual screen sizes and ratios.\nI tried my best to take into account these factors and adjusted my code to \'predict\' its behaviour on screen\\window sizes too different from the usual 16:9 ratio and 1080p/1440p/2160p sizes. Sadly, I don\'t have a bank account big enough to invest in all possible device for testing nor the time to invest into making this add-on omni-compatible. Sorry if it doesn\'t work on your device. :(',
							'- All the features marked as \'beta\' or \'experimental\' have no guarantees of ever being fixed, completed and/or improved. This is not due to my lack of good will but because the reason why they are marked with such labels is that their development ran into some technical limitations.',
						}
					};

help.chatwindowOverview = {
								'Overview',
								'On first load the FancyChat window will appear on the top left of the game window with its default configuration.\nThe window will display 8 lines of text, a series of tabs for the different types of chat and other buttons assigned to extra features. '
						  }
help.chatwindowPosition = {
								'Positioning',
								'It is possible to adjust a FancyChat window position by dragging it with the mouse. If upon doing so, the window doesn\'t react, it is likely due to it being locked (see the Settings section).'
						  }
help.chatwindowHistory = {
								'Scrolling Chat History',
								'The FancyChat window allows the player to use the scroll wheel of the mouse to scroll up previous messages in the chat, effectively entering a \"Scrolling History" state. Each tick of the wheel scrolls one line, however, if the cursor is hovering the FancyChat window, it is possible to use the keyboard shortcut [Shift]+[L./R. Arrow] to scroll multiple lines at the time (see the Settings section).'
						  }
help.chatwindowTabs = 	{
								'Chat Tabs',
								'A description of how the tabs work, the compact mode, etc.'
						  }					
help.chatwindowSections = {help.chatwindowOverview, help.chatwindowPosition, help.chatwindowHistory, help.chatwindowTabs};		
help.settingsChatWindow = {
							'Chat Window',
							'In this menu...'
						  };
help.settingsFontColors = {
							'Font Colors',
							'In this menu...'
						  };
help.settingsShortcuts = {
							'Shortcuts',
							'In this menu...'
						  };
help.settingsExtra = {
						'Extra',
						'In this menu...'
					 };	
help.settingsTools = {
						'Tools',
						'In this menu...'
					 };						  
help.settingsSections = {help.settingsChatWindow, help.settingsFontColors, help.settingsShortcuts, help.settingsExtra, help.settingsTools};				


help.GetLongestWord = function(text)
    local max_word = ""
    for word in text:gmatch("%S+") do
        if #word > #max_word then
            max_word = word
        end
    end
    return max_word
end


help.SetText = function(text)
	imgui.PushTextWrapPos(imgui.GetWindowWidth()-10);
	for i = 2, #text do
		imgui.TextWrapped(text[i]);
		if i < #text then imgui.Dummy({0,5}); end
	end
	imgui.PopTextWrapPos();
end

help.AddSection = function(section, indent, parentsearch, parent, parentIdx)

	for s = 1, #section do
		local search = false;
		for f = 1, #section[s] do	
			if help.searchBuff[1] == '' then search = true;
			elseif not search then search = string.find(string.lower(section[s][f]), string.lower(help.searchBuff[1]))end
		end
		if search and help.searchBuff[1] ~= '' then help.foundAnything = true; end
		--print('hello')
		if search and help.searchBuff[1] ~= '' and parent~= nil and (parentIdx == 0 or parent~= help.foundParent[parentIdx]) and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == section[s][1] then return true end end return false end)() then  table.insert(help.foundParent, parent); elseif help.searchBuff[1] ~= '' then imgui.SetNextItemOpen(false) end
		if search and help.searchBuff[1] ~= '' and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == section[s][1] then return true end end return false end)() then   table.insert(help.foundParent, section[s][1])end
		if (search or parentsearch) and help.searchBuff[1] ~= '' then  imgui.SetNextItemOpen(true) elseif help.collapseAll then imgui.SetNextItemOpen(false) end
	--	if search then winFlags = ImGuiTreeNodeFlags_Selected; end
		if ( imgui.CollapsingHeader(section[s][1])) then --..'__'
			if (search or parentsearch) then  --ImGuiTreeNodeFlags_DefaultOpen ImGuiTreeNodeFlags_Selected --ImGuiTreeNodeFlags_OpenOnArrow
				local textlines = 0;
				if #help.GetLongestWord(section[s][1]) > #help.longestword then help.longestword = help.GetLongestWord(section[s][1]) end
				--local help.longestword = ''; --..'___'
				for i = 2, #section[s] do			
					if #help.GetLongestWord(section[s][i]) > #help.longestword then help.longestword = help.GetLongestWord(section[s][i]) end
					textlines = textlines + math.floor(imgui.CalcTextSize(section[s][i]..(i==#section[s] and (indent and help.longestword..'___' or help.longestword..'_') or ''), nil, false)/imgui.GetWindowWidth())+2;
				end
				imguiWrap.BeginChild(section[s][1].."Frame", { 0, (textlines)*(imgui.GetFont().FontSize or imgui.GetFont().LegacySize)+((#section[s]-1)*5)+25 }, true );
				help.SetText(section[s]);
				imgui.EndChild();
			end
		end
	end
end

help.AddSubSections = function(name, sections)
	local search = false;
	local foundIdx = 0;
	if help.searchBuff[1] == '' then search = true; 
	elseif not search then search = string.find(string.lower(name), string.lower(help.searchBuff[1]))end
	if search and help.searchBuff[1] ~= '' then help.foundAnything = true; end
	if search and help.searchBuff[1] ~= '' and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == name then return true end end return false end)() then  table.insert(help.foundParent, name); end
	if ( search or (#help.foundParent == 0 or (function() for i = 1, #help.foundParent do if help.foundParent[i] == name then foundIdx = i return true end end return false end)())) and help.searchBuff[1] ~= '' or help.foundAnything then imgui.SetNextItemOpen(true) elseif help.searchBuff[1] ~= '' or #help.foundParent>0 or help.collapseAll then imgui.SetNextItemOpen(false) end
	if imgui.CollapsingHeader(name) then 
		imgui.Indent();
		help.AddSection(sections,true, search, name, foundIdx);
		imgui.Unindent();
	end
	
end


help.ShowManual = function(playerName)
	
	local dsize = imgui.GetIO().DisplaySize;
	imgui.SetNextWindowSize({ dsize.x/5, dsize.y/3 }, ImGuiCond_Once);
	imgui.SetNextWindowSizeConstraints({ dsize.x/5, dsize.y/3 }, { dsize.x, dsize.y });
	if( imgui.Begin('FancyChat Manual##_'..playerName, help.opened, bit.bor(ImGuiWindowFlags_NoCollapse,ImGuiWindowFlags_NoNav))) then
		
		imguiWrap.BeginChild("TitleFrame", { 0, 48 }, true);
		imgui.Dummy({0,1})
		imgui.Dummy({(imgui.GetWindowWidth()/2)-(imgui.CalcItemWidth()/10+75),0}); imgui.SameLine();
		help.SetText({'','Welcome to FancyChat!'});
		imgui.Dummy({0,5})
		imgui.EndChild();
		imguiWrap.BeginChild("SearchFrame", { 0, 42 }, true);
		imgui.PushItemWidth(imgui.GetWindowWidth()/3)
		imgui.SetCursorPosY(imgui.GetCursorPosY()+4);
		imgui.Text('Search');imgui.SameLine();
		imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		local prevSearchBuff =  help.searchBuff[1];
		imgui.InputText(' ##SearchBox', help.searchBuff, 20, ImGuiInputTextFlags_EnterReturnsTrue);
		if prevSearchBuff ~= help.searchBuff[1] then help.foundParent = {}; help.foundAnything = false; end
		if help.searchBuff[1] == '' then help.foundAnything = false; end
		imgui.PopItemWidth()
		imgui.SameLine();
		if imguiWrap.isNewVer then
			imgui.SetCursorPosX(imgui.GetCursorPosX()-20);
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		else
			imgui.SetCursorPosX(imgui.GetCursorPosX()-20);
		end
		if imgui.Button('x', {25,0}) then
			help.searchBuff[1] = '';
			help.foundParent = {};
			help.foundAnything = false;
		end
		imgui.SameLine();
		imgui.Dummy({5,0});
		imgui.SameLine();
		if imguiWrap.isNewVer then
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		end
		if imgui.ArrowButton('##Collapse all', ImGuiDir_Up) then
			if help.searchBuff[1] == '' then help.collapseAll = true; end
		end
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX()-5);
		if imguiWrap.isNewVer then
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		end
		imgui.Text('Fold All');
		imgui.SameLine();
		imgui.EndChild();
		imguiWrap.BeginChild("MainFrame", { 0, imgui.GetWindowHeight()-142 }, true);
		help.AddSection(help.overviewText,false, false, nil, 0);
		help.AddSection(help.loremText,false, false, nil, 0);
		help.AddSubSections('The FancyChat Window', help.chatwindowSections);
		help.AddSubSections('Settings', help.settingsSections);
		imgui.Dummy({0,10})
        help.collapseAll = false;
		imgui.EndChild();
	end
	imgui.End();
end

return help;