-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Load required Corona modules
local widget = require("widget")
local physics = require("physics")
system.activate("multitouch")

-- Get the screen metrics (use the entire device screen area)
local WIDTH = display.actualContentWidth
local HEIGHT = display.actualContentHeight
local xMin = display.screenOriginX
local yMin = display.screenOriginY
local xMax = xMin + WIDTH
local yMax = yMin + HEIGHT
local xCenter = (xMin + xMax) / 2
local yCenter = (yMin + yMax) / 2

-- Game metrics
local yControls = yMin					     -- y position for UI buttons
local ballRadius = 12                     -- radius of the ball
local xStart = xCenter                  -- starting x for the ball
local yStart = yMax - ballRadius - 90       -- starting y for the ball

-- Game objects
local ball         -- the ball that bounces around

local shoot     -- circle that when hit, shoots a bullet

local joystickSet = "on"  -- setting where user can choose to have joystick on or off

local background = display.newImageRect( "starBackground.png", xMax, yMax )
background.x = xCenter
background.y = yCenter

-- Make and return a ball object at the given position
function makeShip(x, y)
	--local b = display.newCircle(x, y, ballRadius)
	s = display.newImageRect( "triangle.png", 30, 30)
	--b:setFillColor(1, 0, 0)  -- red
	--physics.addBody(b, { radius = ballRadius })
	s.x = x
	s.y = y
	--local triangleShape = {0,-15, 15,15, -15,15 }
	physics.addBody( s, { density = 100, friction = 0, bounce = 0 })
	s.isSleepingAllowed = false   -- accelerometer will not wake ball on its own
	return s
end

-- Make and return a border wall at the given position and size
function makeBorder(x, y, width, height) 
	local b = display.newRect(x, y, width, height)
	b:setFillColor( 0, .2, .7 )
	physics.addBody(b, "static")
	return b
end

-- Handle accelerometer events. Simulate gravity in direction of device tilt.
function accelEvent(event)
	--print(event.xRaw, event.yRaw)
	--physics.setGravity(event.xRaw * 10, -event.yRaw * 10)
	ship:setLinearVelocity(event.xRaw * 250, -event.yRaw * 250)
	--ship:setLinearVelocity(event.xRaw * 250, -event.yRaw * 250)
end


-- Called when the screen is touched
-- Fire a new bullet.
function fireBullet( event )
	if event.phase == "began" then
		local b = createBullet()
		transition.to( b, { x = ship.x, y = yMin, time = 1000, onComplete = bulletDone } )
	end
end


function createBullet()
	--local b = display.newImageRect( bullets, "bullet.png", 32, 60 )      --(use the bullets group as the parent)
	local b = display.newRect( bullets, ship.x, ship.y - 15, 3, 7 )
	--b.x = ball.x
	--b.y = ball.y

	return b
end

-- Create a return a new target object at a random altitude.
function createTarget()
	local t = display.newGroup()
	t = display.newImageRect( targets, "zombie.png", 30, 50 )
	t.y = yMin - 15
	t.x = math.random( xMin+70, xMax-70 )
	targets:insert(t)   -- put t into the targets group
	return t
end


-- Called when a bullet goes off the top of the screen
-- Delete the bullet.
function bulletDone( obj )
	obj:removeSelf(b)
end

-- Called when a target goes off the left of the screen
-- Delete the target and count a miss.
function targetDone( obj )
	transition.cancel( obj )
	obj:removeSelf( )
	--miss = miss + 1
	--missTxt.text = "Miss: " .. miss
	--percCalc()
end


-- Return true if the given bullet hit the given target
function hitTest( b, t )
	if math.abs(b.x - t.x) <= 15 and math.abs(b.y - t.y) <= 15 then
		transition.cancel(t)
		return true
	else
		return false
	end
end

function shipCollide( s, t )
	if math.abs(s.x - t.x) <= 15 and math.abs(s.y - t.y) <= 15 then
		s.x = xStart
		s.y = yStart
		-- hits = 0
		print("yes")
		return true
	else
		return false
	end
end

-- Called before each animation frame
function newFrame()
	-- Launch new targets at random intervals and speeds
	if math.random(0, 20) < 0.1		then
		local t = createTarget()
		transition.to( t, { y = yMax-100, rotation = 360, time = math.random( 3000, 5000 ), onComplete = targetDone } )
	end


	-- Test for hits (all bullets against all targets)
	local zombies = {}   -- to hold objects that need deferred deleting
	for i = 1, bullets.numChildren do
		local b = bullets[i]
		for j = 1, targets.numChildren do
			local t = targets[j]
			if hitTest( b, t ) then
				-- Add bullet and target to the zombie list for deferred delete.
				-- (Deleting them now will screw up the for loops)
				zombies[#zombies + 1] = b
				zombies[#zombies + 1] = t

				-- Count a hit
				--hits = hits + 1
				--hitsTxt.text = "Hits: " .. hits
				--percCalc()


				-- Make an explosion
				--e = display.newImageRect( "explosion.png", 48, 48 )
				--e.x = t.x
				--e.y = t.y
				--transition.fadeOut( e, { xScale = 2, yScale = 2, time = 4000, onComplete = explosionDone }  )
				--transition.to( e, { xScale = 1.5, yScale = 1.5, alpha = 0, time = 1000, onComplete = explosionDone } )

			end
			--if shipCollide(s, t) then
			--	zombies[#zombies + 1] = t
			--end
		end
	end

	-- Now delete all the zombie objects
	for i = 1, #zombies do
		local obj = zombies[i]
		transition.cancel( obj )
		obj:removeSelf()
	end
end


-- Init the game
function initGame()
	-- Prepare screen and physics engine
	display.setStatusBar(display.HiddenStatusBar)
	physics.start()
	physics.setGravity(0, 0)   -- gravity will be set by accelerometer events

	-- Make the ball object and the blocks group
	ship = makeShip(xStart, yStart)

		-- Make walls around the borders of the screen
	local thickness = 4
	makeBorder(xCenter, yMin, WIDTH, thickness)  -- top with room for UI bar
	makeBorder(xCenter, yMax - 45, WIDTH, 90)  -- bottom
	makeBorder(xMin, yCenter, thickness, HEIGHT)  -- left
	makeBorder(xMax, yCenter, thickness, HEIGHT)  -- right

	-- Load and show the joystick control if running on a simulator
	--if system.getInfo("environment") == "simulator" then
	if joystickSet == "on" then
		local joystick = require("joystick")
		local offset = joystick.rOuter + 6
		joystick:create(xMin + offset, yMax - offset)
	end
	--end

	shoot = display.newCircle( xMax - 45, yMax - 45, 40 )
	--shoot:setFillColor( 1, 0, 0 )
	shoot:setFillColor( 0,1,1 )

	bullets = display.newGroup()
	targets = display.newGroup()

	-- Start the event listeners
	Runtime:addEventListener( "accelerometer", accelEvent )
	--joystick:addEventListener( "touch", accelEvent )
	shoot:addEventListener( "touch", fireBullet )
	Runtime:addEventListener( "enterFrame", newFrame )
	--Runtime:addEventListener( "enterFrame", shipCollide )
	--Runtime:addEventListener( "touch", onScreenTouch )
end

-- Init and start the game
initGame()