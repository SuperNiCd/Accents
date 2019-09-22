-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
-- local ModeSelect = require "Unit.MenuControl.OptionControl"
local MenuHeader = require "Unit.MenuControl.Header"
local Task = require "Unit.MenuControl.Task"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
-- local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local VoltageBank4 = Class{}
VoltageBank4:include(Unit)

function VoltageBank4:init(args)
  args.title = "Voltage Bank"
  args.mnemonic = "VB"
  Unit.init(self,args)
end

function VoltageBank4:onLoadGraph(channelCount)
  -- create objects

  -- Create network objects
  local localVars = {}
  local numSlots = 4

  -- define the different objects to be mass created
  local objectList = {
    sh = { "TrackAndHold" },
    shOut = { "Multiply" },
    shTrack = { "Multiply" },
    shMix = { "Sum" },
    bump  = { "BumpMap" },
  }

  for k, v in pairs(objectList) do
    for i = 1, numSlots do
      local dynamicVar = k .. i
      local dynamicDSPUnit = v[1]
      localVars[dynamicVar] = self:createObject(dynamicDSPUnit,dynamicVar)
    end
  end

  local index = self:createObject("GainBias","index")
  index:hardSet("Gain",1.0)
  local indexRange = self:createObject("MinMax","indexRange")
  local trig = self:createObject("Comparator","trig")
  local divIndex = self:createObject("ConstantGain","divIndex")

  local bypass = self:createObject("Comparator","bypass")
  local invertingVCA = self:createObject("Multiply","invertingVCA")
  local negOne = self:createObject("ConstantOffset","negOne")
  local one = self:createObject("ConstantOffset","one")
  local bypassSum = self:createObject("Sum","bypassSum")
  bypass:setToggleMode()
  negOne:hardSet("Offset",-1.0)
  one:hardSet("Offset",1.0)

  divIndex:hardSet("Gain",1/numSlots)
  self:createMonoBranch("trig",trig,"In",trig,"Out")
  self:createMonoBranch("index",index,"In",index,"Out")
  self:createMonoBranch("bypass",bypass,"In",bypass,"Out")

  local bumpMapWidth = 1 / numSlots
  local bumpMapOffset = bumpMapWidth / 2

  local bumpOffset = self:createObject("ConstantOffset","bumpOffset")
  bumpOffset:hardSet("Offset",-bumpMapOffset)

  local inToOutVCA = self:createObject("Multiply","inToOutVCA")
  local inToOutVCAConst = self:createObject("Constant","inToOutVCAConst")
  inToOutVCAConst:hardSet("Value",0.0)
  local indexToOutVCA = self:createObject("Multiply","indexToOutVCA")
  local indexToOutVCAConst = self:createObject("Constant","indexToOutVCAConst")
  indexToOutVCAConst:hardSet("Value",1.0)
  local outputMixer = self:createObject("Sum","outputMixer")

  -- set bump map properties
  for i = 1, numSlots do
    localVars["bump" .. i]:hardSet("Height",1.0)
    localVars["bump" .. i]:hardSet("Fade",0.0)
    localVars["bump" .. i]:hardSet("Width",bumpMapWidth)
    localVars["bump" .. i]:hardSet("Center",(bumpMapWidth*i)-bumpMapOffset)
  end

  -- connect objects
  connect(index,"Out",indexRange,"In")
  connect(index,"Out",divIndex,"In")
  connect(divIndex,"Out",bumpOffset,"In")
  connect(localVars["shOut1"],"Out",localVars["shMix1"],"Left")
  connect(localVars["shOut2"],"Out",localVars["shMix1"],"Right")

  for i = 1, numSlots do
    connect(bumpOffset,"Out",localVars["bump" .. i],"In")
    connect(self,"In1",localVars["sh" .. i],"In")
    connect(trig,"Out",localVars["shTrack" .. i],"Left")
    connect(localVars["bump" .. i],"Out",localVars["shTrack" .. i],"Right")
    connect(localVars["shTrack" .. i],"Out",localVars["sh" .. i],"Track")
    connect(localVars["sh" .. i],"Out",localVars["shOut" .. i],"Left")
    connect(localVars["bump" .. i],"Out",localVars["shOut" .. i],"Right")
    if i < numSlots - 1 then
      connect(localVars["shMix" .. i],"Out",localVars["shMix" .. i + 1],"Left")
      connect(localVars["shOut" .. i + 2],"Out",localVars["shMix" .. i + 1],"Right")
    end
  end

  connect(localVars["shMix" .. numSlots-1],"Out",indexToOutVCA,"Left")
  -- connect(indexToOutVCAConst,"Out",indexToOutVCA,"Right")
  connect(negOne,"Out",invertingVCA,"Left")
  connect(bypass,"Out",invertingVCA,"Right")
  connect(invertingVCA,"Out",bypassSum,"Left")
  connect(one,"Out",bypassSum,"Right")
  connect(bypassSum,"Out",indexToOutVCA,"Right")
  connect(indexToOutVCA,"Out",outputMixer,"Left")
  connect(self,"In1",inToOutVCA,"Left")
  -- connect(inToOutVCAConst,"Out",inToOutVCA,"Right")
  connect(bypass,"Out",inToOutVCA,"Right")
  connect(inToOutVCA,"Out",outputMixer,"Right")
  connect(outputMixer,"Out",self,"Out1")
end

local menu = {
  "setHeader",
  "index",
  "input",
  "sum",
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

-- function VoltageBank:setOp(op)
--   local objects = self.objects
--   self.op = op

--   if op=="index" then
--     objects.inToOutVCAConst:hardSet("Value",0.0)
--     objects.indexToOutVCAConst:hardSet("Value",1.0)
--   elseif op=="input" then
--     objects.inToOutVCAConst:hardSet("Value",1.0)
--     objects.indexToOutVCAConst:hardSet("Value",0.0)
--   elseif op=="sum" then
--     objects.inToOutVCAConst:hardSet("Value",1.0)
--     objects.indexToOutVCAConst:hardSet("Value",1.0)
--   end
-- end

-- function VoltageBank:onLoadFinished()
--   self:setOp("index")
-- end

function VoltageBank4:serialize()
  local t = Unit.serialize(self)
  t.voltageBankOp = self.op
  return t
end

function VoltageBank4:deserialize(t)
  Unit.deserialize(self,t)
  if t.voltageBankOp then
    self:setOp(t.voltageBankOp)
  end
end

-- function VoltageBank:onLoadMenu(objects,branches)
--   local controls = {}

--   controls.setHeader = MenuHeader {
--     description = string.format("Output signal: %s.",self.op)
--   }

--   controls.index = Task {
--     description = "index",
--     task = function()
--       self:setOp("index")
--     end
--   }

--   controls.input = Task {
--     description = "input",
--     task = function()
--       self:setOp("input")
--     end
--   }

--   controls.sum = Task {
--     description = "sum",
--     task = function()
--       self:setOp("sum")
--     end
--   }

--   return controls, menu
-- end

local function intMap(min,max)
  local map = app.LinearDialMap(min,max)
  map:setSteps(5,1,0.25,0.25);
  map:setRounding(1)
  return map
end

local indexMap = intMap(1,4)  -- adjust max param for numSlots

local views = {
  expanded = {"trigger","index","bypass"},
  collapsed = {},
}

function VoltageBank4:onLoadViews(objects,branches)
  local controls = {}

  controls.trigger = Gate {
    button = "trig",
    branch = branches.trig,
    description = "Trigger",
    comparator = objects.trig,
  }

  controls.index = GainBias {
    button = "index",
    description = "Bank Slot",
    branch = branches.index,
    gainbias = objects.index,
    range = objects.indexRange,
    biasMap = indexMap,
    biasPrecision = 0,
    gainMap = indexMap,
    initialBias = 1,
  }

  controls.bypass = Gate {
    button = "bypass",
    description = "Pass thru Input",
    branch = branches.bypass,
    comparator = objects.bypass,
  }

  return controls, views
end

return VoltageBank4
