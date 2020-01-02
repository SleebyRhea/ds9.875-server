-- Print override for timestamps
do
    local __vanilla_print = _G.print
    function _G.print(...)
        io.write("(" .. os.date("%H:%M:%S %m-%d-%Y") .. ")> ")
        return __vanilla_print(...)
    end
end

