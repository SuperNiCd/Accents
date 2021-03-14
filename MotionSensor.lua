local app = app
local libcore = require "core.libcore"
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
  local compare = self:addObject("compare",app.Comparator())
  local invert = self:addObject("invert",app.Multiply())
  local negOne = self:addObject("negOne",app.Constant())
  local sum = self:addObject("sum",app.Sum())
  local rectify = self:addObject("rectify",libcore.Rectify())
  local delay = self:addObject("delay",libcore.Delay(1))
  local env = self:addObject("env",libcore.EnvelopeFollower())
  local release = self:addObject("release",app.ParameterAdapter())
  local attack = self:addObject("attack",app.ParameterAdapter())
  local pregain = self:addObject("pregain",app.Multiply())
  local preGainAmt = self:addObject("preGainAmt",app.Constant())
  local gain = self:addObject("gain",app.Multiply())
  local level = self:addObject("level",app.GainBias())
  local levelRange = self:addObject("levelRange",app.MinMax())

  -- set parameters
  compare:setGateMode()
  compare:hardSet("Threshold",0.010)
  compare:hardSet("Hysteresis",0.00)
  negOne:hardSet("Value",-1.0)
  rectify:setOptionValue("Type",3) --full rectification
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
  self:addMonoBranch("release",release,"In",release,"Out")
  self:addMonoBranch("attack",attack,"In",attack,"Out")
  self:addMonoBranch("level",level,"In",level,"Out")
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
