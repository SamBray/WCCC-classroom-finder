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

--for a centered image, determine of the desired margin is too big. 
--if so, return max width and height, else return scaled width and height
function M.getCenteredImageSize(maxWidth, maxHeight, margin)
	local width, height
	if maxWidth < display.contentWidth - margin * 2 then
		width = maxWidth
		height = maxHeight
	else
		width = display.contentWidth - margin * 2
		height = maxHeight * (width / maxWidth)
	end
	return width, height
end

M.debugText = "ClassroomFinderOutput: "

return M