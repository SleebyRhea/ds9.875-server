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
    include("ds9utils-lib")

    local __file  = Server().folder .. "/RulesList.txt"
    local __name  = 'rules'
    local __mod   = "ds9utils-welcomeemail"
    local __desc  = "Output the server rules"
    local __usage = ''

    local function __does_file_exist(name)
        local f=io.open(name,"r")
        if f~=nil then io.close(f) return true else return false end
    end

    function execute(sender, commandName, modName, ...)
        print("\nNEW RULES OUTPUT\n")

        local args = {...}
        local response = ""

        if not __does_file_exist(__file) then
            print("[${mod}] No rules defined in <${f}>"%_T % {mod=__mod, f=__file})
            return 1, "", "No rules defined!"
        end

        local c = 0
        for l in io.lines(__file) do
            local __resp = false

            l = string.gsub(l, "^%s*(.-)%s*$", "%1")

            if type(l) == "nil" or l == "" or string.sub(l,1,1) == ";" then
                -- Stubbed. Lua has no continue statement so this has to
                -- remain. It makes me sad inside :/
                -- Anyway, this catches empty lines, lines filled with
                -- whitespace that were blanked out, and comments.

            elseif string.sub(l,1,1) == "#" then
                l = string.gsub(l, "^%s*#*%s*(.-)%s*$", "%1")
                __resp = "${r}\n"%_T % {c=c,r=l}

            elseif string.sub(l,1,1) == "-" or string.sub(l,1,1) == "+" then
                l = string.gsub(string.sub(l,2,-1), "^%s*[-+]*%s*(.-)%s*$", "%1")
                __resp = "    - ${r}\n"%_T % {c=c, r=l}

            else
                c = c + 1
                __resp = "${c}: ${r}\n"%_T % {c=c, r=l}
            end

            response = (__resp and response .. __resp or response)
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