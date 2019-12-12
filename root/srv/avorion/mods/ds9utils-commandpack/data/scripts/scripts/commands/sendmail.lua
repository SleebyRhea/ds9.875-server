package.path = package.path .. ";data/scripts/lib/?.lua"

local __err = {
    no_arg = "Please provide an argument",
}

local __modinfo = {
    i_modname = "ds9utils-commandpack",
    i_commandname = "sendmail",
}

function getDescription()
    return "Sends mail via command."
end

function getHelp()
    return "For us via Console Only."
end

do
    local function __sendEmail(__id, __m)
        local __plr = Player(sender)
        local __mail = Mail()

        __mail.sender = __m.m_sender
        __mail.header = __m.m_header
        __mail.text = __m.m_text

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

        __plr:addMail(mail)
    end

    local function __getTblLen(__tbl)
        local c = 0
        for _, _ in pairs(__tbl) do c=c+1 end
        return c
    end

    local function __addAllPlayers(__rcpt, __d)
        if Server():hasAdminPrivileges(sender) then
        end
    end

    local function __addPlayer(__rcpt, __d)
        if __rcpt == "+all" then
            return __add_all_players()
        end

        for _, __id  in ipairs(__d) do
            table.insert(__rcpt, __id)
        end
    end

    local function __addResource(__msg, __res, __cnt)
        if not type(__res) == "string" or not __msg["r_"..__res] then
            return false, "Resource name is invalid: <${res}>"%_T % {res=tostring(__res)}
        end

        if type(__cnt) == "string" then
            __cnt = ( tonumber(__cnt) or nil )
        end

        if not __cnt then
            return false, "Please provide a valid amount for resource <${res}>"%_T % {res=__res}
        end

        __msg["r_"..__res] = __cnt
        return true, "Sent ${amount} ${res}"%_T % {amount=__cnt, res=__res}
    end

    local function __setHeader(__d)
    end

    local function __setFile()
    end

    local function __setText()
    end

    -- Returns a table with the available commands and their mapped
    -- functions IF the user of the command is permitted to use it
    local function __getAvailableArguments(sender)
        local PERMITTED = false
        local __server = Server()
        local __sender = Player(sender)
        
        local __data = {
            __args = {},
            __func_map = {}
        }

        if __server:hasAdminPrivileges(__sender) then
            PERMITTED = true

            table.insert(__data.__args, "-p", "Adds a player")
            table.insert(__data.__args, "-f", "Specify the file (stored in ${dir} to use for the email"%_T % {dir=})
        elseif 

        -- Only return if the user has permission to even use
        -- this command in the first place
        return ( PERMITTED and __data or false )
    end

    function execute(sender, commandName, ...)
        if not ... then
            return 1, "", __err.no_arg 
        end

        -- Initilize our message data
        local __rcpt = {}
        local __msg = {
            -- Message data
            m_header     = "Test Message",
            m_sender     = "Server",
            m_text       = "Test message please ignore.",

            -- Resources
            r_credits    = 0,
            r_iron       = 0,
            r_titanium   = 0,
            r_naonite    = 0,
            r_trinium    = 0,
            r_xanion     = 0,
            r_ogonite    = 0,
            r_avorion    = 0,
            
            -- Execution Flags
            f_do_resources_send = false,
        }

        local __valid_arguments = __getAvailableArguments(sender)

        do
            local __command_data = {}
            for i, v in ipairs({...}) do
                if not 
            end
        end

        if __getTblLen(__rcpt) < 1 then
            return 1, "Please supply a valid recipient"
        end

        for i, __id in ipairs(__rcpt) do
            __sendEmail(__id, __msg)
        end        

        return 0, "", ""
    end
end