--[[

    DS9 Utilities - Rules List
    -----------------------------
    Whenever invoked by a player, will read from the rules file and
    output the text found therein. Each newline corresponds to a *new* rule, so
    lines can be as long as you like.

    Licensed under the "BSD-3-Clause" license

]]

do
    local __old_path = package.path
    package.path = package.path .. ";data/scripts/lib/?.lua"

    include("utility")
    include("stringutility")
    include("weapontype")

    local __file=Server().folder .. "/RulesList.txt"
    local __name='rules'
    local __desc="Output the server rules"
    local __usage=''

    local function __does_file_exist(name)
        local f=io.open(name,"r")
        if f~=nil then io.close(f) return true else return false end
    end

    local function __strip_leading_chars(str, chars)
        local __newstr = str
        -- Default to whitespace if an invalid input is provided (or is nil)
        if type(chars) ~= "string" then
            chars=" \t"
        end

        for i=1, #str do
            local c

            for ch_i=1, #chars do
                c = chars:sub(ch_i, ch_i)
                print("Testing for <${c}>"%_T % {c=c})
                if str:sub(1,1) == c then
                    str = str:sub(2,-1)
                    print("Found and stripped char: <${c}>"%_T % {c=c})
                    i = i - 1 --Make sure to deiterate
                elseif ch_i >= #chars and i > 0 then
                    return str
                end
            end
        end

        return str
    end

    function execute(sender, commandName, modName, ...)
        print("\nNEW RULES OUTPUT\n")

        local args = {...}
        local response = ""

        if __does_file_exist(__file) then
            local c = 0
            for l in io.lines(__file) do
                local __resp = false
                print("Operating on new line: <${l}>"%_T % {l=l})

                l = __strip_leading_chars(l)

                if type(l) == "nil" or l == "" or string.sub(l,1,1) == ";" then
                    -- Stubbed. Lua has no continue statement so this has to
                    -- remain. It makes me sad inside :/
                    -- Anyway, this catches empty lines, lines filled with
                    -- whitespace that were blanked out, and comments.

                elseif string.sub(l,1,1) == "#" then
                    l = __strip_leading_chars(l, "# \t")
                    __resp = "${r}\n"%_T % {c=c,r=l}

                elseif string.sub(l,1,1) == "-" or string.sub(l,1,1) == "+" then
                    l = __strip_leading_chars(string.sub(l,2,-1))
                    __resp = "    - ${r}\n"%_T % {c=c, r=l}

                else
                    c = c + 1
                    __resp = "${c}: ${r}\n"%_T % {c=c, r=l}
                end

                -- Debug (tostring here to prevent nils from breaking this)
                print("Outputting: <"..(__resp and __resp or "NO OUTPUT")..">")
                response = (__resp and response .. __resp or response)
            end
        else
            return 1, "No rules defined!", "No rules defined in <${f}>"%_T % {f=__file}
        end

        return 0, response, ""
    end

    function getDescription()
        return __desc.."."
    end

    function getHelp()
        return "${d}. Usage: /${n} ${u}"%_T % {d=__desc, n=__name, u=__usage}
    end

    package.path = __old_path
end