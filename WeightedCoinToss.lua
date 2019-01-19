-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Gate = require "Unit.ViewControl.Gate"
local GainBias = require "Unit.ViewControl.GainBias"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local WeightedCoinToss = Class{}
WeightedCoinToss:include(Unit)

function WeightedCoinToss:init(args)
  args.title = "Weighted Coin Toss"
  args.mnemonic = "TC"
  Unit.init(self,args)
end

function WeightedCoinToss:onLoadGraph(channelCount)
  --random block
  local random=self:createObject("WhiteNoise","random")
  local hold = self:createObject("TrackAndHold","hold")
  local comparator = self:createObject("Comparator","comparator")
  local rectify = self:createObject("Rectify","rectify")

  -- probability control block
  local prob = self:createObject("ConstantOffset","prob")
  local probOffset = self:createObject("ParameterAdapter","probOffset")
  local one = self:createObject("Constant","one")
  local negOne = self:createObject("Constant","negOne")
  local sum1 = self:createObject("Sum","sum")
  local invert = self:createObject("Multiply","invert")
  local thresh = self:createObject("ParameterAdapter","thresh")

  -- comparison block
  local compare = self:createObject("Comparator","compare")
  local thresh = self:createObject("ParameterAdapter","thresh")
  local reset = self:createObject("Comparator","reset")
  local sum = self:createObject("Sum","sum")
  local flip = self:createObject("Multiply","flip")

  -- output control
  local outputNegOne = self:createObject("Constant","outputNegOne")
  local outputOffset = self:createObject("ConstantOffset","outputOffset")
  local outputVCA = self:createObject("Multiply","outputVCA")

  comparator:setTriggerMode()
  compare:setGateMode()
  reset:setTriggerMode()
  rectify:optionSet("Type",3) --full rectification
  one:hardSet("Value",1.0)
  negOne:hardSet("Value",-1.0)
  thresh:hardSet("Gain",1.0)
  outputNegOne:hardSet("Value",1.0)
  outputOffset:hardSet("Offset",0.0)

  -- register exported ports
  self:createMonoBranch("trig",comparator,"In",comparator,"Out")
  self:createMonoBranch("prob",probOffset,"In",probOffset,"Out")

  -- connect objects
  connect(comparator,"Out",hold,"Track")
  connect(random,"Out",rectify,"In")
  connect(rectify,"Out",hold,"In")
  connect(hold,"Out",sum,"Left")

  connect(comparator,"Out",reset,"In")
  connect(reset,"Out",flip,"Left")
  connect(negOne,"Out",flip,"Right")
  connect(flip,"Out",sum,"Right")

  connect(prob,"Out",invert,"Left")
  connect(negOne,"Out",invert,"Right")
  connect(invert,"Out",sum1,"Left")
  connect(one,"Out",sum1,"Right")
  connect(sum1,"Out",thresh,"In")

  connect(sum,"Out",compare,"In")
  connect(compare,"Out",outputOffset,"In")
  connect(outputOffset,"Out",outputVCA,"Left")
  connect(outputNegOne,"Out",outputVCA,"Right")
  connect(outputVCA,"Out", self,"Out1")

  if channelCount>1 then
    connect(outputVCA,"Out",self,"Out2")
  end

  tie(prob,"Offset",probOffset,"Out")
  tie(compare,"Threshold",thresh,"Out")

end

local views = {
  expanded = {"trigger","prob"},
  collapsed = {},
}

function WeightedCoinToss:onLoadViews(objects,branches)
  local controls = {}

  controls.trigger = Gate {
    button = "trig",
    branch = branches.trig,
    description = "Trigger",
    comparator = objects.comparator,
  }

  controls.prob = GainBias {
    button = "weight",
    description = "Stack the Odds",
    branch = branches.prob,
    gainbias = objects.probOffset,
    range = objects.probOffset,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.5
  }

  return controls, views
end

local menu = {
  "setHeader",
  "setZero",
  "setNegOne",
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function WeightedCoinToss:setLowValueMode(mode)
  local objects = self.objects
  self.mode = mode

  if mode=="0" then
    objects.outputOffset:hardSet("Offset",0.0)
    objects.outputNegOne:hardSet("Value",1.0)
  elseif mode=="-1" then
    objects.outputOffset:hardSet("Offset",-0.5)
    objects.outputNegOne:hardSet("Value",2.0)
  end
end

function WeightedCoinToss:onLoadFinished()
  self:setLowValueMode("0")
end

function WeightedCoinToss:serialize()
  local t = Unit.serialize(self)
  t.lowValueMode = self.mode
  return t
end

function WeightedCoinToss:deserialize(t)
  Unit.deserialize(self,t)
  if t.lowValueMode then
    self:setLowValueMode(t.lowValueMode)
  end
end

function WeightedCoinToss:onLoadMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Low value is: %s.",self.mode)
  }

  controls.setZero = Task {
    description = "0",
    task = function()
      self:setLowValueMode("0")
    end
  }

  controls.setNegOne = Task {
    description = "-1",
    task = function()
      self:setLowValueMode("-1")
    end
  }

  return controls, menu
end

return WeightedCoinToss
