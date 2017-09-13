
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local debugText = "ClassroomFinderOutput: "

local currentLocationMarker
local map
local buildings

--create GPS listener
local function locationHandler(event)
	if(event.errorCode) then
		print(debugText.."Error in GPS handler!")
	elseif map ~= nil then
		--whenever the user moves, update their location
		if currentLocationMarker ~= nil then
			--need to remove the old marker
			map:removeMarker(currentLocationMarker)
		end
		--add a new marker at the user's current location
		currentLocationMarker = map:addMarker(event.latitude, event.longitude, {title = "You Are Here"})
	end
end

local function markerHandler(event)
--[[
	--code for detecting which marker was pushed
	local currentMarker = event.markerId
	local buildingTapped
	for i = 1, #buildings do
		if buildings[i].marker == currentMarker then
			buildingTapped = buildings[i]
			break
		end
	end
	if buildingTapped == nil then
		print(debugText.."Error handling building touch")
	else
		--launch classroomMenu with the current building
		composer.setVariable("selectedBuilding",buildingTapped)
		composer.gotoScene("classroomMenu", { time=800, effect="crossFade" })
	end
]]--
	--ehh, just go to classroom menu without doing anything fancy
	composer.gotoScene("classroomMenu", { time=800, effect="crossFade" })
end

--listener for back button
local function back(event)
	composer.gotoScene("mainMenu", { time=800, effect="crossFade" })
end



-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	--get buildings
	buildings = composer.getVariable("buildings")
	
	-- Code here runs when the scene is first created but has not yet appeared on screen
	--insert background
	local background = display.newImageRect(sceneGroup, "res/MapBackground.png", 1500, 1500)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	--create groups
	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)
	
	--create map
	local mapHeight = display.contentHeight + 400
	local mapWidth = display.contentWidth + 400
	map = native.newMapView(display.contentCenterX, display.contentCenterY, mapWidth, mapHeight)
	if map == nil then
		--probably running on the simulator
		print("Failed to create map")
	else
		--initial setup
		map.mapType = "standard"
		map:setCenter(40.234639,-79.566676)
		
		--create markers for buildings
		for i = 1, #buildings do
			local markerSettings = 
			{
				title = buildings[i].name,
				listener = markerHandler,
			}
			--associate a building with a marker ID (returned by map:addMarker)
			local markerId = map:addMarker(buildings[i].latitude, buildings[i].longitude,markerSettings)
			building[i]["marker"] = markerId
		end
		
		--create the back marker
		map:addMarker(40.235679,-79.569494, {title = "Go Back", listener = back})
		
		--add the GPS listener
		Runtime:addEventListener("location",locationHandler)
	end
	
	--create back button
	local backButton = display.newImageRect(uiGroup, "res/back.png", 40, 40)
	backButton.anchorX = 0
	backButton.anchorY = 0
	backButton.x = 20
	backButton.y = 20
	backButton:addEventListener("tap", back)
	
	
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
		composer.removeScene("buildingMap")
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
