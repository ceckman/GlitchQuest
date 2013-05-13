require "lua/AnAL"
require "lua/TEsound"
Camera = require "lua/camera"
Gamestate = require "lua/gamestate"
Menu = require 'lua/menu'
Timer = require "lua/timer"

--This code is best viewed in Notepad++

--To run download LOVE online and run the love file

--Glitches:
--on a reset after death, MAFRE hangs in the air for a couple of seconds. The problem is linked to the timer that resets the player after death, as a regular reset with "r" works fine. We need to go back and look at the glitchy timer and see what is wrong with it.
--MAFRE occasionally disappears when two or more keys are hit. This is a problem with his various states conflicting (ie running, jumping, etc). We need to go back and check the state checkers and see what is wrong there.
--Occassionally, touching the sides of the crushing blocks will kill the player. This has something to do with how we check for collision on the blocks (ie the blocks hitbox is too large). We just need to make the hitbox on the blocks smaller on the sides.
--Also, the music in the end is glitchy, but that adds nicely to the style of the game

--Create our gamestates (ie levels, menu)
local menu = {}
local game = {}
local controls = {}
local credits = {}
local endgame = {}

function love.load()
	Gamestate.registerEvents() -- so state:update() will get called
    Gamestate.switch(menu) --starts the game on menu screen
end

--Our list of various variables
--These are for jumping
yc = -9000
change = 0
--These are used to check the various staes that MAFRE is in and to display his proper animation
jump = false
jumping = false
left = false
right = false
standing = true
air = false
up = false
mid = false
down = false
walking= false
first = true
--These variables are for the crushing blocks
bup = false
bup2 = false
bup3 = false
dead = false
--This variable is just for the lever
leveronn = false
--This makes it so that the death noise only plays once
play_dead = true

--Menu
function menu:init()
   TEsound.playLooping("menu/maintheme.mp3", "main")
   mbk = love.graphics.newImage("menu/m_bk.jpg")
   testmenu = Menu.new()
   testmenu:addItem{
      name = 'Start Game',
      action = function()
		TEsound.play("sound/select.mp3")
		TEsound.playLooping("level1/level1.mp3", "level")
		TEsound.stop("main")
        Gamestate.switch(game)
      end
   }
   testmenu:addItem{
      name = 'How to Play',
      action = function()
         TEsound.play("sound/select.mp3")
		 Gamestate.switch(controls)
      end
   }
   testmenu:addItem{
      name = 'Options',
      action = function()
         TEsound.play("sound/select.mp3")
      end
   }
   testmenu:addItem{
      name = 'Credits',
      action = function()
		 TEsound.play("sound/select.mp3")
         Gamestate.switch(credits)
      end
   }
   testmenu:addItem{
      name = 'Quit',
      action = function()
		 TEsound.play("sound/select.mp3")
         love.event.push('quit')
      end
   }
  love.graphics.setMode(1024, 768, false, true, 0) --set the window dimensions to 1024 by 768
end

function menu:update(dt)
   testmenu:update(dt)
   --cleanup is called to loop the music
   TEsound.cleanup()
end

function menu:draw()
   love.graphics.setColor(255, 255, 255)
   love.graphics.draw(mbk, 0, 0)
   love.graphics.setColor(0, 255, 0)
   love.graphics.print("GLITCH QUEST", 250, 100, 0, 2, 2)
   testmenu:draw(250, 250)
end

function menu:keypressed(key)
   testmenu:keypressed(key)
   if key == "up" or key == "down" then TEsound.play("sound/select.mp3") end
end

--Credits screen
function credits:init()
	mbk = love.graphics.newImage("menu/m_bk.jpg")	
end

function credits:update(dt)
   TEsound.cleanup()
end

function credits:draw()
   love.graphics.setColor(255, 255, 255)
   love.graphics.draw(mbk, 0, 0)
   love.graphics.setColor(0, 255, 0)
   love.graphics.print("GlitchQuest Credits", 250, 100, 0, 2, 2)
   love.graphics.setColor(0, 0, 0)
   love.graphics.print("Created by Andrei Osypov and Clay Eckman", 250, 200)
   love.graphics.print("Cave Story for music, backgrounds, and sound effects", 250, 300)
   love.graphics.print("http://spriters-resource.com/ for all sprites (MAFRE, lever, spikes)", 250, 400)
   love.graphics.print("Ensayia, Matthias Richter, Bartbes, and nkorth for their code libraries", 250, 500)
   love.graphics.print("Github and Google Drive", 250, 600)
end

function credits:keypressed(key)
    if key == "escape" then
	  TEsound.play("sound/select.mp3")
	  Gamestate.switch(menu)
   end
end

--How to Play screen
function credits:init()
	control = love.graphics.newImage("menu/controls.jpg")	
end

function credits:update(dt)
   TEsound.cleanup()
end

function credits:draw()
   love.graphics.setColor(255, 255, 255)
   love.graphics.draw(control, 0, 0)
end

function credits:keypressed(key)
    if key == "escape" then
	  TEsound.play("sound/select.mp3")
	  Gamestate.switch(menu)
   end
end

--End Screen
--Before you ask, yes, the end screen is supposed to be glitchy (to go along with the game's name)
function endgame:init()
   bsod = love.graphics.newImage("MAFRE/bsod.jpg")
   TEsound.playLooping("level2/run.mp3", "main")
   TEsound.playLooping("level1/level1.mp3", "main")
   TEsound.playLooping("menu/maintheme.mp3", "main")
   Timer.add(5, function() love.event.push("quit") end)
   love.graphics.setMode(1024, 768, false, true, 0) --set the window dimensions to 1024 by 768
end

function endgame:update(dt)
   Timer.update(dt)
   TEsound.cleanup()
end

function endgame:draw()
    love.graphics.setColor(255, 255, 255)
	love.graphics.draw(bsod)
end

--The game (which will be the first level in our full game)
function game:init()
   --All the local images are turned into animations
   local img  = love.graphics.newImage("MAFRE/running.png")
   local img2  = love.graphics.newImage("MAFRE/runningbetterleft.png")
   local death = love.graphics.newImage("MAFRE/dying.png")
   bk = love.graphics.newImage("level1/bk1.png")
   --Animation is divided into different parts
   --image, frame width, frame height, fps
   anim = newAnimation(img, 93, 75, .15, 0)
   --choose either loop, bounce, or once for setMode
   anim:setMode("loop")
   
   --static images
   imageStanding = love.graphics.newImage("MAFRE/standingbetter.png")
   imageStandingLeft = love.graphics.newImage("MAFRE/standingleft.png")
   
   imageJumpingUp = love.graphics.newImage("MAFRE/jumpingup.png")
   imageJumpingDown = love.graphics.newImage("MAFRE/jumpingdown.png")
   
   imageJumpingUpLeft = love.graphics.newImage("MAFRE/jumpingupleft.png")
   imageJumpingDownLeft = love.graphics.newImage("MAFRE/jumpingdownleft.png")
   
   spikes = love.graphics.newImage("MAFRE/spikes.png")
   
   spikesright = love.graphics.newImage("MAFRE/spikesright.png")
   
   spikesdown = love.graphics.newImage("MAFRE/spikesdown.png")
   
   lever = love.graphics.newImage("MAFRE/lever.png")
   
   leveron = love.graphics.newImage("MAFRE/leveron.png")
   
   anim2 = newAnimation(img2, 93, 75, .15, 0)
   anim2:setMode("loop")
   
   anim_dead = newAnimation(death, 110, 88, .1, 0)
   anim_dead:setMode("loop")
    
	--text is used in our debugger
	text = " "
	love.physics.setMeter(100) --the height of a meter our worlds will be 64px
	world = love.physics.newWorld(0, 9.81*64, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
	
	objects = {} -- table to hold all our physical objects

	objects.player = {}
	objects.player.body = love.physics.newBody(world, 40, 100, "dynamic")
	objects.player.shape = love.physics.newRectangleShape(60, 65) --make a rectangle with a width of 1024 and a height of 50
	objects.player.fixture = love.physics.newFixture(objects.player.body, objects.player.shape); --attach shape to body
	objects.player.body:setFixedRotation(true)
	
	cam = Camera(objects.player.body:getX(), objects.player.body:getY())
	
	--list of blocks used in game, see andrei's block map for reference
	objects.block1 = {}
	objects.block1.body = love.physics.newBody(world, 0, 350, "kinematic")
	objects.block1.shape = love.physics.newRectangleShape(0, 0, 400, 100)
	objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- A higher density gives it more mass.

	objects.block2 = {}
	objects.block2.body = love.physics.newBody(world, 600, 300, "kinematic")
	objects.block2.shape = love.physics.newRectangleShape(0, 0, 200, 200)
	objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)
	
	objects.block3 = {}
	objects.block3.body = love.physics.newBody(world, 500, 500, "kinematic")
	objects.block3.shape = love.physics.newRectangleShape(0, 0, 100, 300)
	objects.block3.fixture = love.physics.newFixture(objects.block3.body, objects.block3.shape, 5) -- A higher density gives it more mass.
	
	objects.block4 = {}
	objects.block4.body = love.physics.newBody(world, -300, 0, "kinematic")
	objects.block4.shape = love.physics.newRectangleShape(0, 0, 600, 1000)
	objects.block4.fixture = love.physics.newFixture(objects.block4.body, objects.block4.shape, 5)
	
	objects.block5 = {}
	objects.block5.body = love.physics.newBody(world, 800,-300, "kinematic")
	objects.block5.shape = love.physics.newRectangleShape(0, 0, 2000, 620)
	objects.block5.fixture = love.physics.newFixture(objects.block5.body, objects.block5.shape, 5)
	
	objects.block6 = {}
	objects.block6.body = love.physics.newBody(world, 500,400, "kinematic")
	objects.block6.shape = love.physics.newRectangleShape(0, 0, 1000, 110)
	objects.block6.fixture = love.physics.newFixture(objects.block6.body, objects.block6.shape, 5)
	
	objects.block7 = {}
	objects.block7.body = love.physics.newBody(world, 950, 300, "kinematic")
	objects.block7.shape = love.physics.newRectangleShape(0, 0, 102, 200)
	objects.block7.fixture = love.physics.newFixture(objects.block7.body, objects.block7.shape, 2)
	
	objects.block8 = {}
	objects.block8.body = love.physics.newBody(world, 1700, 700, "kinematic")
	objects.block8.shape = love.physics.newRectangleShape(0, 0, 1000, 2000)
	objects.block8.fixture = love.physics.newFixture(objects.block8.body, objects.block8.shape, 2)
	
	objects.block9 = {}
	objects.block9.body = love.physics.newBody(world, 800, 900, "kinematic")
	objects.block9.shape = love.physics.newRectangleShape(0, 0, 1250, 200)
	objects.block9.fixture = love.physics.newFixture(objects.block9.body, objects.block9.shape, 2)
	
	objects.block10 = {}
	objects.block10.body = love.physics.newBody(world, 700, 500, "kinematic")
	objects.block10.shape = love.physics.newRectangleShape(0, 0, 100, 300)
	objects.block10.fixture = love.physics.newFixture(objects.block10.body, objects.block10.shape, 5)
	
	objects.block11 = {}
	objects.block11.body = love.physics.newBody(world, 900, 500, "kinematic")
	objects.block11.shape = love.physics.newRectangleShape(0, 0, 100, 300)
	objects.block11.fixture = love.physics.newFixture(objects.block11.body, objects.block11.shape, 5)
	
	objects.block12 = {}
	objects.block12.body = love.physics.newBody(world, 300, 500, "kinematic")
	objects.block12.shape = love.physics.newRectangleShape(0, 0, 100, 300)
	objects.block12.fixture = love.physics.newFixture(objects.block12.body, objects.block12.shape, 5)
	
	objects.block13 = {}
	objects.block13.body = love.physics.newBody(world, 0, 650, "kinematic")
	objects.block13.shape = love.physics.newRectangleShape(0, 0, 200, 50)
	objects.block13.fixture = love.physics.newFixture(objects.block13.body, objects.block13.shape, 5)
	
	objects.block14 = {}
	objects.block14.body = love.physics.newBody(world, -700, 0, "kinematic")
	objects.block14.shape = love.physics.newRectangleShape(0, 0, 600, 6000)
	objects.block14.fixture = love.physics.newFixture(objects.block14.body, objects.block14.shape, 5)
	
	objects.block15 = {}
	objects.block15.body = love.physics.newBody(world, 50, 975, "kinematic")
	objects.block15.shape = love.physics.newRectangleShape(0, 0, 300, 50)
	objects.block15.fixture = love.physics.newFixture(objects.block15.body, objects.block15.shape, 5)
	
	objects.block16 = {}
	objects.block16.body = love.physics.newBody(world, -80, 900, "kinematic")
	objects.block16.shape = love.physics.newRectangleShape(0, 0, 50, 200)
	objects.block16.fixture = love.physics.newFixture(objects.block16.body, objects.block16.shape, 5)
	
	objects.block17 = {}
	objects.block17.body = love.physics.newBody(world, -300, 1300, "kinematic")
	objects.block17.shape = love.physics.newRectangleShape(0, 0, 200, 50)
	objects.block17.fixture = love.physics.newFixture(objects.block17.body, objects.block17.shape, 5)
	
	objects.block18 = {}
	objects.block18.body = love.physics.newBody(world, 350, 1300, "kinematic")
	objects.block18.shape = love.physics.newRectangleShape(0, 0, 600, 60)
	objects.block18.fixture = love.physics.newFixture(objects.block18.body, objects.block18.shape, 5)
	
	objects.block19 = {}
	objects.block19.body = love.physics.newBody(world, 400, 600, "dynamic")
	objects.block19.shape = love.physics.newRectangleShape(0, 0, 94, 150)
	objects.block19.fixture = love.physics.newFixture(objects.block19.body, objects.block19.shape, 1)
	objects.block19.body:setFixedRotation(true)
	
	objects.block20 = {}
	objects.block20.body = love.physics.newBody(world, 600, 600, "dynamic")
	objects.block20.shape = love.physics.newRectangleShape(0, 0, 94, 150)
	objects.block20.fixture = love.physics.newFixture(objects.block20.body, objects.block20.shape, 1)
	objects.block20.body:setFixedRotation(true)
	
	objects.block21 = {}
	objects.block21.body = love.physics.newBody(world, 800, 600, "dynamic")
	objects.block21.shape = love.physics.newRectangleShape(0, 0, 94, 150)
	objects.block21.fixture = love.physics.newFixture(objects.block21.body, objects.block21.shape, 1)
	objects.block21.body:setFixedRotation(true)
	
	objects.block22 = {}
	objects.block22.body = love.physics.newBody(world, -30, 1550, "kinematic")
	objects.block22.shape = love.physics.newRectangleShape(0, 0, 300, 50)
	objects.block22.fixture = love.physics.newFixture(objects.block22.body, objects.block22.shape, 5)
	
	objects.block23 = {}
	objects.block23.body = love.physics.newBody(world, 100, 1425, "kinematic")
	objects.block23.shape = love.physics.newRectangleShape(0, 0, 50, 300)
	objects.block23.fixture = love.physics.newFixture(objects.block23.body, objects.block23.shape, 5)
	
	objects.block24 = {}
	objects.block24.body = love.physics.newBody(world, 1000, 2300, "kinematic")
	objects.block24.shape = love.physics.newRectangleShape(0, 0, 3000, 700)
	objects.block24.fixture = love.physics.newFixture(objects.block24.body, objects.block24.shape, 5)
	
	objects.block25 = {}
	objects.block25.body = love.physics.newBody(world, 500, 1650, "kinematic")
	objects.block25.shape = love.physics.newRectangleShape(0, 0, 300, 50)
	objects.block25.fixture = love.physics.newFixture(objects.block25.body, objects.block25.shape, 5)
	
	objects.block26 = {}
	objects.block26.body = love.physics.newBody(world, 240, 1450, "dynamic")
	objects.block26.shape = love.physics.newRectangleShape(0, 0, 250, 10)
	objects.block26.fixture = love.physics.newFixture(objects.block26.body, objects.block26.shape, 5)
	
	objects.block27 = {}
	objects.block27.body = love.physics.newBody(world, 675, 1700, "kinematic")
	objects.block27.shape = love.physics.newRectangleShape(0, 0, 50, 860)
	objects.block27.fixture = love.physics.newFixture(objects.block27.body, objects.block27.shape, 5)
	
	objects.block28 = {}
	objects.block28.body = love.physics.newBody(world, 275, 1100, "kinematic")
	objects.block28.shape = love.physics.newRectangleShape(0, 0, 50, 360)
	objects.block28.fixture = love.physics.newFixture(objects.block28.body, objects.block28.shape, 5)
	
	--Timer for when the crushing blocks fall
	Timer.addPeriodic(2.5, function() bup=true end)
	Timer.addPeriodic(1.5, function() bup2=true end)
	Timer.addPeriodic(1.9, function() bup3=true end)

	--initial graphics setup
	love.graphics.setBackgroundColor(104, 0, 248) --set the background color to a nice blue (which won't be seen btw)
	love.graphics.setMode(1024, 768, false, true, 0) --set the window dimensions to 1024 by 768
end

function game:update(dt)
	moving = false
	walking = false

	--sets camera position on player
	cam:lookAt(objects.player.body:getX(), objects.player.body:getY())
	camx, camy = cam:pos()
	world:update(dt)
	
	change = yc-objects.player.body:getY()
	
	if objects.player.body:getX()>1200 then
		TEsound.stop("level")
		Gamestate.switch(endgame)
	end
	
	--Death areas
	if objects.player.body:getX()>720 and objects.player.body:getX()<900 and objects.player.body:getY()>250 and objects.player.body:getY()<330 then
		dead=true
	end --First Spikes
	
	if objects.player.body:getX()>-50 and objects.player.body:getX()<250 and objects.player.body:getY()<920 and objects.player.body:getY()>850 then
		dead=true
	end --Second Spikes
	
	if objects.player.body:getX()>-350 and objects.player.body:getX()<-300 and objects.player.body:getY()<1920 and objects.player.body:getY()>1350 then
		dead=true
	end --Bottom Spikes on left
	
	if objects.player.body:getX()>-300 and objects.player.body:getX()<-97 and objects.player.body:getY()<1920 and objects.player.body:getY()>1875 then
		dead=true
	end --Bottom Spikes on very bottom
	
	--lever
	if objects.player.body:getX()>515 and objects.player.body:getX()<600 and objects.player.body:getY()<1592 and objects.player.body:getY()>1550 then
		leveronn=true
	end
	
	if objects.player.body:getX()>515 and objects.player.body:getX()<600 and objects.player.body:getY()<1592 and objects.player.body:getY()>1550 then
		leveronn=true
	end --lever area
	
	if objects.player.body:getX()<objects.block21.body:getX()+76 and objects.player.body:getX()>objects.block21.body:getX()-76 then
		if objects.player.body:getY()<=objects.block21.body:getY()+125 and objects.player.body:getY()>=objects.block21.body:getY()-25 then
			dead=true
		end
	end --moving column right
	
	if objects.player.body:getX()<objects.block20.body:getX()+76 and objects.player.body:getX()>objects.block20.body:getX()-76 then
		if objects.player.body:getY()<=objects.block20.body:getY()+125 and objects.player.body:getY()>=objects.block20.body:getY()-25 then
			dead=true
		end
	end --moving column center
	
	if objects.player.body:getX()<objects.block19.body:getX()+76 and objects.player.body:getX()>objects.block19.body:getX()-76 then
		if objects.player.body:getY()<=objects.block19.body:getY()+125 and objects.player.body:getY()>=objects.block19.body:getY()-25 then
			dead=true
		end
	end --moving column left
	
	
	if objects.block26.body:getAngularVelocity() ~= .75 and objects.player.body:getX()>160 and objects.player.body:getX()<420 and objects.player.body:getY()>1350 and objects.player.body:getY()<1650 then
			dead=true
	end --rotating kill
	
	objects.block26.body:setPosition(260, 1475)
	objects.block26.body:setAngularVelocity(.75)
	
	--this statement locks controls if player is dead
	if dead==false then
	
	--These commands tell the pillars to rise and fall when the timer reaches a ceratin time
	if bup==true then objects.block19.body:applyLinearImpulse(0, -2000) bup=false 
		end
	if bup2==true then objects.block20.body:applyLinearImpulse(0, -3000) bup2=false 
		else objects.block19.body:applyForce(0, -600)
		end
	if bup3==true then objects.block21.body:applyLinearImpulse(0, -4000) bup3=false 
		end
	
	if love.keyboard.isDown("right") then
		objects.player.body:applyForce(400, 0)
		right = true
		left = false
		anim:update(dt) 
		
		moving=true
		standing=false
		
		walking=true
		
		if air==true then 
			moving=false
			if jump==true then
				up = true
			else
				down = true
			end
		end
	end
		
	if love.keyboard.isDown("left") then 
		objects.player.body:applyForce(-400, 0)
		right = false
		left = true
		anim2:update(dt) 
		
		moving=true
		standing=false
		
		walking=true
		
		if air==true then 
			moving=false
			if jump==true then
				up = true
			else
				down = true
			end
		end
	end
		
	if love.keyboard.isDown("up") then
		fx = 0
		fy = 0
		if yc==-9000 then yc = objects.player.body:getY() end

		yc = objects.player.body:getY()
		
		fx, fy = objects.player.body:getLinearVelocity()
		
		if jump then
			if fy>=0 then
				if fy<.01 then
					jump = false
					up = false
					down = true
					objects.player.body:applyLinearImpulse(0, 10)
					
				end
			end
		end
		
		fx, fy = objects.player.body:getLinearVelocity()
		
		if jump==false then
			if fy>=0 then
				if fy<.0001 then
					if change == 0 then
						objects.player.body:applyLinearImpulse(0, -300) 
						jump = true
						up = true
						down = false
						air=true
						TEsound.play("sound/jump.mp3")
					end
				end
			end
		end
		
		
		moving=true
		standing=false
		walking=false
	end
	
	
	fx, fy = objects.player.body:getLinearVelocity()
	
	if moving==false then
		if air==false then
			if fx<700 then
				if fx>-700 then
					objects.player.body:setLinearVelocity(0, fy)
				end
			end
		end
	end
		
		if jump then
			if fy>=0 then
				if fy<.8 then
					jump = false
					up = false
					down = true
					objects.player.body:applyLinearImpulse(0, 10)
				end
			end
		end
		
	fx, fy = objects.player.body:getLinearVelocity()
		
		if jump==false then
			if fy>=0 then
				if fy<.8 then
						up = false
						down = false
						air=false
				end
			end
		end
	
	--If MAFRE is going to slow, then we set him back to a standing position
	if fy>.1 then walking=false moving=false end
	
	if moving==false then 
		if walking==false then
			if air==false then
				if fy>.1 then
					standing=true
					down = true
				else
					if fx==0 then
						standing=true 
						down = false
					else
						walking=true
						moving=true
						standing=false
						if right==true then anim:update(dt)
						else anim2:update(dt) end
					end
				end
			end
		end
	end
	
	--Sets debugger text as player position
	if checker then
			text =  objects.player.body:getX() .. " " .. objects.player.body:getY()
		else
			text = " "
		end
	
	
	if first then
		standing = true
		right = true
		if fx ~= 0 then
			first=false
		end
	end
	end
	
	if dead==true then
		if play_dead == true then
			TEsound.play("sound/dead.mp3")
			play_dead = false
		end
		anim_dead:update(dt)
		--This is the timer that is causing the problem (see glitch #1)
		Timer.add(1, function() reset() end)
	end
	
	if leveronn == true then objects.block28.body:setActive(false) else objects.block28.body:setActive(true) end
	
	Timer.update(dt)
	TEsound.cleanup()
end

function game:draw()
    --Sets the camera onto the player
	cam:attach()

	love.graphics.setColor(255, 255, 255)
	
	love.graphics.setColor(72, 160, 14)
	
	love.graphics.setColor(255,255,255)
	
	--Makes it so that the background stays in place
	love.graphics.draw(bk, camx-512, camy-384)
	
	if leveronn==false then love.graphics.draw(lever, 525, 1575)
	else love.graphics.draw(leveron, 525, 1575)
	end
	
	if dead==true then
		yc = -9000
		change = 0
		jump = false
		jumping = false
		left = false
		right = false
		standing = true
		air = false
		up = false
		mid = false
		down = false
		walking= false
		first = true
		bup = false
		bup2 = false
		bup3 = false
		anim_dead:draw(objects.player.body:getX()-45, objects.player.body:getY()-50) 
	end
	
	if right==true then 
		if up then
			love.graphics.draw(imageJumpingUp, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingUp:getWidth()/2, imageJumpingUp:getHeight()/2+5) 
		end
		if walking then
			if up==false then 
				if down==false then
					anim:draw(objects.player.body:getX()-45, objects.player.body:getY()-40) 
				end
			end
		end
		if down then
					love.graphics.draw(imageJumpingDown, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingDown:getWidth()/2, imageJumpingDown:getHeight()/2+5) 
		end
	end
	if left ==true then 
		if up then
			love.graphics.draw(imageJumpingUpLeft, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingUpLeft:getWidth()/2, imageJumpingUpLeft:getHeight()/2+5) 
		end
		if walking then
			if up==false then 
				if down==false then
					anim2:draw(objects.player.body:getX()-45, objects.player.body:getY()-40) 
				end
			end
		end
		if down then
					love.graphics.draw(imageJumpingDownLeft, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingDownLeft:getWidth()/2, imageJumpingDownLeft:getHeight()/2+5) 
		end
	end
	if standing==true then 	
		if right == true then
			if down == true then
				love.graphics.draw(imageJumpingDown, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingDown:getWidth()/2, imageJumpingDown:getHeight()/2+5) 	
			else
				love.graphics.draw(imageStanding, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageStanding:getWidth()/2, imageStanding:getHeight()/2+5) 
			end
		end
		if left == true then
			if down == true then
				love.graphics.draw(imageJumpingDownLeft, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageJumpingDownLeft:getWidth()/2, imageJumpingDownLeft:getHeight()/2+5)
			else
				love.graphics.draw(imageStandingLeft, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle() , 1, 1, imageStandingLeft:getWidth()/2, imageStandingLeft:getHeight()/2+5)
			end
		end
	end
	love.graphics.setColor(193, 47, 14)
	
	love.graphics.setColor(50, 50, 50) -- set the drawing color to grey for the blocks
	x1=0
	y1=0
	
	--draws all of our spikes
	love.graphics.draw(spikes, 650, 275)
	love.graphics.draw(spikes, 700, 275)
	love.graphics.draw(spikes, 750, 275)
	love.graphics.draw(spikes, 800, 275)
	love.graphics.draw(spikes, 850, 275)
	
	love.graphics.draw(spikes, -10, 875)
	love.graphics.draw(spikes, 40, 875)
	love.graphics.draw(spikes, 90, 875)
	love.graphics.draw(spikes, 140, 875)
	love.graphics.draw(spikes, -60, 875)
	
	love.graphics.draw(spikes, -400, 1875)
	love.graphics.draw(spikes, -350, 1875)
	love.graphics.draw(spikes, -300, 1875)
	love.graphics.draw(spikes, -250, 1875)
	love.graphics.draw(spikes, -200, 1875)
	
	love.graphics.draw(spikesright, -400, 1300)
	love.graphics.draw(spikesright, -400, 1350)
	love.graphics.draw(spikesright, -400, 1400)
	love.graphics.draw(spikesright, -400, 1450)
	love.graphics.draw(spikesright, -400, 1500)
	love.graphics.draw(spikesright, -400, 1550)
	love.graphics.draw(spikesright, -400, 1600)
	love.graphics.draw(spikesright, -400, 1650)
	love.graphics.draw(spikesright, -400, 1700)
	love.graphics.draw(spikesright, -400, 1750)
	love.graphics.draw(spikesright, -400, 1800)
	love.graphics.draw(spikesright, -400, 1850)
	love.graphics.draw(spikesright, -400, 1900)
	
	--drwas all of our blocks
	love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
	love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))
	love.graphics.polygon("fill", objects.block3.body:getWorldPoints(objects.block3.shape:getPoints()))
	love.graphics.polygon("fill", objects.block4.body:getWorldPoints(objects.block4.shape:getPoints()))
	love.graphics.polygon("fill", objects.block5.body:getWorldPoints(objects.block5.shape:getPoints()))
	love.graphics.polygon("fill", objects.block6.body:getWorldPoints(objects.block6.shape:getPoints()))
	love.graphics.polygon("fill", objects.block7.body:getWorldPoints(objects.block7.shape:getPoints()))
	love.graphics.polygon("fill", objects.block8.body:getWorldPoints(objects.block8.shape:getPoints()))
	love.graphics.polygon("fill", objects.block9.body:getWorldPoints(objects.block9.shape:getPoints()))
	love.graphics.polygon("fill", objects.block10.body:getWorldPoints(objects.block10.shape:getPoints()))
	love.graphics.polygon("fill", objects.block11.body:getWorldPoints(objects.block11.shape:getPoints()))
	love.graphics.polygon("fill", objects.block12.body:getWorldPoints(objects.block12.shape:getPoints()))
	love.graphics.polygon("fill", objects.block13.body:getWorldPoints(objects.block13.shape:getPoints()))
	love.graphics.polygon("fill", objects.block14.body:getWorldPoints(objects.block14.shape:getPoints()))
	love.graphics.polygon("fill", objects.block15.body:getWorldPoints(objects.block15.shape:getPoints()))
	love.graphics.polygon("fill", objects.block16.body:getWorldPoints(objects.block16.shape:getPoints()))
	love.graphics.polygon("fill", objects.block17.body:getWorldPoints(objects.block17.shape:getPoints()))
	love.graphics.polygon("fill", objects.block18.body:getWorldPoints(objects.block18.shape:getPoints()))
	love.graphics.setColor(200, 0, 0) -- red,green,blue
	love.graphics.polygon("fill", objects.block19.body:getWorldPoints(objects.block19.shape:getPoints()))
	love.graphics.polygon("fill", objects.block20.body:getWorldPoints(objects.block20.shape:getPoints()))
	love.graphics.polygon("fill", objects.block21.body:getWorldPoints(objects.block21.shape:getPoints()))
	love.graphics.setColor(50, 50, 50)
	love.graphics.polygon("fill", objects.block22.body:getWorldPoints(objects.block22.shape:getPoints()))
	love.graphics.polygon("fill", objects.block23.body:getWorldPoints(objects.block23.shape:getPoints()))
	love.graphics.polygon("fill", objects.block24.body:getWorldPoints(objects.block24.shape:getPoints()))
	love.graphics.polygon("fill", objects.block25.body:getWorldPoints(objects.block25.shape:getPoints()))
	love.graphics.setColor(200, 0, 0) -- red,green,blue
	love.graphics.polygon("fill", objects.block26.body:getWorldPoints(objects.block26.shape:getPoints()))
	love.graphics.setColor(50, 50, 50)
	love.graphics.polygon("fill", objects.block27.body:getWorldPoints(objects.block27.shape:getPoints()))
	love.graphics.setColor(0, 0, 200) -- red,green,blue
	if leveronn==false then love.graphics.polygon("fill", objects.block28.body:getWorldPoints(objects.block28.shape:getPoints())) end
	love.graphics.setColor(50, 50, 50)
	
	love.graphics.printf(text, objects.player.body:getX(), objects.player.body:getY()-100, 800)

	
	cam:detach()
end

function game:keypressed(key, u)
   --Debug
   if key == "f12" then
      if(checker==true) then checker = false 
	  else checker = true end
   end
   --Exit
   if key == "escape" then
	  love.event.push("quit")
   end
   --Reset
   if key == "r" then
	  reset()
   end
   --Complete level
   if key == "s" then
	  dead = false
	  leveronn = false
	  objects.player.body:setPosition(-150, 900)
	  objects.player.body:setLinearVelocity(1,1)
   end
   --Plays the jump sound effect
   if key== "m" then
    TEsound.play("sound/select.mp3")
	
	TEsound.playLooping("menu/maintheme.mp3", "main")
	TEsound.stop("level")
	Gamestate.switch(menu)
	end

end

--Sends the player back to the beginning
function reset()
	dead = false
	play_dead = true
	leveronn = false
	objects.player.body:setPosition(100, 200)
	objects.player.body:setLinearVelocity(1,1)
end