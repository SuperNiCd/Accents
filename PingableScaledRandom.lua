-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Gate = require "Unit.ViewControl.Gate"
local GainBias = require "Unit.ViewControl.GainBias"
local Fader = require "Unit.ViewControl.Fader"
local Task = require "Unit.MenuControl.Task"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local PingableScaledRandom = Class{}
PingableScaledRandom:include(Unit)

function PingableScaledRandom:init(args)
  args.title = "Pingable Scaled Random"
  args.mnemonic = "SR"
  Unit.init(self,args)
end

function PingableScaledRandom:onLoadGraph(channelCount)

  --random block
  local random=self:createObject("WhiteNoise","random")
  local hold = self:createObject("TrackAndHold","hold")
  local comparator = self:createObject("Comparator","comparator")
  local scale = self:createObject("Multiply","scale")
  local scaleAmt = self:createObject("ConstantOffset","scaleAmt")
  local scaleLevel = self:createObject("ParameterAdapter","scaleLevel")
  local offset = self:createObject("ConstantOffset","offset")
  local offsetLevel = self:createObject("ParameterAdapter","offsetLevel")
  local quantize = self:createObject("GridQuantizer", "quantize")
  local quantVCA = self:createObject("Multiply", "quantVCA")
  local noQuantVCA = self:createObject("Multiply","noQuantVCA")
  local mix = self:createObject("Sum","mix")
  local quantVCASelector = self:createObject("Constant","quantVCASelector")
  local noQuantVCASelector = self:createObject("Constant","noQuantVCASelector")

  comparator:setTriggerMode()
  quantVCASelector:hardSet("Value",0.0)
  noQuantVCASelector:hardSet("Value",1.0)

  tie(scaleAmt,"Offset",scaleLevel,"Out")
  tie(offset,"Offset",offsetLevel,"Out")

  -- connect objects
  connect(comparator,"Out",hold,"Track")
  connect(random,"Out",hold,"In")
  connect(hold,"Out",quantize,"In")
  --quantized branch
  connect(quantize,"Out",quantVCA,"Left")
  connect(quantVCASelector,"Out",quantVCA,"Right")
  connect(quantVCA,"Out",mix,"Left")
  --unquantized branch
  connect(hold,"Out",noQuantVCA,"Left")
  connect(noQuantVCASelector,"Out",noQuantVCA,"Right")
  connect(noQuantVCA,"Out",mix,"Right")
  --merge branches
  connect(mix,"Out",scale,"Left")
  connect(scaleAmt,"Out",scale,"Right")
  connect(scale,"Out",offset,"In")
  connect(offset,"Out",self,"Out1")

  if channelCount>1 then
    connect(offset,"Out",self,"Out2")
  end

  -- register exported ports
  self:createMonoBranch("trig",comparator,"In",comparator,"Out")
  self:createMonoBranch("scalelvl",scaleLevel,"In",scaleLevel,"Out")
  self:createMonoBranch("offset",offsetLevel,"In",offsetLevel,"Out")
end

local views = {
  expanded = {"trigger","levels","scale","offset"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local scaleMap = linMap(0,1,0.1,0.01,0.001,0.001)
local offsetMap = linMap(-1,1,0.1,0.01,0.001,0.001)

function PingableScaledRandom:onLoadViews(objects,branches)
  local controls = {}

  controls.trigger = Gate {
    button = "trig",
    branch = branches.trig,
    description = "Trigger",
    comparator = objects.comparator,
  }
  controls.scale = GainBias {
    button = "scale",
    description = "Attenuation",
    branch = branches.scalelvl,
    gainbias = objects.scaleLevel,
    range = objects.scaleLevel,
    biasMap = scaleMap,
    biasUnits = app.unitNone,
    initialBias = 1.0
  }
  controls.offset = GainBias {
    button = "offset",
    description = "Offset",
    branch = branches.offset,
    gainbias = objects.offsetLevel,
    range = objects.offsetLevel,
    biasMap = offsetMap,
    biasUnits = app.unitNone,
    initialBias = 0.0
  }
  controls.levels = Fader {
    button = "levels",
    description = "Quant Levels",
    param = objects.quantize:getParameter("Levels"),
    monitor = self,
    map = Encoder.getMap("int[1,256]"),
    precision = 0
  }

  return controls, views
end

local menu = {
  "setHeader",
  "setControlsNo",
  "setControlsYes",
  "infoHeader",
  "rename",
  "load",
  "save"
}

function PingableScaledRandom:onLoadMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Quantize Output: %s.",self.controlMode)
  }

  controls.setControlsNo = Task {
    description = "no",
    task = function() self:changeControlMode("no") end
  }

  controls.setControlsYes = Task {
    description = "yes",
    task = function() self:changeControlMode("yes") end
  }

  return controls, menu
end

function PingableScaledRandom:changeControlMode(mode)
  self.controlMode = mode
  local objects = self.objects
  if mode=="no" then
    objects.quantVCASelector:hardSet("Value",0.0)
    objects.noQuantVCASelector:hardSet("Value",1.0)
  else
    objects.quantVCASelector:hardSet("Value",1.0)
    objects.noQuantVCASelector:hardSet("Value",0.0)
  end
end

function PingableScaledRandom:onLoadFinished()
  self:changeControlMode("no")
end

function PingableScaledRandom:serialize()
  local t = Unit.serialize(self)
  t.controlMode = self.controlMode
  return t
end

function PingableScaledRandom:deserialize(t)
  Unit.deserialize(self,t)
  if t.controlMode then
    self:changeControlMode(t.controlMode)
  end
end

return PingableScaledRandom
