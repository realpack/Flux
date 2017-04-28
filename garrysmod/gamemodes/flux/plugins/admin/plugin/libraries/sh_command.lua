--[[
	Flux © 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before
	the framework is publicly released.
--]]

library.New("command", fl)
local stored = fl.command.stored or {}
local aliases = fl.command.aliases or {}
fl.command.stored = stored
fl.command.aliases = aliases

function fl.command:Create(id, data)
	if (!id or !data) then return end

	data.uniqueID = id:MakeID()
	data.name = data.name or "Unknown"
	data.description = data.description or "An undescribed command."
	data.syntax = data.syntax or "[none]"
	data.immunity = data.immunity or false
	data.playerArg = data.playerArg or nil
	data.arguments = data.arguments or 0

	stored[id] = data

	-- Add original command name to aliases table.
	aliases[id] = data.uniqueID

	if (data.aliases) then
		for k, v in ipairs(data.aliases) do
			aliases[v] = id
		end
	end

	fl.admin:PermissionFromCommand(data)
end

function fl.command:FindByID(id)
	id = id:utf8lower()

	if (stored[id]) then return stored[id] end
	if (aliases[id]) then return stored[aliases[id]] end
end

function fl.command:Find(id)
	id = id:utf8lower()

	local found = self:FindByID(id)

	if (found) then
		return found
	end

	for k, v in pairs(aliases) do
		if (k:find(id)) then
			return stored[v]
		end
	end
end

-- A function to find all commands by given search string.
function fl.command:FindAll(id)
	local hits = {}

	for k, v in pairs(aliases) do
		if (k:find(id) or v:find(id)) then
			table.insert(hits, v)
		end
	end

	return hits
end

function fl.command:ExtractArguments(text)
	local arguments = {}
	local word = ""
	local skip = 0

	for i = 1, #text do
		if (skip > 0) then
			skip = skip - 1

			continue
		end

		local char = text:utf8sub(i, i)

		if ((char == "\"" or char == "'") and word == "") then
			local endPos = text:find("\"", i + 1)

			if (!endPos) then
				endPos = text:find("'", i + 1)
			end

			if (endPos) then
				table.insert(arguments, text:utf8sub(i + 1, endPos - 1))

				skip = endPos - i
			else
				word = word..char
			end
		elseif (char == " ") then
			if (word != "") then
				table.insert(arguments, word)
				word = ""
			end
		else
			word = word..char
		end
	end

	if (word != "") then
		table.insert(arguments, word)
	end

	return arguments
end

if (SERVER) then
	function fl.command:Interpret(player, text)
		local args

		if (istable(text)) then
			args = text
		else
			args = self:ExtractArguments(text)
		end

		local command = args[1]:utf8lower()

		table.remove(args, 1)

		local cmdTable = self:FindByID(command)

		if (cmdTable) then
			if ((!IsValid(player) and !cmdTable.noConsole) or player:HasPermission(cmdTable.uniqueID)) then
				if (cmdTable.arguments == 0 or cmdTable.arguments <= #args) then
					if (cmdTable.immunity or cmdTable.playerArg != nil) then
						local targetArg = args[(cmdTable.playerArg or 1)]
						local target = _player.Find(targetArg)

						if (IsValid(target)) then
							if (cmdTable.immunity and !fl.admin:CheckImmunity(player, target, cmdTable.canBeEqual)) then
								fl.player:Notify(player, L("Commands_HigherImmunity", target:Name()))

								return
							end

							-- One step less for commands.
							args[cmdTable.playerArg or 1] = target
						else
							if (IsValid(player)) then
								fl.player:Notify(player, L("Commands_PlayerInvalid", targetArg))
							else
								ErrorNoHalt("'"..targetArg.."' is not a valid player!\n")
							end

							return
						end
					end

					-- Let plugins hook into this and abort command's execution if necessary.
					if (!hook.Run("PlayerRunCommand", player, cmdTable, args)) then
						if (IsValid(player)) then
							ServerLog(player:Name().." has used /"..cmdTable.name.." "..text:utf8sub(cmdTable.name:utf8len() + 2, text:utf8len()))
						end

						self:Run(player, cmdTable, args)
					end
				else
					fl.player:Notify(player, "/"..cmdTable.name.." "..cmdTable.syntax)
				end
			else
				if (IsValid(player)) then
					fl.player:Notify(player, "#Commands_NoAccess")
				else
					ErrorNoHalt("[Flux] This command cannot be run from console!\n")
				end
			end
		else
			if (IsValid(player)) then
				fl.player:Notify(player, L("Commands_NotValid", command))
			else
				ErrorNoHalt("'"..command.."' is not a valid command!\n")
			end
		end
	end

	-- Warning: this function assumes that command is valid and all permission checks have been done.
	function fl.command:Run(player, cmdTable, arguments)
		if (cmdTable.OnRun) then
			local success, result = pcall(cmdTable.OnRun, cmdTable, player, unpack(arguments))

			if (!success) then
				ErrorNoHalt("[Flux] "..cmdTable.uniqueID.." command has failed to run!\n")
				ErrorNoHalt(result.."\n")
			end
		end
	end
end

concommand.Add("flCmd", function(player, cmd, args)
	fl.command:Interpret(player, args)
end)

concommand.Add("flc", function(player, cmd, args)
	fl.command:Interpret(player, args)
end)