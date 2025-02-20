-- Computercraft script: 

-- Mekanism Digital Miner Automator version 2.1 for Minecraft 1.20.1 
-- (or maybe even anything above 1.12.2 with slight edits to the Blocks section) 
-- Original Script by MartiNJ409 - https://github.com/martinjanas
-- The original script can be found at - https://github.com/martinjanas/DigitalMinerAutomatization
 
-- This script places & destroys miner, energy block, storage block, chatbox and chunkloader.
-- It can also output miner status to the chat, visible to anyone on servers, can be turned off below in Settings.
-- Also works on AdvancedPeriperals's chunky turtle, so no need for chunkloader.
 
-- Just place all the required blocks into the turtle.
-- No need to use chunkloader if you are using chunky turtle, chat box is not mandatory.

-- I'm honestly too lazy to write documentation for the edits I made. I will do so eventually, but for now
-- I'm putting this on GitHub purely so that I can use it myself :)

-- edits by hidngem - https://github.com/HidnGemini
-- This script can be found at https://github.com/HidnGemini/DigitalMinerAutomatization
 
-- User Settings Area --
Settings = {}
Settings.MAX_CHUNKS = 16 -- The amount of chunks this script will run. (Default 16)
Settings.SEND_TO_CHAT = true -- Set this to false if you don't wish for the chatbox to send serverwide messages about the mining status.

Blocks = {}
Blocks.BLOCK_MINER = "mekanism:digital_miner"
Blocks.BLOCK_ENERGY = "mekanism:quantum_entangloporter" -- Edit this to match your desired block.
Blocks.BLOCK_STORAGE = "mekanism:quantum_entangloporter" -- Edit this to match your desired block.
Blocks.BLOCK_CHUNKLOADER = "chickenchunks:chunk_loader" -- Edit this to match your desired block.
Blocks.BLOCK_CHATBOX = "advancedperipherals:chat_box" -- Edit this only if you are porting to newer/older versions.
-- User Settings Area --

-- Dont touch this if you don't know what you are doing:
local List = require "lib/list"
GlobalVars = {}
GlobalVars.m_pMiner = nil
GlobalVars.m_pChatBox = nil
GlobalVars.m_bHasChunkLoader = false
GlobalVars.m_bIsChunkyTurtle = false
GlobalVars.m_bHasChatBox = false
local MOTEM_SLOT = 16
local MESSAGE_RECIPIENT = 11

-- added refueling
local STORAGE_SLOTS = List(1,2,3,4,5,6,7,8,9,10,11,12,13)
local function refuel()
   local slot = turtle.getSelectedSlot()
   for i in STORAGE_SLOTS() do
     local item = turtle.getItemDetail(i)
     if item and item.name:find("coal") then
       turtle.select(i)
       turtle.refuel()
     end
     if turtle.getFuelLevel() >= 600 then
       return
     end
   end
   turtle.select(slot)
 end

function swapItem()
   local old_slot = turtle.getSelectedSlot()

   turtle.select(MOTEM_SLOT)
   turtle.equipLeft()
   turtle.select(old_slot)
end

function sendMessage(message)
   swapItem()
   rednet.open("left")
   rednet.send(MESSAGE_RECIPIENT, message)
   swapItem()
end

function sendPosition(message)
   swapItem()
   local x,y,z = gps.locate()
   local text = string.format("I'm all done at %d,%d,%d", x, y, z)
   swapItem()
   sendMessage(text)
end

-- original main function
function main(i)

   refuel()

   require "utils"

   GlobalVars.m_bIsChunkyTurtle = utils_is_chunky_turtle()

   utils_place_blocks(Blocks, GlobalVars)

   os.sleep(0.15)

   if GlobalVars.m_pMiner then
      GlobalVars.m_pMiner.start()

      local to_mine_cached = GlobalVars.m_pMiner.getToMine()

      while GlobalVars.m_pMiner.isRunning() do
         local to_mine = GlobalVars.m_pMiner.getToMine()
         local seconds = (to_mine * 0.5)

         if Settings.SEND_TO_CHAT then
            local percentage = (to_mine / to_mine_cached) * 100
            percentage = math.floor(percentage)

            if utils_percentage_in_range(percentage, 50, 1) then
               local text = string.format("50%% of Blocks Mined (%d/%d)", to_mine, to_mine_cached)
               sendMessage(text)
               os.sleep(2)
            end

         end

         if to_mine % 5 then
            local text = string.format("To mine: %d, ETA: %s", to_mine, utils_get_time(seconds))
		      print(text)
         end

         if (to_mine == 0) then
            if Settings.SEND_TO_CHAT then
               local text = string.format("Done (%d/%d) rounds", i, Settings.MAX_CHUNKS)
               sendMessage(text)
               os.sleep(1)
            end
                
            if i == Settings.MAX_CHUNKS and Settings.SEND_TO_CHAT then
               sendPosition()
               os.sleep(1)
            end

            utils_destroy_blocks(GlobalVars)

            os.sleep(2)

            turtle.turnRight()
            utils_go_one_chunk()
            utils_go_one_chunk()
         end

         os.sleep(0.5)
      end
   end
end

function setup()
   if not fs.exists("utils.lua") then
      shell.run("wget https://raw.githubusercontent.com/HidnGemini/DigitalMinerAutomatization/main/utils.lua")
   end
end

done = false

for i = 1, Settings.MAX_CHUNKS do
   if not done then
      setup()
      done = true
   end

   GlobalVars.m_bIsChunkyTurtle = false
   GlobalVars.m_bHasChunkLoader = false
   GlobalVars.m_bHasChatBox = false
    
   main(i)
end