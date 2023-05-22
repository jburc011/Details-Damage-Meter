-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	local _detalhes = _G.Details
	local Loc = LibStub("AceLocale-3.0"):GetLocale ( "Details" )
	local addonName, Details222 = ...
	local _

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--local pointers

	local upper = string.upper --lua local
	local ipairs = ipairs --lua local
	local pairs = pairs --lua local
	local _math_floor = math.floor --lua local
	local _math_max = math.max --lua local
	local _math_min = math.min --lua local
	local _math_random = math.random --lua local
	local type = type --lua local
	local _string_match = string.match --lua local
	local _string_format = string.format --lua local
	local loadstring = loadstring --lua local
	local select = select
	local tonumber = tonumber
	local strsplit = strsplit
	local _pcall = pcall
	local GetTime = GetTime

	local IsInRaid = IsInRaid --wow api local
	local IsInGroup = IsInGroup --wow api local
	local GetNumGroupMembers = GetNumGroupMembers --wow api local
	local UnitAffectingCombat = UnitAffectingCombat --wow api local
	local _InCombatLockdown = InCombatLockdown --wow api local

	local gump = _detalhes.gump --details local

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--fade handler

	Details.FadeHandler = {
		frames = {}
	}


	--fade in is hidding the frame,	it is the opposite of the stardard
	local fadeINFinishedCallback = function(frame)
		if (frame.fading_in) then
			frame.hidden = true
			frame.faded = true
			frame.fading_in = false
			frame:Hide()
		end
	end

	--fade out is showing the frame
	local fadeOUTFinishedCallback = function(frame)
		if (frame:IsShown() and frame.fading_out) then
			frame.hidden = false
			frame.faded = false
			frame.fading_out = false
		else
			frame:SetAlpha(0)
		end
	end

	local just_fade_func = function(frame)
		frame.hidden = false
		frame.faded = true
		frame.fading_in = false
	end

	local cancelFadeAnimation = function(frame)
		Details.FadeHandler.frames[frame] = nil
	end

	Details.FadeHandler.OnUpdateFrame = CreateFrame("frame", "DetailsFadeFrameOnUpdate", UIParent)
	Details.FadeHandler.OnUpdateFrame:SetScript("OnUpdate", function(self, deltaTime)
		for frame, frameSettings in pairs(Details.FadeHandler.frames) do
			local totalTime = frameSettings.totalTime
			local initAlpha = frameSettings.startAlpha
			local targetAlpha = frameSettings.endAlpha

			frameSettings.elapsed = frameSettings.elapsed + deltaTime
			local currentAlpha = Lerp(initAlpha, targetAlpha, frameSettings.elapsed / totalTime)

			if (frameSettings.elapsed >= totalTime) then
				frame:SetAlpha(targetAlpha)
				frameSettings.finishedCallback(frame)
				--remove the frame from the list
				Details.FadeHandler.frames[frame] = nil
			else
				frame:SetAlpha(currentAlpha)
			end
		end
	end)

	--fade in is hidding the frame
	local startFadeINAnimation = function(frame, totalTime, startAlpha, endAlpha, callbackFunc)
		frame.fading_out = nil
		frame.fading_in = true

		Details.FadeHandler.frames[frame] = {
			totalTime = totalTime or Details.fade_speed,
			startAlpha = startAlpha or frame:GetAlpha(),
			endAlpha = endAlpha or 0,
			finishedCallback = callbackFunc or fadeINFinishedCallback,
			elapsed = 0,
		}
	end

	--fade out is showing the frame
	local startFadeOUTAnimation = function(frame, totalTime, startAlpha, endAlpha, callbackFunc)
		frame.fading_in = nil
		frame.fading_out = true

		Details.FadeHandler.frames[frame] = {
			totalTime = totalTime or Details.fade_speed,
			startAlpha = startAlpha or frame:GetAlpha() or 0,
			endAlpha = endAlpha or 1,
			finishedCallback = callbackFunc or fadeOUTFinishedCallback,
			elapsed = 0,
		}
	end

	function Details.FadeHandler.Fader(frame, animationType, speed, hideType, param5)
		if (frame == nil) then
			frame, animationType, speed, hideType = animationType, speed, hideType, param5
		end

		--if is a table, might be passed an instance object
		if (type(frame) == "table") then
			--is it an instance
			if (frame.meu_id) then

				local instance = frame

				--hide all bars in the instance
				if (hideType == "barras") then
					if (speed) then
						for i = 1, instance.rows_created do
							local instanceBar = instance.barras[i]
							Details.FadeHandler.Fader(instanceBar, animationType, speed)
						end
						return
					else
						speed = speed or Details.fade_speed
						for i = 1, instance.rows_created do
							local instanceBar = instance.barras[i]
							Details.FadeHandler.Fader(instanceBar, animationType, Details.fade_speed+(i/10))
						end
						return
					end

				--instant hide all bars in the instance
				elseif (hideType == "hide_barras") then
					for i = 1, instance.rows_created do
						local instanceBar = instance.barras[i]
						if (instanceBar.fading_in or instanceBar.fading_out) then
							startFadeINAnimation(instanceBar, 0.01, instanceBar:GetAlpha(), instanceBar:GetAlpha())
						end
						instanceBar.hidden = true
						instanceBar.faded = true
						instanceBar.fading_in = false
						instanceBar.fading_out = false
						instanceBar:Hide()
						instanceBar:SetAlpha(0)
					end
					return
				end

			--if is a framework widget
			elseif (frame.dframework) then
				frame = frame.widget
			end
		end

		speed = speed or Details.fade_speed
		--animationType = upper(animationType)

		--hide all instanceBars on all instances
		if (frame == "all") then
			for _, instancia in ipairs(_detalhes.tabela_instancias) do
				if (hideType == "barras") then
					for i = 1, instancia.rows_created do
						local instanceBar = instancia.barras[i]
						Details.FadeHandler.Fader(instanceBar, animationType, speed+(i/10))
					end
				end
			end
			return

		elseif (upper(animationType) == "IN") then --hide the frame

			--check if already hidden
			if (frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out) then
				return
			--chekc if already with an animation going on
			elseif (frame.fading_in) then
				return
			end

			--cancel face out animation if exists
			if (frame.fading_out) then
				frame.fading_out = false
			end
			startFadeINAnimation(frame, speed, frame:GetAlpha(), 0)

		elseif (upper(animationType) == "OUT") then --show the frame

			if (frame:GetAlpha() == 1 and not frame.hidden and not frame.fading_in) then --ja esta na tela
				return
			elseif (frame.fading_out) then --j� ta com fading out
				return
			end

			if (frame.fading_in) then --se tiver uma anima��o de hidar em andamento se for true
				frame.fading_in = false
			end

			frame:Show()
			startFadeOUTAnimation(frame, speed, frame:GetAlpha(), 1.0)
			frame.fading_out = true

		elseif (animationType == 0) then --force show the frame
			frame.hidden = false
			frame.faded = false
			frame.fading_out = false
			frame.fading_in = false
			cancelFadeAnimation(frame) --cancel any ongoing animation
			frame:Show()
			frame:SetAlpha(1)

		elseif (animationType == 1) then --force hide the frame
			frame.hidden = true
			frame.faded = true
			frame.fading_out = false
			frame.fading_in = false
			cancelFadeAnimation(frame) --cancel any ongoing animation
			frame:SetAlpha(0)
			frame:Hide()

		elseif (animationType == -1) then --just fade to zero without hidding the frame
			--check already hidden
			if (frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out) then
				return
			--check already hidding
			elseif (frame.fading_in) then
				return
			end

			if (frame.fading_out) then
				frame.fading_out = false
			end

			startFadeINAnimation(frame, speed, frame:GetAlpha(), 0, just_fade_func)

		elseif (upper(animationType) == "ALPHAANIM") then

			local value = speed
			local currentApha = frame:GetAlpha()
			frame:Show()

			if (currentApha < value) then
				if (frame.fading_in) then
					frame.fading_in = false
				end
				startFadeOUTAnimation(frame, Details.fade_speed, currentApha, value, function(frame) frame.fading_out = false end)
			else
				if (frame.fading_out) then
					frame.fading_out = false
				end
				startFadeINAnimation(frame, Details.fade_speed, currentApha, value, function(frame) frame.fading_in = false end)
			end

		--set a fixed alpha value
		elseif (upper(animationType) == "ALPHA") then
			local alphaAmount = speed

			if (frame.fading_in or frame.fading_out) then
				startFadeINAnimation(frame, speed, alphaAmount, alphaAmount)
			end
			frame.hidden = false
			frame.faded = false
			frame.fading_in = false
			frame.fading_out = false
			frame:Show()
			frame:SetAlpha(alphaAmount)
		end
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--details api functions

	--get the npc id from guid
	function _detalhes:GetNpcIdFromGuid (guid)
		local NpcId = select( 6, strsplit( "-", guid ) )
		if (NpcId) then
			return tonumber( NpcId )
		end
		return 0
	end

	function _detalhes:GetSourceFromNpcId (npcId)
		for index, container in ipairs(_detalhes.tabela_vigente) do
			if (index <= 4) then
				local t = container._ActorTable
				for i = 1, #t do
					if (_detalhes:GetNpcIdFromGuid (t[i].serial) == npcId) then
						return t[i].nome
					end
				end
			end
		end
	end

	function Details:GetRaidLeader()
		if (IsInRaid()) then
			for i = 1, GetNumGroupMembers() do
				local name, rank = GetRaidRosterInfo(i)
				if (rank == 2) then
					return name, "raid" .. i
				end
			end
		end
		return
	end

	function _detalhes:UnpackDeathTable (t)
		local deathevents = t[1]
		local deathtime = t[2]
		local playername = t[3]
		local playerclass = t[4]
		local playermaxhealth = t[5]
		local deathtimestring = t[6]
		local lastcooldown = t.last_cooldown
		local deathcombattime = t.dead_at

		return playername, playerclass, deathtime, deathcombattime, deathtimestring, playermaxhealth, deathevents, lastcooldown
	end

	---get a random fraction number
	---@return number
	function Details:GetOrderNumber() --anyString
		--local name = upper(anyString .. "zz")
		--local byte1 = abs(_string_byte(name, 2)-91) / 1000000
		--return byte1 + abs(_string_byte(name, 1)-91) / 10000
		return _math_random(1000, 9000) / 1000000
	end

	--/script print(tonumber(4/1000000)) - 4e-006
	--0.000004
	--set all table keys to lower
	local temptable = {}
	function _detalhes:LowerizeKeys (_table)
		for key, value in pairs(_table) do
			temptable [string.lower(key)] = value
		end
		temptable, _table = Details:Destroy(_table), temptable
		return _table
	end

	_detalhes.ToKFunctions = {}

	--krKR by @yuk6196 (http://wow.curseforge.com/profiles/yuk6196)
	function _detalhes:UseEastAsianNumericalSystem()

		--try to auto detect the language
		local symbol_1K, symbol_10K, symbol_1B
		if (LibStub("AceLocale-3.0"):NewLocale ("Details", "koKR")) then --Korea
			symbol_1K, symbol_10K, symbol_1B = "천", "만", "억"
		elseif (LibStub("AceLocale-3.0"):NewLocale ("Details", "zhCN")) then --China
			symbol_1K, symbol_10K, symbol_1B = "千", "万", "亿"
		elseif (LibStub("AceLocale-3.0"):NewLocale ("Details", "zhTW")) then --Taiwan
			symbol_1K, symbol_10K, symbol_1B = "千", "萬", "億"
		end

		--override, force details! to use symbols for a specific language.
		--usage: _detalhes:SetNumericalSystemOverride (language)  language can be:  "kr", "cn", "tw"

		--just in case the user mess up something
		if (type(_detalhes.numerical_system_symbols) ~= "string") then
			_detalhes.numerical_system_symbols = "auto"
		end

		--do the override
		if (_detalhes.numerical_system_symbols ~= "auto") then
			local locale = string.lower(_detalhes.numerical_system_symbols)

			if (locale == "kr") then
				symbol_1K, symbol_10K, symbol_1B = "천", "만", "억"
			elseif (locale == "cn") then
				symbol_1K, symbol_10K, symbol_1B = "千", "万", "亿"
			elseif (locale == "tw") then
				symbol_1K, symbol_10K, symbol_1B = "千", "萬", "億"
			end
		end

		if (not symbol_1K) then
			--if a english client is trying to use east asian numeral system and there is no override, let's just use the chinese as default.
			--if the user is from kr or tw and want to use english client,  an override must be used.
			symbol_1K, symbol_10K, symbol_1B = "千", "万", "亿"
		end

		function _detalhes:ToK (numero)
			if (numero > 100000000) then
				return _string_format ("%.2f", numero/100000000) .. symbol_1B
			elseif (numero > 10000) then
				return _string_format ("%.2f", numero/10000) .. symbol_10K
			elseif (numero > 1000) then
				return _string_format ("%.1f", numero/1000) .. symbol_1K
			end
			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToK2 (numero)
			if (numero > 99999999) then
				return _string_format ("%.2f", numero/100000000) .. symbol_1B
			elseif (numero > 999999) then
				return _string_format ("%.2f", numero/10000) .. symbol_10K
			elseif (numero > 99999) then
				return _math_floor(numero/10000) .. symbol_10K
			elseif (numero > 9999) then
				return _string_format ("%.1f", (numero/10000)) .. symbol_10K
			elseif (numero > 999) then
				return _string_format ("%.1f", (numero/1000)) .. symbol_1K
			end
			return _string_format ("%.1f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToK0 (numero)
			if (numero > 100000000) then
				return _string_format ("%.0f", numero/100000000) .. symbol_1B
			elseif (numero > 10000) then
				return _string_format ("%.0f", numero/10000) .. symbol_10K
			elseif (numero > 1000) then
				return _string_format ("%.0f", numero/1000) .. symbol_1K
			end
			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToKMin (numero)
			if (numero > 100000000) then
				return _string_format ("%.2f", numero/100000000) .. symbol_1B
			elseif (numero > 10000) then
				return _string_format ("%.2f", numero/10000) .. symbol_10K
			elseif (numero > 1000) then
				return _string_format ("%.1f", numero/1000) .. symbol_1K
			end
			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToK2Min (numero)
			if (numero > 99999999) then
				return _string_format ("%.2f", numero/100000000) .. symbol_1B
			elseif (numero > 999999) then
				return _string_format ("%.2f", numero/10000) .. symbol_10K
			elseif (numero > 99999) then
				return _math_floor(numero/10000) .. symbol_10K
			elseif (numero > 9999) then
				return _string_format ("%.1f", (numero/10000)) .. symbol_10K
			elseif (numero > 999) then
				return _string_format ("%.1f", (numero/1000)) .. symbol_1K
			end
			return _string_format ("%.1f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToK0Min (numero)
			if (numero > 100000000) then
				return _string_format ("%.0f", numero/100000000) .. symbol_1B
			elseif (numero > 10000) then
				return _string_format ("%.0f", numero/10000) .. symbol_10K
			elseif (numero > 1000) then
				return _string_format ("%.0f", numero/1000) .. symbol_1K
			end
			return _string_format ("%.0f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToKReport (numero)
			if (numero > 100000000) then
				return _string_format ("%.2f", numero/100000000) .. symbol_1B
			elseif (numero > 10000) then
				return _string_format ("%.1f", numero/10000) .. symbol_10K
			elseif (numero > 1000) then
				return _string_format ("%.0f", numero/1000) .. symbol_1K
			end
			return numero
		end

		function _detalhes:Format (n, custom)
			n = _math_floor(n)
			if (custom) then
				if (n > 99999999) then
					return _string_format (custom, n/100000000) .. symbol_1B
				elseif (n > 9999) then
					return _string_format (custom, n/10000) .. symbol_10K
				elseif (n > 999) then
					return _string_format (custom, (n/1000))
				else
					return n
				end
			else
				return _detalhes.ToKFunctions [_detalhes.ps_abbreviation] (nil, n)
			end
		end

		--no changes
		function _detalhes:NoToK (numero)
			return _math_floor(numero)
		end

		-- thanks http://richard.warburton.it
		function _detalhes:comma_value (n)
			if (not n) then return "0" end
			n = _math_floor(n)
			if (n == 0) then
				return "0"
			end
			local left,num,right = _string_match (n,'^([^%d]*%d)(%d*)(.-)$')
			return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
		end
		
		function _detalhes:comma_value_raw (n)
			local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
			return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
		end

		Details:Destroy (_detalhes.ToKFunctions)

		tinsert(_detalhes.ToKFunctions, _detalhes.NoToK)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK2)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK0)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToKMin)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK2Min)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK0Min)
		tinsert(_detalhes.ToKFunctions, _detalhes.comma_value)

	end

	function _detalhes:UseWestNumericalSystem()
		--short numbers
		function _detalhes:ToK (numero)
			if (numero > 999999999) then
				return format("%.2f", numero/1000000000) .. "B"
			elseif (numero > 1000000) then
				return _string_format ("%.2f", numero/1000000) .. "M"
			elseif (numero > 999) then
				return _string_format ("%.1f", numero/1000) .. "K"
			end

			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToK2 (numero)
			if (numero > 999999999) then
				return format("%.2f", numero/1000000000) .. "B"
			elseif (numero > 999999) then
				return _string_format ("%.2f", numero/1000000) .. "M"
			elseif (numero > 99999) then
				return _math_floor(numero/1000) .. "K"
			elseif (numero > 999) then
				return _string_format ("%.1f", (numero/1000)) .. "K"
			end

			return _string_format ("%.0f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToK0 (numero)
			if (numero > 999999999) then
				return format("%.2f", numero/1000000000) .. "B"
			elseif (numero > 1000000) then
				return _string_format ("%.0f", numero/1000000) .. "M"
			elseif (numero > 1000) then
				return _string_format ("%.0f", numero/1000) .. "K"
			end

			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToKMin (numero)
			if (numero > 1000000) then
				return _string_format ("%.2f", numero/1000000) .. "m"
			elseif (numero > 1000) then
				return _string_format ("%.1f", numero/1000) .. "k"
			end

			return _string_format ("%.0f", numero)
		end

		function _detalhes:ToK2Min (numero)
			if (numero > 999999) then
				return _string_format ("%.2f", numero/1000000) .. "m"
			elseif (numero > 99999) then
				return _math_floor(numero/1000) .. "k"
			elseif (numero > 999) then
				return _string_format ("%.1f", (numero/1000)) .. "k"
			end

			return _string_format ("%.0f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToK0Min (numero)
			if (numero > 1000000) then
				return _string_format ("%.0f", numero/1000000) .. "m"
			elseif (numero > 1000) then
				return _string_format ("%.0f", numero/1000) .. "k"
			end

			return _string_format ("%.0f", numero)
		end

		--short numbers no numbers after comma
		function _detalhes:ToKReport (numero)
			if (numero > 1000000) then
				return _string_format ("%.2f", numero/1000000) .. "M"
			elseif (numero > 1000) then
				return _string_format ("%.1f", numero/1000) .. "K"
			end

			return numero
		end

		function _detalhes:Format (n, custom)
			n = _math_floor(n)
			if (custom) then
				if (n > 999999) then
					return _string_format (custom, n/1000000) .. "M"
				elseif (n > 999) then
					return _string_format (custom, (n/1000))
				else
					return n
				end
			else
				return _detalhes.ToKFunctions [_detalhes.ps_abbreviation] (nil, n)
			end
		end

		--no changes
		function _detalhes:NoToK (numero)
			return _math_floor(numero)
		end

		-- thanks http://richard.warburton.it
		function _detalhes:comma_value (n)
			if (not n) then return "0" end
			n = _math_floor(n)
			if (n == 0) then
				return "0"
			end
			local left,num,right = _string_match (n,'^([^%d]*%d)(%d*)(.-)$')
			return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
		end
		function _detalhes:comma_value_raw (n)
			local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
			return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
		end

		Details:Destroy (_detalhes.ToKFunctions)

		tinsert(_detalhes.ToKFunctions, _detalhes.NoToK)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK2)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK0)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToKMin)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK2Min)
		tinsert(_detalhes.ToKFunctions, _detalhes.ToK0Min)
		tinsert(_detalhes.ToKFunctions, _detalhes.comma_value)

		--
	end

	--load western as default, the proper method is loaded within the profile
	_detalhes:UseWestNumericalSystem()

	function _detalhes:GetCurrentToKFunction()
		return _detalhes.ToKFunctions [_detalhes.ps_abbreviation]
	end

	--alias
	---transfor an integer into a string separating thousands with a comma
	---@param number number
	---@return string
	function Details:CommaValue(number)
		return Details:comma_value(number)
	end


------------------------------------------------------------------------------------------------------------
--numerical system

	function _detalhes:SetNumericalSystemOverride (language)
		if (not language) then
			language = "auto"
		end
		_detalhes.numerical_system_symbols = language
		_detalhes:Msg("NumSystem override is now:", language)

		_detalhes:SelectNumericalSystem()
	end

	function _detalhes:GetNumericalSystem()
		return _detalhes.numerical_system
	end

	function _detalhes:SelectNumericalSystem (system)
		if (not system or type(system) ~= "number") then
			system = _detalhes.numerical_system or 1
		end

		_detalhes.numerical_system = system

		if (system == 1) then
			_detalhes:UseWestNumericalSystem()
		elseif (system == 2) then
			_detalhes:UseEastAsianNumericalSystem()
		end

		_detalhes:UpdateToKFunctions()
	end

	function _detalhes:UpdateToKFunctions()
		_detalhes.atributo_damage:UpdateSelectedToKFunction()
		_detalhes.atributo_heal:UpdateSelectedToKFunction()
		_detalhes.atributo_energy:UpdateSelectedToKFunction()
		_detalhes.atributo_misc:UpdateSelectedToKFunction()
		_detalhes.atributo_custom:UpdateSelectedToKFunction()
		Details:RefreshMainWindow(-1, true)
	end

--------end of ToK functions----

	--replacing data for custom texts
	_detalhes.string = {}

	local function_cache = {}
	local arguments_cache = {}
	local parameters_cache = {}

	local replace_arg = function(i)
		return arguments_cache [tonumber(i)]
	end
	local run_function = function(str)
		--cache functions
		local func, errortext = function_cache [str]
		if (not func) then
			func = loadstring (str)
			if (not func) then
				_detalhes:Msg("|cFFFF9900error compiling script on custom text|r: ", errortext)
				return 0
			end
			DetailsFramework:SetEnvironment(func)
			function_cache [str] = func
		end

		local okey, value = _pcall (func, parameters_cache [1], parameters_cache [2], parameters_cache [3], parameters_cache [4], arguments_cache[1], arguments_cache[2], arguments_cache[3])
		if (not okey) then
			_detalhes:Msg("|cFFFF9900error on custom text|r:", value)
			return 0
		end
		return value or 0
	end

	function _detalhes.string.replace (str, v1, v2, v3, v4, v5, v6, v7)
		arguments_cache [1] = v1
		arguments_cache [2] = v2
		arguments_cache [3] = v3
		parameters_cache [1] = v4
		parameters_cache [2] = v5
		parameters_cache [3] = v6
		parameters_cache [4] = v7

		return (str:gsub("{data(%d+)}", replace_arg):gsub("{func(.-)}", run_function))
	end

	--remove a index from a hash table
	function _detalhes:tableRemove (tabela, indexName)
		local newtable = {}
		for hash, value in pairs(tabela) do
			if (hash ~= indexName) then
				newtable [hash] = value
			end
		end
		return newtable
	end

	--return if the numeric table have an object
	function _detalhes:tableIN (tabela, objeto)
		for index, valor in ipairs(tabela) do
			if (valor == objeto) then
				return index
			end
		end
		return false
	end

	--reverse numerical table
	function _detalhes:reverse_table (t)
		local new = {}
		local index = 1
		for i = #t, 1, -1 do
			new [index] = t[i]
			index = index + 1
		end
		return new
	end

	_detalhes.table = {}

	function _detalhes.table.reverse (t)
		local new = {}
		local index = 1
		for i = #t, 1, -1 do
			new [index] = t[i]
			index = index + 1
		end
		return new
	end
	--yah, i know

	function _detalhes.table.copy(t1, t2)
		for key, value in pairs(t2) do
			if (type(value) == "table") then
				t1 [key] = Details.CopyTable(value)
			else
				t1 [key] = value
			end
		end
		return t1
	end

	function _detalhes.table.deploy(t1, t2)
		for key, value in pairs(t2) do
			if (type(value) == "table") then
				t1 [key] = t1 [key] or {}
				_detalhes.table.deploy(t1 [key], t2 [key])
			elseif (t1 [key] == nil) then
				t1 [key] = value
			end
		end
	end

	function _detalhes.table.overwrite (t1, t2)
		for key, value in pairs(t2) do
			if (type(value) == "table") then
				t1 [key] = t1 [key] or {}
				_detalhes.table.overwrite (t1 [key], t2 [key])
			else
				t1 [key] = value
			end
		end
	end

	function _detalhes.table.dump (t, s, deep)

		if (type(t) == "number") then
			return t
		end

		s = s or ""
		deep = deep or 0
		local space = ""
		for i = 1, deep do
			space = space .. "   "
		end

		for key, value in pairs(t) do

			local tpe = type(value)

			if (type(key) == "function") then
				key = "#function#"
			elseif (type(key) == "table") then
				key = "#table#"
			end

			if (type(key) ~= "string" and type(key) ~= "number") then
				key = "unknown?"
			end

			if (tpe == "table") then
				if (type(key) == "number") then
					s = s .. space .. "[" .. key .. "] = |cFFa9ffa9table {|r\n"
				else
					s = s .. space .. "[\"" .. key .. "\"] = |cFFa9ffa9table {|r\n"
				end
				s = s .. _detalhes.table.dump (value, nil, deep+1)
				s = s .. space .. "|cFFa9ffa9}|r\n"

			elseif (tpe == "string") then
				s = s .. space .. "[\"" .. key .. "\"] = '|cFFfff1c1" .. value .. "|r'\n"

			elseif (tpe == "number") then
				s = s .. space .. "[\"" .. key .. "\"] = |cFFffc1f4" .. value .. "|r\n"

			elseif (tpe == "function") then
				s = s .. space .. "|cFFa9a9ff[\"|r" .. key .. "|cFFa9a9ff\"]|r = |cFFa9a9fffunction()|r\n"

			elseif (tpe == "boolean") then
				s = s .. space .. "[\"" .. key .. "\"] = |cFF99d0ff" .. (value and "true" or "false") .. "|r\n"

			end

		end

		return s
	end

	function _detalhes:hex (num)
		local hexstr = '0123456789abcdef'
		local s = ''
		while num > 0 do
			local mod = math.fmod(num, 16)
			s = string.sub(hexstr, mod+1, mod+1) .. s
			num = math.floor(num / 16)
		end
		if s == '' then s = '00' end
		if (string.len(s) == 1) then
			s = "0"..s
		end
		return s
	end

	function _detalhes:percent_color (value, inverted)
		local r, g
		if (value < 50) then
			r = 255
		else
			r = _math_floor( 255 - (value * 2 - 100) * 255 / 100)
		end

		if (value > 50) then
			g = 255
		else
			g = _math_floor( (value * 2) * 255 / 100)
		end

		if (inverted) then
			return g/255, r/255, 0
		else
			return r/255, g/255, 0
		end
	end

	--unpack more than 1 table
	-- http://www.dzone.com/snippets/lua-unpack-multiple-tables
	function _detalhes:unpacks (...)
		local values = {}
		for i = 1, select('#', ...) do
			for _, value in ipairs(select(i, ...)) do
				values[ #values + 1] = value
			end
		end
		return unpack(values)
	end

	--trim http://lua-users.org/wiki/StringTrim
	function _detalhes:trim (s)
		local from = s:match"^%s*()"
		return from > #s and "" or s:match(".*%S", from)
	end

-- lua base64 codec (c) 2006-2008 by Alex Kloss - http://www.it-rfc.de - licensed under the terms of the LGPL2 - http://lua-users.org/wiki/BaseSixtyFour
do
	_detalhes._encode = {}

	-- shift left
	local function lsh (value,shift)
		return (value*(2^shift)) % 256
	end

	-- shift right
	local function rsh (value,shift)
		return math.floor(value/2^shift) % 256
	end

	-- return single bit (for OR)
	local function bit (x,b)
		return (x % 2^b - x % 2^(b-1) > 0)
	end

	-- logic OR for number values
	local function lor (x,y)
		local result = 0
		for p=1,8 do result = result + (((bit(x,p) or bit(y,p)) == true) and 2^(p-1) or 0) end
		return result
	end

	-- encryption table
	local base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_'}

	-- function encode
	-- encodes input string to base64.
	function _detalhes._encode:enc (data)
		local bytes = {}
		local result = ""
		for spos=0,string.len(data)-1,3 do
			for byte=1,3 do bytes[byte] = string.byte(string.sub(data,(spos+byte))) or 0 end
			result = string.format('%s%s%s%s%s',result,base64chars[rsh(bytes[1],2)],base64chars[lor(lsh((bytes[1] % 4),4), rsh(bytes[2],4))] or "=",((#data-spos) > 1) and base64chars[lor(lsh(bytes[2] % 16,2), rsh(bytes[3],6))] or "=",((#data-spos) > 2) and base64chars[(bytes[3] % 64)] or "=")
		end
		return result
	end

	-- decryption table
	local base64bytes = {['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['-']=62,['_']=63,['=']=nil}

	-- function decode
	-- decode base64 input to string
	function _detalhes._encode:Decode (data)
		local chars = {}
		local result=""
		for dpos=0,string.len(data)-1,4 do
			for char=1,4 do chars[char] = base64bytes[(string.sub(data,(dpos+char),(dpos+char)) or "=")] end
			result = string.format('%s%s%s%s',result,string.char(lor(lsh(chars[1],2), rsh(chars[2],4))),(chars[3] ~= nil) and string.char(lor(lsh(chars[2],4), rsh(chars[3],2))) or "",(chars[4] ~= nil) and string.char(lor(lsh(chars[3],6) % 192, (chars[4]))) or "")
		end
		return result
	end

	function _detalhes._encode:Encode (s)
		return _detalhes._encode:enc (s)
	end
end

	--scale
	function _detalhes:Scale (rangeMin, rangeMax, scaleMin, scaleMax, x)
		return 1 + (x - rangeMin) * (scaleMax - scaleMin) / (rangeMax - rangeMin)
	end

	--font color
	function _detalhes:SetFontColor(fontString, r, g, b, a)
		r, g, b, a = gump:ParseColors(r, g, b, a)
		fontString:SetTextColor(r, g, b, a)
	end

	--font size
	function _detalhes:SetFontSize(fontString, ...)
		local fonte, _, flags = fontString:GetFont()
		fontString:SetFont(fonte, _math_max (...), flags)
	end
	function _detalhes:GetFontSize (fontString)
		local _, size = fontString:GetFont()
		return size
	end

	--font face
	function _detalhes:SetFontFace (fontString, fontface)
		local _, size, flags = fontString:GetFont()
		fontString:SetFont(fontface, size, flags)
	end
	function _detalhes:GetFontFace (fontString)
		local fontface = fontString:GetFont()
		return fontface
	end

	--font outline
	function _detalhes:SetFontOutline (fontString, outline)
		local fonte, size = fontString:GetFont()
		if (outline) then
			if (type(outline) == "boolean" and outline) then
				outline = "OUTLINE"
			elseif (outline == 1) then
				outline = "OUTLINE"
			elseif (outline == 2) then
				outline = "THICKOUTLINE"
			end
		end

		if (_detalhes.force_font_outline ~= "") then
			if (_detalhes.force_font_outline == "OUTLINE") then
				outline = "OUTLINE"
			elseif (_detalhes.force_font_outline == "THICKOUTLINE") then
				outline = "THICKOUTLINE"
			elseif (_detalhes.force_font_outline == "MONOCHROME") then
				outline = "MONOCHROME"
			end
		end

		fontString:SetFont(fonte, size, outline)
	end

	function _detalhes:UseOutline (outline)
		outline = outline or ""
		_detalhes.force_font_outline = outline
		for ID, instance in _detalhes:ListInstances() do
			if (instance:IsEnabled()) then
				instance:RefreshBars()
				instance:InstanceReset()
				instance:ReajustaGump()
			end
		end
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--internal functions

	function _detalhes:HealthTick()
		if (UnitExists("boss1") and IsInRaid() and IsInInstance()) then
			local health = (UnitHealth ("boss1") or 0) / (UnitHealthMax ("boss1") or 0)
			if (_detalhes.boss1_health_percent) then
				if (_detalhes.boss1_health_percent < health) then
					return
				end
			end
			_detalhes.boss1_health_percent = health
		end
	end

	--is in combat yet?
	function _detalhes:EstaEmCombate()

		_detalhes:TimeDataTick()
		_detalhes:BrokerTick()
		_detalhes:HealthTick()

		local _, zoneType = GetInstanceInfo()

		if (Details.Coach.Server.IsEnabled()) then
			if (Details.debug) then
				print("coach server is enabled, can't leave combat...")
			end
			return true

		--battleground
		elseif (zoneType == "pvp" and _detalhes.use_battleground_server_parser) then
			return true

		--arena
		elseif (zoneType == "arena" or _InCombatLockdown()) then
			return true

		--is in combat
			elseif (UnitAffectingCombat("player")) then
				return true

			elseif (IsInRaid()) then
				local unitIdCache = Details222.UnitIdCache.Raid
				for i = 1, GetNumGroupMembers(), 1 do
					if (UnitAffectingCombat(unitIdCache[i])) then
						return true
					end
				end

			elseif (IsInGroup()) then
				local unitIdCache = Details222.UnitIdCache.Party
				for i = 1, GetNumGroupMembers()-1, 1 do
					if (UnitAffectingCombat(unitIdCache[i])) then
						return true
					end
				end
			end

		--coach feature
		if (not Details.Coach.Server.IsEnabled()) then
			if (Details.debug) then
				Details:Msg("coach is disabled, the combat is now over!")
			end
		end

		Details:SairDoCombate()
	end

	function _detalhes:FindGUIDFromName (name)
		if (IsInRaid()) then
			for i = 1, GetNumGroupMembers(), 1 do
				local this_name, _ = UnitName ("raid"..i)
				if (this_name == name) then
					return UnitGUID("raid"..i)
				end
			end
		elseif (IsInGroup()) then
			for i = 1, GetNumGroupMembers()-1, 1 do
				local this_name, _ = UnitName ("party"..i)
				if (this_name == name) then
					return UnitGUID("party"..i)
				end
			end
		end
		if (UnitName ("player") == name) then
			return UnitGUID("player")
		end
		return nil
	end

	--[[ test grayscale ]]
	function _detalhes:teste_grayscale()
		local instancia = _detalhes.tabela_instancias[1]
		for i = 1, instancia.rows_created, 1 do
			local barra = instancia.barras[i]
			local red, green, blue, alpha = barra.textura:GetVertexColor()
			local grayscale = (red*0.03+green+blue) / 3 --grayscale lightness method
			gump:GradientEffect ( barra.textura, "texture", red, green, blue, alpha, grayscale, grayscale, grayscale, alpha, 1)
		end
	end

	local function frame_task (self, elapsed)

		self.FrameTime = self.FrameTime + elapsed

		if (self.HaveGradientEffect) then

			local done = false
			for index, ThisGradient in ipairs(self.gradientes) do

				if (not ThisGradient.done) then

					local percent = _math_min((GetTime() - ThisGradient.TimeStart) / ThisGradient.Duration * 100, 100)
					local red_now = ThisGradient.StartRed + (percent  * ThisGradient.OnePercentRed)
					local green_now = ThisGradient.StartGreen + (percent * ThisGradient.OnePercentGreen)
					local blue_now = ThisGradient.StartBlue + (percent  * ThisGradient.OnePercentBlue)
					local alpha_now = ThisGradient.StartAlpha + (percent  * ThisGradient.OnePercentAlpha)

					red_now = Saturate(red_now)
					green_now = Saturate(green_now)
					blue_now = Saturate(blue_now)
					alpha_now = Saturate(alpha_now)

					if (ThisGradient.ObjectType == "frame") then
						ThisGradient.Object:SetBackdropColor(red_now, green_now, blue_now, alpha_now)
					elseif (ThisGradient.ObjectType == "texture") then
						ThisGradient.Object:SetVertexColor(red_now, green_now, blue_now, alpha_now)
					end

					if (percent == 100) then
						if (ThisGradient.Func) then
							local okey, errortext = _pcall (ThisGradient.Func, ThisGradient.FuncParam)
							if (not okey) then
								_detalhes:Msg("GradientEffect() end function error:", errortext)
							end
						end

						ThisGradient.done = true
						done = true
					end
				end
			end

			if (done) then
				local _iter = {index = 1, data = self.gradientes [1]}
				while (_iter.data) do
					if (_iter.data.done) then
						_iter.data.Object.HaveGradientEffect = false
						table.remove (self.gradientes, _iter.index)
						_iter.data = self.gradientes [_iter.index]
					else
						_iter.index = _iter.index + 1
						_iter.data = self.gradientes [_iter.index]
					end
				end

				if (#self.gradientes < 1) then
					self.HaveGradientEffect = false
				end
			end
		end

		if (not self.HaveGradientEffect) then
			self:SetScript("OnUpdate", nil)
		end

	end

	function gump:GradientEffect (Object, ObjectType, StartRed, StartGreen, StartBlue, StartAlpha, EndRed, EndGreen, EndBlue, EndAlpha, Duration, EndFunction, FuncParam)

		if (type(StartRed) == "table" and type(StartGreen) == "table") then
			Duration, EndFunction = StartBlue, StartAlpha
			EndRed, EndGreen, EndBlue, EndAlpha = unpack(StartGreen)
			StartRed, StartGreen, StartBlue, StartAlpha = unpack(StartRed)

		elseif (type(StartRed) == "table") then
			EndRed, EndGreen, EndBlue, EndAlpha, Duration, EndFunction = StartGreen, StartBlue, StartAlpha, EndRed, EndGreen, EndBlue
			StartRed, StartGreen, StartBlue, StartAlpha = unpack(StartRed)

		elseif (type(EndRed) == "table") then
			Duration, EndFunction = EndGreen, EndBlue
			EndRed, EndGreen, EndBlue, EndAlpha = unpack(EndRed)
		end

		if (not EndAlpha) then
			EndAlpha = 1.0
		end
		if (not StartAlpha) then
			StartAlpha = 1.0
		end
		if (not StartRed) then
			StartRed = 1.0
		end
		if (not StartGreen) then
			StartGreen = 1.0
		end
		if (not startBlue) then
			StartBlue = 1.0
		end
		if (not EndRed or EndRed > 1.0) then
			EndRed = 1.0
		end
		if (not EndGreen or EndGreen > 1.0) then
			EndGreen = 1.0
		end
		if (not EndBlue or EndBlue > 1.0) then
			EndBlue = 1.0
		end

		local GradientFrameControl = _detalhes.listener
		GradientFrameControl.gradientes = GradientFrameControl.gradientes or {}

		for index = 1, #GradientFrameControl.gradientes do
			if (GradientFrameControl.gradientes[index].Object == Object) then
				GradientFrameControl.gradientes[index].done = true
			end
		end

		if (EndFunction and type(EndFunction) == "string") then
			EndFunction = loadstring (EndFunction) or false
			if (EndFunction) then
				DetailsFramework:SetEnvironment(EndFunction)
			end
		end

		GradientFrameControl.gradientes [#GradientFrameControl.gradientes+1] = {
			Object = Object,
			ObjectType = string.lower(ObjectType),
			Func = EndFunction,
			FuncParam = FuncParam,
			TimeStart = GetTime(),
			Duration = Duration,

			StartRed = StartRed,
			StartGreen = StartGreen,
			StartBlue = StartBlue,
			StartAlpha = StartAlpha,

			OnePercentRed = StartRed > EndRed and (StartRed - EndRed) / 100 * -1 or (EndRed - StartRed) / 100,
			OnePercentGreen = StartGreen > EndGreen and (StartGreen - EndGreen) / 100 * -1 or (EndGreen - StartGreen) / 100,
			OnePercentBlue = StartBlue > EndBlue and (StartBlue - EndBlue) / 100 * -1 or (EndBlue - StartBlue) / 100,
			OnePercentAlpha = StartAlpha > EndAlpha and (StartAlpha - EndAlpha) / 100 * -1 or (EndAlpha - StartAlpha) /100,
		}

		Object.HaveGradientEffect = true
		GradientFrameControl.HaveGradientEffect = true

		if (not GradientFrameControl:GetScript("OnUpdate")) then
			GradientFrameControl:SetScript("OnUpdate", frame_task)
		end

	end

	--work around to solve the UI Frame Flashes
	local onFinish = function(self)
		if (self.showWhenDone) then
			self.frame:SetAlpha(1)
		else
			self.frame:SetAlpha(0)
			self.frame:Hide()
		end

		if (self.onFinishFunc) then
			self:onFinishFunc (self.frame)
		end
	end

	local stop = function(self)
		local FlashAnimation = self.FlashAnimation
		FlashAnimation:Stop()
	end

	local flash = function(self, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime, loopType)

		local FlashAnimation = self.FlashAnimation

		local fadeIn = FlashAnimation.fadeIn
		local fadeOut = FlashAnimation.fadeOut

		fadeIn:Stop()
		fadeOut:Stop()

		fadeIn:SetDuration(fadeInTime or 1)
		fadeIn:SetEndDelay (flashInHoldTime or 0)

		fadeOut:SetDuration(fadeOutTime or 1)
		fadeOut:SetEndDelay (flashOutHoldTime or 0)

		FlashAnimation.duration = flashDuration
		FlashAnimation.loopTime = FlashAnimation:GetDuration()
		FlashAnimation.finishAt = GetTime() + flashDuration
		FlashAnimation.showWhenDone = showWhenDone

		FlashAnimation:SetLooping (loopType or "REPEAT")

		self:Show()
		self:SetAlpha(0)
		FlashAnimation:Play()
	end

	function gump:CreateFlashAnimation (frame, onFinishFunc, onLoopFunc)

		local FlashAnimation = frame:CreateAnimationGroup()

		FlashAnimation.fadeOut = FlashAnimation:CreateAnimation("Alpha") --fade out anime
		FlashAnimation.fadeOut:SetOrder (1)

		FlashAnimation.fadeOut:SetFromAlpha (0)
		FlashAnimation.fadeOut:SetToAlpha (1)

		FlashAnimation.fadeIn = FlashAnimation:CreateAnimation("Alpha") --fade in anime
		FlashAnimation.fadeIn:SetOrder (2)
		FlashAnimation.fadeIn:SetFromAlpha (0)
		FlashAnimation.fadeIn:SetToAlpha (1)

		frame.FlashAnimation = FlashAnimation
		FlashAnimation.frame = frame
		FlashAnimation.onFinishFunc = onFinishFunc

		FlashAnimation:SetScript("OnLoop", onLoopFunc)
		FlashAnimation:SetScript("OnFinished", onFinish)

		frame.Flash = flash
		frame.Stop = stop

	end

	--todo: remove the function creation everytime this function run.



	local fade_OUT_finished_func = function(frame)
		if (frame:IsShown() and frame.fading_out) then
			frame.hidden = false
			frame.faded = false
			frame.fading_out = false
		else
			frame:SetAlpha(0)
		end
	end

	local just_fade_func = function(frame)
		frame.hidden = false
		frame.faded = true
		frame.fading_in = false
	end

	local anim_OUT_alpha_func = function(frame)
		frame.fading_out = false
	end

	local anim_IN_alpha_func = function(frame)
		frame.fading_in = false
	end


	--this functions should be called anymore
	function gump:Fade (frame, tipo, velocidade, parametros)

		a = a + 1 --throw an error if called

		if (type(frame) == "table") then

			if (frame.meu_id) then --ups, � uma inst�ncia
				if (parametros == "barras") then --hida todas as barras da inst�ncia
					if (velocidade) then
						for i = 1, frame.rows_created, 1 do
							Details.FadeHandler.Fader(frame.barras[i], tipo, velocidade)
						end
						return
					else
						velocidade = velocidade or 0.3
						for i = 1, frame.rows_created, 1 do
							Details.FadeHandler.Fader(frame.barras[i], tipo, 0.3+(i/10))
						end
						return
					end
				elseif (parametros == "hide_barras") then --hida todas as barras da inst�ncia
					for i = 1, frame.rows_created, 1 do
						local esta_barra = frame.barras[i]
						if (esta_barra.fading_in or esta_barra.fading_out) then
							esta_barra.fadeInfo.finishedFunc = nil
--							_UIFrameFadeIn (esta_barra, 0.01, esta_barra:GetAlpha(), esta_barra:GetAlpha())
						end
						esta_barra.hidden = true
						esta_barra.faded = true
						esta_barra.fading_in = false
						esta_barra.fading_out = false
						esta_barra:Hide()
						esta_barra:SetAlpha(0)
					end
					return
				end
			elseif (frame.dframework) then
				frame = frame.widget
			end
		end

		velocidade = velocidade or 0.3

		--esse ALL aqui pode dar merda com as inst�ncias n�o ativadas
		if (frame == "all") then --todas as inst�ncias
			for _, instancia in ipairs(_detalhes.tabela_instancias) do
				if (parametros == "barras") then --hida todas as barras da inst�ncia
					for i = 1, instancia.rows_created, 1 do
						Details.FadeHandler.Fader(instancia.barras[i], tipo, velocidade+(i/10))
					end
				end
			end

		elseif (upper (tipo) == "IN") then

			if (frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out) then --ja esta escondida
				return
			elseif (frame.fading_in) then --ja esta com uma anima��o, se for true
				return
			end

			if (frame.fading_out) then --se tiver uma anima��o de aparecer em andamento se for true
				frame.fading_out = false
			end

--			_UIFrameFadeIn (frame, velocidade, frame:GetAlpha(), 0)
			frame.fading_in = true

			frame.fadeInfo.finishedFunc = fade_IN_finished_func
			frame.fadeInfo.finishedArg1 = frame

		elseif (upper (tipo) == "OUT") then --aparecer

			if (frame:GetAlpha() == 1 and not frame.hidden and not frame.fading_in) then --ja esta na tela
				return
			elseif (frame.fading_out) then --j� ta com fading out
				return
			end

			if (frame.fading_in) then --se tiver uma anima��o de hidar em andamento se for true
				frame.fading_in = false
			end

			frame:Show()
--			_UIFrameFadeOut (frame, velocidade, frame:GetAlpha(), 1.0)
			frame.fading_out = true

			frame.fadeInfo.finishedFunc = fade_OUT_finished_func
			frame.fadeInfo.finishedArg1 = frame

		elseif (tipo == 0) then --for�a o frame a ser mostrado
			frame.hidden = false
			frame.faded = false
			frame.fading_out = false
			frame.fading_in = false
			frame:Show()
			frame:SetAlpha(1)

		elseif (tipo == 1) then --for�a o frame a ser hidado
			frame.hidden = true
			frame.faded = true
			frame.fading_out = false
			frame.fading_in = false
			frame:SetAlpha(0)
			frame:Hide()

		elseif (tipo == -1) then --apenas da fade sem hidar
			if (frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out) then --ja esta escondida
				return
			elseif (frame.fading_in) then --ja esta com uma anima��o, se for true
				return
			end

			if (frame.fading_out) then --se tiver uma anima��o de aparecer em andamento se for true
				frame.fading_out = false
			end

--			_UIFrameFadeIn (frame, velocidade, frame:GetAlpha(), 0)
			frame.fading_in = true
			frame.fadeInfo.finishedFunc = just_fade_func
			frame.fadeInfo.finishedArg1 = frame

		elseif (upper (tipo) == "ALPHAANIM") then

			local value = velocidade
			local currentApha = frame:GetAlpha()
			frame:Show()

			if (currentApha < value) then
				if (frame.fading_in) then --se tiver uma anima��o de hidar em andamento se for true
					frame.fading_in = false
					frame.fadeInfo.finishedFunc = nil
				end
--				_UIFrameFadeOut (frame, 0.3, currentApha, value)
				frame.fading_out = true

				frame.fadeInfo.finishedFunc = anim_OUT_alpha_func
				frame.fadeInfo.finishedArg1 = frame

			else
				if (frame.fading_out) then --se tiver uma anima��o de hidar em andamento se for true
					frame.fading_out = false
					frame.fadeInfo.finishedFunc = nil
				end
--				_UIFrameFadeIn (frame, 0.3, currentApha, value)
				frame.fading_in = true

				frame.fadeInfo.finishedFunc = anim_IN_alpha_func
				frame.fadeInfo.finishedArg1 = frame
			end

		elseif (upper (tipo) == "ALPHA") then --setando um alpha determinado
			if (frame.fading_in or frame.fading_out) then
				frame.fadeInfo.finishedFunc = nil
--				_UIFrameFadeIn (frame, velocidade, frame:GetAlpha(), frame:GetAlpha())
			end
			frame.hidden = false
			frame.faded = false
			frame.fading_in = false
			frame.fading_out = false
			frame:Show()
			frame:SetAlpha(velocidade)
		end
	end

	function _detalhes:name_space (barra)
		--if (barra.icone_secundario_ativo) then
		--	local tamanho = barra:GetWidth()-barra.lineText4:GetStringWidth()-16-barra:GetHeight()
		--	barra.lineText1:SetSize(tamanho-2, 15)
		--else
			barra.lineText1:SetSize(barra:GetWidth()-barra.lineText4:GetStringWidth()-18, 15)
		--end
	end

	function _detalhes:name_space_info (barra)
		if (barra.icone_secundario_ativo) then
			local tamanho = barra:GetWidth()-barra.lineText4:GetStringWidth()-16-barra:GetHeight()
			barra.lineText1:SetSize(tamanho-10, 15)
		else
			local tamanho = barra:GetWidth()-barra.lineText4:GetStringWidth()-16
			barra.lineText1:SetSize(tamanho-10, 15)
		end
	end

	function _detalhes:name_space_generic (barra, separador)
		local texto_direita_tamanho = barra.lineText4:GetStringWidth()
		local tamanho = barra:GetWidth()-texto_direita_tamanho-16
		if (separador) then
			barra.lineText1:SetSize(tamanho+separador, 10)
			barra.lineText4:SetSize(texto_direita_tamanho+15, 10)
		else
			barra.lineText1:SetSize(tamanho-10, 15)
			barra.lineText4:SetSize(texto_direita_tamanho+5, 15)
		end
	end
