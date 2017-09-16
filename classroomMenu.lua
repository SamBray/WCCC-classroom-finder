
local composer = require( "composer" )
local widget = require( "widget" )

local theme = require("classes.theme")
local util = require("lib.utility")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local classroomTable = {}
local entranceTable = {}
local buildingTable = composer.getVariable("buildings")

local buildingTableView
local currentBuildingRowIndex
local currentBuilding

local classroomTableView
local currentClassroomRowIndex
local currentClassroom

local classroomSelectText

local goButton

local currentLatitude
local currentLongitude
local gpsTime
local gpsTimeout = 15000

--create GPS listener
local function locationHandler(event)
	if not (event.errorCode) then
		currentLatitude = event.latitude
		currentLongitude = event.longitude
		gpsTime = system.getTimer()
		--print(util.debugText.."GPS Event: Latitude: "..currentLatitude.." Longitude: "..currentLongitude)
	end
end

--function to read in entrance and classroom data
local function readBuildingInfo(buildingID, buildingFile)
	local filePath = system.pathForFile("res/"..buildingFile)
	local file, errorString = io.open(filePath, "r")
	
	if not file then
		print(util.debugText.."File error: "..errorString)
	else
		classroomTable[buildingID] = {}
		entranceTable[buildingID] = {}
		local mode
		for line in file:lines() do
			--if line == "!classroom" then
			local tokens = util.split(line, ",")
			if line:find("!classroom") ~= nil then
				--set read mode to classroom
				mode = "classroom"
			--elseif line == "!entrance" then
			elseif line:find("!entrance") ~= nil then
				--set read mode to entrance
				mode = "entrance"
			elseif #tokens < 3 then
				--skip
			elseif mode == "classroom" then
				--reading a classroom
				if tonumber(tokens[2]) and tonumber(tokens[3]) then
					local index = #classroomTable[buildingID] + 1
					classroomTable[buildingID][index] = {}
					classroomTable[buildingID][index].name = tokens[1]
					classroomTable[buildingID][index].x = tonumber(tokens[2])
					classroomTable[buildingID][index].y = tonumber(tokens[3])
				end
			elseif mode == "entrance" then
				--reading an entrance
				if #tokens >= 4 and tonumber(tokens[1]) and tonumber(tokens[2]) and tonumber(tokens[3]) and tonumber(tokens[4]) then
					local index = #entranceTable[buildingID] + 1
					entranceTable[buildingID][index] = {}
					entranceTable[buildingID][index].x = tonumber(tokens[1])
					entranceTable[buildingID][index].y = tonumber(tokens[2])
					entranceTable[buildingID][index].latitude = tonumber(tokens[3])
					entranceTable[buildingID][index].longitude = tonumber(tokens[4])
				end
			end
		end
		
		--close the file
		file:close()
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
	local rowColor = { default=theme.backgroundColor, over=theme.overColor }
	local lineColor = theme.accentColor
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
	
	--print("Rendering row "..row.index)
	
	
	local rowTitle = display.newText(row, params.name, 20, rowHeight * 0.5, theme.font, 16)
	if rowTitle.setFillColor then
		rowTitle:setFillColor(theme.textColor)
	end
	rowTitle.anchorX = 0
	
	if currentClassroomRowIndex and row.index == (currentClassroomRowIndex) then
		--row:setRowColor({default = theme.selectedColor, over = theme.overColor})
		local checkMark = display.newImageRect( row, "res/checkmark.png", 30, 30 )
		checkMark.x = rowWidth - 30
		checkMark.y = rowTitle.y
	else
		--print("row is not selected")
		--row:setRowColor({default = theme.backgroundColor, over = theme.overColor})
	end
end

local function onClassroomRowTouch(event)
	local row = event.target
	local params = row.params

	if event.phase == "release" then
		--if row.index ~= currentClassroomRowIndex then
			currentClassroomRowIndex = row.index
			currentClassroom = params
			--print("touched row "..row.index)
			classroomTableView:reloadData()
		--end
		goButton.isVisible = true
	end
end

--functions for building tableview
local function populateBuildingTableView()
	local rowHeight = 40
	local rowColor = { default=theme.backgroundColor, over=theme.overColor }
	local lineColor = theme.accentColor
	
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
	
	local rowTitle = display.newText(row, params.name, 20, rowHeight * 0.5, theme.font, 16)
	if rowTitle.setFillColor then
		rowTitle:setFillColor(theme.textColor)
	end
	rowTitle.anchorX = 0
	
	if currentBuildingRowIndex and row.index == (currentBuildingRowIndex) then
		local checkMark = display.newImageRect( row, "res/checkmark.png", 30, 30 )
		checkMark.x = rowWidth - 30
		checkMark.y = rowTitle.y
	end
end

local function onBuildingRowTouch(event)
	local row = event.target
	local params = row.params

	if event.phase == "release" then
		if row.index ~= currentBuildingRowIndex then
			--if required, read in classroom and entrance data for the building
			if classroomTable[params.id] == nil then
				readBuildingInfo(params.id, params.data)
			end
			
			--reset classroom variables
			currentClassroomRowIndex = nil
			currentClassroom = nil
			
			--hide the go button until the user selects a classroom
			goButton.isVisible = false
			
			currentBuildingRowIndex = row.index
			currentBuilding = params
			buildingTableView:reloadData()
			
			--populate classroom selector
			classroomSelectText.isVisible = true
			classroomTableView.isVisible = true
			populateClassroomTableView(params.id)
		end
	end
end

--handle go button
local function goToMap(event)
	--set up table for map except for entrance info
	local mapTable = {}
	mapTable.mapFile = currentBuilding.image
	mapTable.mapHeight = currentBuilding.height
	mapTable.mapWidth = currentBuilding.width
	mapTable.classroomX = currentClassroom.x
	mapTable.classroomY = currentClassroom.y
	
	if currentLatitude == nil or currentLongitude == nil then
		--no GPS data is currently available - leave mapTable.entranceX and Y as nil and set gpsStatus
		composer.setVariable("mapTable", mapTable)
		composer.setVariable("gpsStatus", "none")
		composer.gotoScene("gpsError", { time=800, effect="crossFade" })
	else
		--we have GPS data, so calculate closest entrance...
		local lat = currentLatitude
		local long = currentLongitude
		local bestDistance = math.huge
		local bestEntrance = 0
		for index = 1, #(entranceTable[currentBuilding.id]) do
			local dist = math.sqrt((lat - entranceTable[currentBuilding.id][index].latitude)^2 + (long - entranceTable[currentBuilding.id][index].longitude)^2)
			if dist < bestDistance then
				bestDistance = dist
				bestEntrance = index
			end
		end
		
		if bestEntrance == 0 then
			--no entrances for the given building
			composer.setVariable("gpsStatus", "none")
			composer.setVariable("mapTable", mapTable)
			composer.gotoScene("map", { time=800, effect="crossFade" })
		else
			mapTable.entranceX = entranceTable[currentBuilding.id][bestEntrance].x
			mapTable.entranceY = entranceTable[currentBuilding.id][bestEntrance].y
			print(util.debugText.."Best entrance at "..mapTable.entranceX..","..mapTable.entranceY)
			
			composer.setVariable("mapTable", mapTable)
			
			if (system.getTimer() - gpsTime) > gpsTimeout then
				--...but the data is older than the timeout
				composer.setVariable("gpsStatus","timeout")
				composer.gotoScene("gpsError", { time=800, effect="crossFade" })
			else
				--...and the data is recent
				composer.setVariable("gpsStatus","current")
				composer.gotoScene("map", { time=800, effect="crossFade" })
			end
		end
	end
end

local function back(event)
	composer.gotoScene("mainMenu", { time=800, effect="crossFade" })
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	--set up GUI
	--set background
	local background = display.newImageRect(sceneGroup, "res/classroomMenuBackground.jpg", 800, 965)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	--create building items
	local textWidth, textHeight
	textWidth, textHeight = util.getCenteredImageSize(442, 125, 65)
	local buildingSelectText = display.newImageRect(sceneGroup, "res/buildingSelectText.png", textWidth, textHeight)
	buildingSelectText.anchorY = 0
	buildingSelectText.y = 10
	buildingSelectText.x = display.contentCenterX
	
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
	
	--create classroom items
	textWidth = (textHeight / 125) * 465
	classroomSelectText = display.newImageRect(sceneGroup, "res/classroomSelectText.png", textWidth, textHeight)
	classroomSelectText.anchorY = 0
	classroomSelectText.y = 200
	classroomSelectText.x = display.contentCenterX
	classroomSelectText.isVisible = false
	
	--create classroom tableview
	classroomTableView = widget.newTableView({
		x = display.contentCenterX,
		y = 339,
		height = 160,
		width = display.contentWidth - 50,
		onRowRender = onClassroomRowRender,
		onRowTouch = onClassroomRowTouch
	})
	classroomTableView.isVisible = false
	sceneGroup:insert(classroomTableView)
	
	--create go button
	local buttonHeight = textHeight
	local buttonWidth = (textHeight / 85) * 125
	goButton = display.newImageRect(sceneGroup, "res/goButton.png", buttonWidth, buttonHeight)
	goButton.anchorY = 0
	goButton.y = display.contentHeight - buttonHeight
	goButton.x = display.contentCenterX
	goButton.isVisible = false
	goButton:addEventListener("tap", goToMap)
	
	--create back button
	local backButton = display.newImageRect(sceneGroup, "res/back.png", 40, 40)
	backButton.anchorX = 0
	backButton.anchorY = 0
	backButton.x = 20
	backButton.y = 20
	backButton:addEventListener("tap", back)
	
	--[[
	--if we are coming here from buildingMap, set the current building
	local selectedBuilding = composer.getVariable("selectedBuilding")
	if selectedBuilding ~= nil then
		
		--reset the composer variable
		composer.setVariable("selectedBuilding", nil)
	end
	]]--
	--add the GPS listener
	Runtime:addEventListener("location",locationHandler)
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
		--composer.removeScene("classroomMenu")
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
