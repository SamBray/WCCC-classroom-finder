
local composer = require( "composer" )

local theme = require("classes.theme")
local util = require("lib.utility")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local debugText = "ClassroomFinderOutput: "

local map
local buildings

local function addMarkers()
	--create markers for buildings
	for i = 1, #buildings do
		local markerSettings = 
		{
			title = buildings[i].name,
			listener = markerHandler
		}
		--associate a building with a marker ID (returned by map:addMarker)
		local markerId = map:addMarker(buildings[i].latitude, buildings[i].longitude,markerSettings)
		buildings[i]["marker"] = markerId
	end
	
	--create the back marker
	--map:addMarker(40.235679,-79.569494, {title = "Go Back", listener = back})	
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
	
	--create map
	local mapHeight = display.contentHeight + 400
	local mapWidth = display.contentWidth + 400
	map = native.newMapView(display.contentCenterX, display.contentCenterY, mapWidth, mapHeight)
	if map == nil then
		--probably running on the simulator, or no internet access
		--print("Failed to create map")
		--load error background
		local errorImageDim
		if display.contentHeight > 512 then
			errorImageDim = 512
		else
			errorImageDim = display.contentHeight
		end
		local errorImage = display.newImageRect(sceneGroup, "res/error_img.png", errorImageDim, errorImageDim)
		errorImage.x = display.contentCenterX
		errorImage.y = display.contentCenterY
		
		--load error message
		local errorTextWidth, errorTextHeight = util.getCenteredImageSize(405, 171, 20)
		local errorText = display.newImageRect(sceneGroup, "res/mapError.png", errorTextWidth, errorTextHeight)
		errorText.x = display.contentCenterX
		errorText.y = display.contentCenterY - 50
	else
		--initial setup
		map.mapType = "standard"
		if buildings.centerLatitude and buildings.centerLongitude then
			map:setCenter(buildings.centerLatitude,buildings.centerLongitude)
		else
			map:setCenter(0,0)
		end
		
		--add markers after delay
		timer.performWithDelay(500, addMarkers)
	end
	
	--create UI group
	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)
	
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
		if map then
			map:removeSelf()
			map = nil
		end
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
