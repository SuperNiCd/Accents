-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local GainBias = require "Unit.ViewControl.GainBias"
local Utils = require "Utils"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local MotionSensor = Class{}
MotionSensor:include(Unit)

function MotionSensor:init(args)
  args.title = "Motion Sensor"
  args.mnemonic = "MS"
  Unit.init(self,args)
end

function MotionSensor:onLoadGraph()
  -- create objects
  local compare = self:createObject("Comparator","compare")
  local invert = self:createObject("Multiply","invert")
  local negOne = self:createObject("Constant","negOne")
  local sum = self:createObject("Sum","sum")
  local rectify = self:createObject("Rectify","rectify")
  local delay = self:createObject("Delay","delay",1)
  local env = self:createObject("EnvelopeFollower","env")
  local release = self:createObject("ParameterAdapter","release")
  local attack = self:createObject("ParameterAdapter","attack")
  local pregain = self:createObject("Multiply","pregain")
  local preGainAmt = self:createObject("Constant","preGainAmt")
  local gain = self:createObject("Multiply","gain")
  local level = self:createObject("GainBias","level")
  local levelRange = self:createObject("MinMax","levelRange")

  -- set parameters
  compare:setGateMode()
  compare:hardSet("Threshold",0.010)
  compare:hardSet("Hysteresis",0.00)
  negOne:hardSet("Value",-1.0)
  rectify:optionSet("Type",3) --full rectification
  self:setMaxDelayTime(0.1)
  delay:hardSet("Left Delay",0.001)
  preGainAmt:hardSet("Value",4.0)

  -- connect inputs/outputs
  connect(self,"In1",sum,"Left")
  connect(self,"In1",invert,"Left")
  connect(negOne,"Out",invert,"Right")
  connect(invert,"Out",delay,"Left In")
  connect(delay,"Left Out",sum,"Right")
  connect(sum,"Out",rectify,"In")
  connect(rectify,"Out",env,"In")
  connect(level,"Out",levelRange,"In")
  connect(level,"Out",gain,"Left")
  connect(env,"Out", pregain,"Left")
  connect(preGainAmt,"Out",pregain,"Right")
  connect(pregain,"Out",gain,"Right")
  connect(gain,"Out",compare,"In")
  connect(compare,"Out",self,"Out1")

  -- tie parameters
  tie(env,"Release Time",release,"Out")
  tie(env,"Attack Time",attack,"Out")

  -- register exported ports
  self:createMonoBranch("release",release,"In",release,"Out")
  self:createMonoBranch("attack",attack,"In",attack,"Out")
  self:createMonoBranch("level",level,"In",level,"Out")
end

local views = {
  expanded = {"input","level","attack","release","mode"},
  collapsed = {},
  input = {"scope","input"}
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local sensMap = linMap(0,100,1,0.1,0.01,0.001)

function MotionSensor:onLoadViews(objects,branches)
  local controls = {}

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    unit = self,
    comparator = objects.compare,
  }

  controls.level = GainBias {
    button = "sens",
    branch = branches.level,
    description = "Level",
    gainbias = objects.level,
    range = objects.levelRange,
    biasMap = sensMap,
    biasUnits = app.unitNone,
    initialBias = 50.0,
    gainMap = Encoder.getMap("gain"),
  }

  controls.attack = GainBias {
    button = "attack",
    description = "Attack Time",
    branch = branches.attack,
    gainbias = objects.attack,
    range = objects.attack,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.5
  }

  controls.release = GainBias {
    button = "release",
    description = "Release Time",
    branch = branches.release,
    gainbias = objects.release,
    range = objects.release,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.5
  }

  controls.mode = ModeSelect {
    button = "o",
    description = "Type",
    option = objects.compare:getOption("Mode"),
    choices = {"toggle","gate","trigger"},
    muteOnChange = true
  }

  return controls, views
end

function MotionSensor:setMaxDelayTime(secs)
    local requested = Utils.round(secs,1)
    local allocated = self.objects.delay:allocateTimeUpTo(requested)
  end

return MotionSensor
