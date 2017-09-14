M = {}

--utility function: split string into table based on delimiter
--credit: https://helloacm.com/split-a-string-in-lua/
function M.split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

return M