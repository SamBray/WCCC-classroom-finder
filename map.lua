
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local mapData = composer.getVariable("mapTable")

local mapGroup
local mapGroupScale = .5

local uiGroup

local flagHeight = 141
local flagWidth = 141
local flagBase = 5

local function checkBounds()
	if mapGroup.x > 0 or display.contentWidth > mapData.mapWidth * mapGroupScale then
		mapGroup.x = 0
	elseif mapGroup.x < display.contentWidth - mapData.mapWidth * mapGroupScale then
		mapGroup.x = display.contentWidth - mapData.mapWidth * mapGroupScale
	end

	if mapGroup.y > 0 or display.contentHeight > mapData.mapHeight * mapGroupScale then
		mapGroup.y = 0
	elseif mapGroup.y < display.contentHeight - mapData.mapHeight * mapGroupScale then
		mapGroup.y = display.contentHeight - mapData.mapHeight * mapGroupScale
	end
end

local function dragMap(event)
	local mapGroup = event.target
	local phase = event.phase
	
	if("began" == phase) then
		--set focus to mapGroup
		display.currentStage:setFocus(mapGroup)
		--store initial offset position
		mapGroup.touchOffsetX = event.x - mapGroup.x
		mapGroup.touchOffsetY = event.y - mapGroup.y
	elseif("moved" == phase) then
		mapGroup.x = event.x - mapGroup.touchOffsetX
		mapGroup.y = event.y - mapGroup.touchOffsetY
		checkBounds()
	elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Release touch focus on the ship
        display.currentStage:setFocus( nil )
	end
	
	return true
end

local function zoomIn(event)
	if mapGroupScale < 1 then
		mapGroup.xScale = mapGroup.xScale + .1
		mapGroup.yScale = mapGroup.yScale + .1
		mapGroupScale = mapGroupScale + .1
		checkBounds()
	end
	return true
end

local function zoomOut(event)
	if mapGroupScale > .2 then
		mapGroup.xScale = mapGroup.xScale - .1
		mapGroup.yScale = mapGroup.yScale - .1
		mapGroupScale = mapGroupScale - .1
		checkBounds()
	end
	return true
end

local function back(event)
	composer.gotoScene("classroomMenu", { time=800, effect="crossFade" })
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	--insert background
	local background = display.newImageRect(sceneGroup, "res/MapBackground.png", 1500, 1500)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	--create display groups
	mapGroup = display.newGroup() 
	sceneGroup:insert(mapGroup)
	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)
	
	--create and init map and flags
	local map = display.newImageRect(mapGroup, "res/"..mapData.mapFile, mapData.mapWidth, mapData.mapHeight)
	map.anchorX = 0
	map.anchorY = 0
	
	mapGroup.xScale = mapGroupScale
	mapGroup.yScale = mapGroupScale
	
	--set initial map location
	mapGroup.x = display.contentCenterX - mapData.entranceX * mapGroupScale
	mapGroup.y = display.contentCenterY - mapData.entranceY * mapGroupScale
	checkBounds()

	--set initial flag locations
	local entranceFlag = display.newImageRect(mapGroup, "res/StartFlag.png", flagWidth, flagHeight)
	entranceFlag.anchorX = flagBase/flagWidth
	entranceFlag.anchorY = 1
	entranceFlag.x = mapData.entranceX
	entranceFlag.y = mapData.entranceY
	
	local classroomFlag = display.newImageRect(mapGroup, "res/EndFlag.png", flagWidth, flagHeight)
	classroomFlag.anchorX = flagBase/flagWidth
	classroomFlag.anchorY = 1
	classroomFlag.x = mapData.classroomX
	classroomFlag.y = mapData.classroomY
	
	--add the movement listener for the mapGroup
	mapGroup:addEventListener("touch", dragMap)
	
	--create the buttons in the uiGroup
	local plusButton = display.newImageRect(uiGroup, "res/plus.png", 40, 40)
	plusButton.anchorX = 1
	plusButton.anchorY = 0
	plusButton.x = display.contentWidth - 20
	plusButton.y = 20
	plusButton:addEventListener("tap", zoomIn)
	
	local minusButton = display.newImageRect(uiGroup, "res/minus.png", 40, 40)
	minusButton.anchorX = 1
	minusButton.anchorY = 0
	minusButton.x = display.contentWidth - 70
	minusButton.y = 20
	minusButton:addEventListener("tap", zoomOut)
	
	local backButton = display.newImageRect(uiGroup, "res/back.png", 40, 40)
	backButton.anchorX = 0
	backButton.anchorY = 0
	backButton.x = 0 + 20
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
		composer.removeScene( "map" )
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
