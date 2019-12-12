package.path = package.path .. ";data/scripts/lib/?.lua"

function getDescription()
    return "Sends mail via command."
end

function getHelp()
    return "For us via Console Only."
end

do
    local function __send_email(__id, __m)
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

    local function __add_all_players(__rcpt, __d)
        if Server():sender
    end

    local function __add_player(__rcpt, __d)
        if __rcpt == "+all" then
            return __add_all_players()
        end

        for _, __id  in ipairs(__d) do
            table.insert(__rcpt, __id)
        end
    end

    local function __add_resource(__msg, __res, __cnt)
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

    local __mapped_options = {
        "-p" = __add_player,
        "-r" = __add_resource,
        "-f" = __set_message_file
    }

    function execute(sender, commandName, ...)
        -- Make sure that we have a set of recipients
        if not ... then
            return 1, "", getHelp() 
        end

        -- Initilize our message data
        local __rcpt = {}
        local __msg = {
            -- Message data
            m_header     = ( __subject or "Test Message"),
            m_sender     = ( __from or "Server"),
            m_text       = ( __text or "Test message please ignore."),

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

        do
            local __command_data = {}
            for i, v in ipairs({...}) do
                if not 
            end
        end

        if __get_tbl_len(__rcpt) < 1 then
            return 1, "Please supply a valid recipient"
        end

        for i, __id in ipairs(__rcpt) do
            __send_email(__id, __msg)
        end        

        return 0, "", ""
    end
end