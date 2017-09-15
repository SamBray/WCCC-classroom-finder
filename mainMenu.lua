
local composer = require( "composer" )

local theme = require("classes.theme")
local util = require("lib.utility")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local backgroundColor = {1,1,1}

--file reading functions
local function readBuildings()
	local filePath = system.pathForFile("res/buildings.data")
	local file, errorString = io.open(filePath, "r")
	
	local buildingTable = {}
	
	if not file then
		print("File error: "..errorString)
	else
		local mode
		for line in file:lines() do
			if line == "" then
				--skip
			elseif line:find("!building") ~= nil then
				mode = "building"
			elseif line:find("!center") ~= nil then
				mode = "center"
			elseif mode == "building" then
				local currentIndex = #buildingTable + 1
				local tokens = util.split(line, ",")
				buildingTable[currentIndex] = {}
				buildingTable[currentIndex].name = tokens[1]
				buildingTable[currentIndex].data = tokens[2]
				buildingTable[currentIndex].latitude = tonumber(tokens[3])
				buildingTable[currentIndex].longitude = tonumber(tokens[4])
				buildingTable[currentIndex].image = tokens[5]
				buildingTable[currentIndex].width = tonumber(tokens[6])
				buildingTable[currentIndex].height = tonumber(tokens[7])
				buildingTable[currentIndex].id = util.split(tokens[2],"%.")[1]
			elseif mode == "center" then
				local tokens = util.split(line, ",")
				buildingTable.centerLatitude = tonumber(tokens[1])
				buildingTable.centerLongitude = tonumber(tokens[2])
			end
		end
		file:close()
		
		--sort the buildings
		local function compare(a,b)
			return a.name < b.name
		end
		table.sort(buildingTable, compare)
	end
	return buildingTable
end

function findBuildingListener()
	composer.gotoScene("buildingMap", { time=800, effect="crossFade" })
end

function findClassroomListener()
	composer.gotoScene("classroomMenu", { time=800, effect="crossFade" })
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
	local background = display.newImageRect(sceneGroup, "res/mainMenuBackground.jpg", 1024, 626)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	--create the logo
	local logoHeight, logoWidth
	logoWidth, logoHeight = util.getCenteredImageSize(450, 208, 15)
	local logo = display.newImageRect(sceneGroup, "res/logo.png", logoWidth, logoHeight)
	logo.anchorY = 0
	logo.x = display.contentCenterX
	logo.y = 30
	
	
	--create buttons
	local buttonHeight
	local buttonWidth
	buttonWidth, buttonHeight = util.getCenteredImageSize(601, 163, 30)
	local findBuildingButton = display.newImageRect(sceneGroup, "res/findBuildingButton.png", buttonWidth, buttonHeight)
	findBuildingButton.anchorY = 0
	findBuildingButton.y = display.contentHeight - buttonHeight * 2 - 50 - 35
	findBuildingButton.x = display.contentCenterX
	findBuildingButton:addEventListener("tap", findBuildingListener)
	
	local findClassroomButton = display.newImageRect(sceneGroup, "res/findClassroomButton.png", buttonWidth, buttonHeight)
	findClassroomButton.anchorY = 0
	findClassroomButton.y = display.contentHeight - buttonHeight - 50
	findClassroomButton.x = display.contentCenterX
	findClassroomButton:addEventListener("tap", findClassroomListener)
	
	--read in the building data and set composer variables
	local buildingTable = readBuildings()
	--composer.setVariable("selectedBuilding", nil)
	composer.setVariable("buildings", buildingTable)
	
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
