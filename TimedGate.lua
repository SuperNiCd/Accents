local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local MenuHeader = require "Unit.MenuControl.Header"
local Task = require "Unit.MenuControl.Task"
local InputGate = require "Unit.ViewControl.InputGate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local TimedGate = Class{}
TimedGate:include(Unit)

function TimedGate:init(args)
  args.title = "Timed Gate"
  args.mnemonic = "TG"
  Unit.init(self,args)
end

function TimedGate:onLoadGraph(channelCount)
  --create objects
  local skewedsin = self:addObject("skewedsin",libcore.SkewedSineEnvelope())
  local limiter = self:addObject("limiter",libcore.Limiter())
  local gain = self:addObject("gain",app.Multiply())
  local thirtyK = self:addObject("thirtyK",app.Constant())
  local durationSum = self:addObject("durationSum",app.Sum())
  local retrigSum = self:addObject("retrigSum",app.Sum())
  local invertVCA = self:addObject("invertVCA",app.Multiply())
  local feedbackVCA = self:addObject("feedbackVCA",app.Multiply())
  local negOne = self:addObject("negOne",app.Constant())
  local one = self:addObject("one",app.Constant())
  local feedbackConst = self:addObject("feedbackConst",app.Constant())
  local durationAdapter = self:addObject("durationAdapter",app.ParameterAdapter())
  local t1 = self:addObject("t1",app.GainBias())
  local t2 = self:addObject("t2",app.GainBias())
  local t1Range = self:addObject("t1Range",app.MinMax())
  local t2Range = self:addObject("t2Range",app.MinMax())
  local trig = self:addObject("trig",app.Comparator())

  trig:setTriggerMode()
  thirtyK:hardSet("Value",30000)
  negOne:hardSet("Value",-1.0)
  feedbackConst:hardSet("Value",1.0)
  durationAdapter:hardSet("Gain",1.0)
  limiter:setOptionValue("Type",3)
  one:hardSet("Value",1.0)
  skewedsin:hardSet("Skew",0.0)

  -- register exported ports
  self:addMonoBranch("durs",t1,"In",t1,"Out")
  self:addMonoBranch("durms",t2,"In",t2,"Out")

  -- connect objects
  connect(one,"Out",skewedsin,"Level")
  connect(self,"In1",retrigSum,"Left")
  connect(retrigSum,"Out",trig,"In")
  connect(trig,"Out",skewedsin,"Trigger")
  connect(skewedsin,"Out",gain,"Left")
  connect(thirtyK,"Out",gain,"Right")
  connect(gain,"Out",limiter,"In")
  connect(limiter,"Out",self,"Out1")
  connect(limiter,"Out",invertVCA,"Left")
  connect(negOne,"Out",invertVCA,"Right")
  connect(invertVCA,"Out",feedbackVCA,"Left")
  connect(feedbackConst,"Out",feedbackVCA,"Right")
  connect(feedbackVCA,"Out",retrigSum,"Right")

  connect(t1,"Out",durationSum,"Left")
  connect(t2,"Out",durationSum,"Right")

  connect(t1,"Out",t1Range,"In")
  connect(t2,"Out",t2Range,"In")

  connect(durationSum,"Out",durationAdapter,"In")
  tie(skewedsin,"Duration",durationAdapter,"Out")

  if channelCount>1 then
    connect(limiter,"Out",self,"Out2")
  end

end

local views = {
  expanded = {"input","durs","durms"},
  collapsed = {},
}

local function intMap(min,max)
  local map = app.LinearDialMap(min,max)
  map:setSteps(5,1,0.25,0.25);
  map:setRounding(1)
  return map
end

local secMap = intMap(0,300)

function TimedGate:onLoadViews(objects,branches)
  local controls = {}

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    unit = self,
    comparator = objects.trig,
  }

  controls.durs = GainBias {
    button = "coarse",
    description = "Duration sec",
    branch = branches.durs,
    gainbias = objects.t1,
    range = objects.t1Range,
    biasMap = secMap,
    biasUnits = app.unitSecs,
    initialBias = 0.0,
  }

  controls.durms = GainBias {
    button = "fine",
    description = "Duration msec",
    branch = branches.durms,
    gainbias = objects.t2,
    range = objects.t2Range,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.5,
  }

  return controls, views
end

local menu = {
  "setHeader",
  "ignore",
  "retrig",
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function TimedGate:onShowMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Retrigger Mode: %s.",self.mode)
  }

  controls.ignore = Task {
    description = "ignore",
    task = function()
      self:setMode("ignore")
    end
  }

  controls.retrig = Task {
    description = "extend",
    task = function()
      self:setMode("extend")
    end
  }
  return controls, menu
end

function TimedGate:setMode(mode)
  self.mode = mode
  local objects = self.objects
  if mode=="ignore" then
    objects.feedbackConst:hardSet("Value",1.0)
  elseif mode=="extend" then
    objects.feedbackConst:hardSet("Value",0.0)
  end
end

function TimedGate:onLoadFinished()
  self:setMode("ignore")
end

function TimedGate:serialize()
  local t = Unit.serialize(self)
  t.timedGateMode = self.mode
  return t
end

function TimedGate:deserialize(t)
  Unit.deserialize(self,t)
  if t.timedGateMode then
    self:setMode(t.timedGateMode)
  end
end

return TimedGate
