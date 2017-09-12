
local composer = require( "composer" )
local widget = require( "widget" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local textColor = {0,0,0}
local backgroundColor = {1,1,1}
local accentColor = {0,0,0}
local selectedColor = {30/255,190/255,224/255}
local overColor = {0,0,.6, .2}

local classroomTable = {}
local entranceTable = {}
local buildingTable = {}

local buildingTableView
local oldBuildingRow

local classroomTableView
local oldClassroomRow
local classroomSelectText

local goButton
--utility function: split string into table based on delimiter
--credit: https://helloacm.com/split-a-string-in-lua/
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

--file reading functions
local function readBuildings()
	local filePath = system.pathForFile("res/buildings.data")
	local file, errorString = io.open(filePath, "r")
	
	if not file then
		print("File error: "..errorString)
	else
		for line in file:lines() do
			local currentIndex = #buildingTable + 1
			local tokens = split(line, ",")
			buildingTable[currentIndex] = {}
			buildingTable[currentIndex].name = tokens[1]
			buildingTable[currentIndex].data = tokens[2]
			buildingTable[currentIndex].image = tokens[3]
			buildingTable[currentIndex].width = tonumber(tokens[4])
			buildingTable[currentIndex].height = tonumber(tokens[5])
			buildingTable[currentIndex].id = split(tokens[2],"%.")[1]
		end
		io.close(file)
		
		--sort the buildings
		local function compare(a,b)
			return a.name < b.name
		end
		table.sort(buildingTable, compare)
	end
end

--function to read in entrance and classroom data
local function readBuildingInfo(buildingID, buildingFile)
	local filePath = system.pathForFile("res/"..buildingFile)
	local file, errorString = io.open(filePath, "r")
	
	if not file then
		print("File error: "..errorString)
	else
		classroomTable[buildingID] = {}
		entranceTable[buildingID] = {}
		local mode
		local index
		for line in file:lines() do
			if line == "" then
				--skip
			elseif line == "!classroom" then
				--set read mode to classroom
				mode = "classroom"
				index = 1
			elseif line == "!entrance" then
				--set read mode to entrance
				mode = "entrance"
				index = 1
			elseif mode == "classroom" then
				--reading a classroom
				local tokens = split(line, ",")
				classroomTable[buildingID][index] = {}
				classroomTable[buildingID][index].name = tokens[1]
				classroomTable[buildingID][index].x = tonumber(tokens[2])
				classroomTable[buildingID][index].y = tonumber(tokens[3])
				index = index + 1
			else
				--reading an entrance
				local tokens = split(line, ",")
				entranceTable[buildingID][index] = {}
				entranceTable[buildingID][index].x = tonumber(tokens[1])
				entranceTable[buildingID][index].y = tonumber(tokens[2])
				entranceTable[buildingID][index].latitude = tonumber(tokens[3])
				entranceTable[buildingID][index].longitude = tonumber(tokens[4])
				index = index + 1
			end
		end
		--sort the classrooms
		local function compare(a,b)
			return a.name < b.name
		end
		table.sort(classroomTable[buildingID], compare)
	end
end

--functions for classroom tableview
local function populateClassroomTableView(buildingID)
	classroomTableView:deleteAllRows()
	local rowHeight = 40
	local rowColor = { default=backgroundColor, over=overColor }
	local lineColor = accentColor
	local classrooms = classroomTable[buildingID]
	for i = 1, #classrooms do
		classroomTableView:insertRow({
			rowHeight = rowHeight,
			rowColor = rowColor,
			lineColor = lineColor,
			params = classrooms[i]})
	end
end

local function onClassroomRowRender(event)
	local row = event.row
	local params = event.row.params
	
	local rowHeight = row.contentHeight
	local rowWidth = row.contentWidth
	
	local rowTitle = display.newText(row, params.name, 20, rowHeight * 0.5, native.systemFont, 16)
	rowTitle:setFillColor(textColor)
	rowTitle.anchorX = 0
end

local function onClassroomRowTouch(event)
	local row = event.target
	local params = row.params
	if event.phase == "tap" or event.phase == "press" then
		if oldClassroomRow ~= nil and oldClassroomRow.index ~= row.index then
			--print("Old row index: "..oldBuildingRow.index)
			oldClassroomRow:setRowColor({default = backgroundColor, over = overColor})
			classroomTableView:reloadData()
		end
		row:setRowColor({default = selectedColor, over = overColor})
		--classroomTableView:reloadData()
		oldClassroomRow = row
	end
	goButton.isVisible = true
end

--functions for building tableview
local function populateBuildingTableView()
	local rowHeight = 40
	local rowColor = { default=backgroundColor, over=overColor }
	local lineColor = accentColor
	
	for i = 1, #buildingTable do
		buildingTableView:insertRow({
			rowHeight = rowHeight,
			rowColor = rowColor,
			lineColor = lineColor,
			params = buildingTable[i]})
	end
end

local function onBuildingRowRender(event)
	local row = event.row
	local params = event.row.params
	
	local rowHeight = row.contentHeight
	local rowWidth = row.contentWidth
	
	local rowTitle = display.newText(row, params.name, 20, rowHeight * 0.5, native.systemFont, 16)
	rowTitle:setFillColor(textColor)
	rowTitle.anchorX = 0
end

local function onBuildingRowTouch(event)
	local row = event.target
	local params = row.params
	if event.phase == "tap" or event.phase == "press" then
		--if required, read in classroom and entrance data for the building
		if classroomTable[params.id] == nil then
			readBuildingInfo(params.id, params.data)
		end
		--change row colors
		if oldBuildingRow ~= nil and oldBuildingRow.index ~= row.index then
			--print("Old row index: "..oldBuildingRow.index)
			oldBuildingRow:setRowColor({default = backgroundColor, over = overColor})
			buildingTableView:reloadData()
		end
		row:setRowColor({default = selectedColor, over = overColor})
		oldBuildingRow = row
		
		--populate classroom selector
		classroomSelectText.isVisible = true
		populateClassroomTableView(params.id)
	end
end

--handle go button
local function goToMap(event)
	--calculate the closest entrance
	local lat,long = 200,200
	local bestDistance = math.huge
	local bestEntrance = 0
	local currentBuilding = oldBuildingRow.params.id
	for index = 1, #(entranceTable[currentBuilding]) do
		local dist = math.sqrt((lat - entranceTable[currentBuilding][index].latitude)^2 + (long - entranceTable[currentBuilding][index].longitude)^2)
		if dist < bestDistance then
			bestDistance = dist
			bestEntrance = index
		end
	end
	
	--set up table for map
	local mapTable = {}
	mapTable.mapFile = oldBuildingRow.params.image
	mapTable.mapHeight = oldBuildingRow.params.height
	mapTable.mapWidth = oldBuildingRow.params.width
	mapTable.classroomX = oldClassroomRow.params.x
	mapTable.classroomY = oldClassroomRow.params.y
	mapTable.entranceX = entranceTable[currentBuilding][bestEntrance].x
	mapTable.entranceY = entranceTable[currentBuilding][bestEntrance].y
	composer.setVariable("mapTable", mapTable)
	
	composer.gotoScene("map", { time=800, effect="crossFade" })
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	--read in the building data
	readBuildings()

	--set up GUI
	--set background
	local background = display.newImageRect(sceneGroup, "res/MapBackground.png", 1500, 1500)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	--create building items
	local buildingSelectText = display.newText(sceneGroup, "Select Building:", display.contentCenterX, 30, native.systemFont, 30)
	buildingSelectText:setFillColor(textColor)
	
	buildingTableView = widget.newTableView({
		x = display.contentCenterX,
		y = 130,
		height = 120,
		width = display.contentWidth - 50,
		onRowRender = onBuildingRowRender,
		onRowTouch = onBuildingRowTouch
	})
	sceneGroup:insert(buildingTableView)
	populateBuildingTableView()
	
	--create classroom buttons
	classroomSelectText = display.newText(sceneGroup, "Select Classroom:", display.contentCenterX, 240, native.systemFont, 30)
	classroomSelectText:setFillColor(textColor)
	classroomSelectText.isVisible = false
	
	--create classroom tableview
	classroomTableView = widget.newTableView({
		x = display.contentCenterX,
		y = 350,
		height = 160,
		width = display.contentWidth - 50,
		onRowRender = onClassroomRowRender,
		onRowTouch = onClassroomRowTouch
	})
	sceneGroup:insert(classroomTableView)
	
	--create go button
	goButton = display.newText(sceneGroup, "Go!", display.contentCenterX, display.contentHeight - 20, native.systemFont, 30)
	goButton:setFillColor(textColor)
	goButton:addEventListener("tap", goToMap)
	goButton.isVisible = false
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		composer.removeScene("classroomMenu")
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
