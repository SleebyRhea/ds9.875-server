do
    local __oldpath = package.path
    package.path = package.path .. ";data/scripts/lib/?.lua"

    include("stringutility")
    include("ds9utils-lib")("ds9utils-sendmail")

    local __err = {
        no_arg = "Please provide an argument",
        bad_arg = "Please provide a valid argument"
    }

    local __modinfo = {
        i_modname = "ds9utils-commandpack",
        i_commandname = "sendmail",
        i_description = "Sends mail via command (for admin/console use only)",
        i_message_dir = Server().folder .. "/messages"
    }

    local function __sendEmail(sender, __m)
        local __mail = Mail()

        __mail.sender = __m.m_sender
        __mail.header = __m.m_header
        __mail.text   = __m.m_text

        __mail.money = __m.r_credits
        __mail:setResources(
            __m.r_iron,
            __m.r_titanium,
            __m.r_naonite,
            __m.r_trinium,
            __m.r_xanion,
            __m.r_ogonite,
            __m.r_avorion
        )

        for __id, v in ipairs(__m.m_rcpt) do
            Player(__id):addMail(__mail)
        end

        return 0, "Sent ${n} players email."%_T % {n=#__m.m_rcpt}, ""
    end

    -- Gets the real table length. Used as # only returns the last index, not
    -- necessarily the true length of a table
    local function __getTblLen(__tbl)
        local c = 0
        for _, _ in pairs(__tbl) do c=c+1 end
        return c
    end

    local __addAllPlayersData = {
        description = "Add all players the the recipients list",
        usage = false,
        func = function (__data, __d)
            return false, "Emailing all players is unimplemented at this time"
        end,
    }

    local __addPlayerData = {
        description = "Adds a player to the recipients list",
        usage = "playername",
        func = function (__data, ...)
            for _, __id  in ipairs({...}) do
                table.insert(__data.m_rcpt, __id)
            end
        end,
    }

    local __addResourceData = {
        description = "Add resources to an email",
        usage = "resourcename amount",
        func = function (__data, __res, __cnt, ...)
            if ... then
                return false, "Too many inputs given"
            end

            if not type(__res) == "string" or not __data["r_"..__res] then
                return false, "Resource name is invalid: <${res}>"%_T % {res=tostring(__res)}
            end

            if type(__cnt) == "string" then
                __cnt = ( tonumber(__cnt) or nil )
            end

            if not __cnt then
                return false, "Please provide a valid amount for resource <${res}>"%_T % {res=__res}
            end

            __data["r_"..__res] = __cnt
            return true, "Sent ${amount} ${res}"%_T % {amount=__cnt, res=__res}
        end,
    }

    local __setHeaderData = {
        description = "Set the subject line of the message",
        usage = "string",
        func = function(__d)
        end,
    }

    local __setFileData = {
		description = "Specify the file (stored in "..
			__modinfo.i_message_dir..
			") to use for the email",
		usage = "filename",
        func = function (fileName)
        end,
    }

    local __setTextData = {
        description = "Specify the message to be sent",
		usage = "message",
        func = function (text)
        end,
    }

    -- Returns a table with the available commands and their mapped
    -- functions IF the user of the command is permitted to use it
    -- Adding command availability is done this way rather than being
    -- static to make it easier later on to implement an ACL-esque system
    -- should it ever become necessary. Also makes it easier to handle
    -- usage and description text without needing to write duplicate code
    local function __getAvailableArguments(sender)
        local __data = {}
		__data["-p"] = __addPlayerData
		__data["-f"] = __setFileData
		__data["-m"] = __setTextData
		__data["-h"] = __setHeaderData
		__data["-b"] = __addAllPlayersData
		__data["-r"] = __addResourceData
		return __data, nil
    end

    function getDescription(sender)
        return __modinfo.i_description
    end

    function getHelp(sender)
		local __usage = ""
        local __valid_arguments, err = __getAvailableArguments(sender)
        if err then
			print(err)
            return 1, "", err
        end

		for k,v in pairs(__valid_arguments) do
			print("Processing: "..k)
			__usage = __usage .. k ..
				": <" .. (v.usage and v.usage or "none") .. ">\n\t" ..
				v.description .. "\n"
		end

		return "Usage: ${c} <option> <parameter>\nOptions:\n${u}"%_T % {
            c=__modinfo.i_commandname,
            u=__usage
        }
    end

    function execute(sender, commandName, ...)
        if not ... then
            return 1, "", __err.no_arg
        end

        -- If an error is received, cancel the command and return it
        local __valid_arguments, err = __getAvailableArguments(sender)
        if err then
            return 1, "", err
        end

        -- Initilize our message data now that we know the user is authorized
        local __arg_map = {}
        local __msg = {
            -- Message data
            m_header    = "Test Message",
            m_sender    = "Server",
            m_text      = "Test message please ignore.",
            m_rcpt      = {},

            -- Resources
            r_credits   = 0,
            r_iron      = 0,
            r_titanium  = 0,
            r_naonite   = 0,
            r_trinium   = 0,
            r_xanion    = 0,
            r_ogonite   = 0,
            r_avorion   = 0,

            -- Execution Flags
            f_do_resources_send = false,
        }

        do
            local __in_cmd = false
            local __command_data = {...}

            repeat
                local v = table.remove(__command_data)

                if type(__valid_arguments[v]) == "nil" and not __in_cmd then
                    return 1, "", __err.no_arg
                elseif type(__valid_arguments[v]) == "table" then
                    __in_cmd=v
                    __arg_map[__in_cmd] = {}
                else
                    table.insert(__arg_map[__in_cmd], v)
                end
            until __getTblLen(__command_data) < 1
        end

        if type(unpack) == "nil" then
            return 1, "", "That command is not usable with this version of Avorion!"
        end

        for k, v in pairs(__arg_map) do
			print("Running: " .. k)
            _, err = __valid_arguments[k].func(unpack(v))
			if err then
				return 1, "", err
			end
        end

        if __getTblLen(__msg.m_rcpt) < 1 then
            return 1, "", "Please supply a recipient"
        end

        return __sendEmail(__msg)
    end

    package.path = __oldpath
end
