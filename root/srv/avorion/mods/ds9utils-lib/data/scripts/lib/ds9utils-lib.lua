-- Print override for timestamps
do
    local __vanilla_print = _G.print
    function _G.print(...)
        io.write("(" .. os.date("%Y-%m-%d %H:%M:%S") .. ") ")
        return __vanilla_print(...)
    end
end

