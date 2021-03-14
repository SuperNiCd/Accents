local app = app
local libcore = require "core.libcore"
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
  local random=self:addObject("random",libcore.WhiteNoise())
  local hold = self:addObject("hold",libcore.TrackAndHold())
  local comparator = self:addObject("comparator",app.Comparator())
  local rectify = self:addObject("rectify",libcore.Rectify())

  -- probability control block
  local prob = self:addObject("prob",app.ConstantOffset())
  local probOffset = self:addObject("probOffset",app.ParameterAdapter())
  local one = self:addObject("one",app.Constant())
  local negOne = self:addObject("negOne",app.Constant())
  local sum1 = self:addObject("sum",app.Sum())
  local invert = self:addObject("invert",app.Multiply())
  local thresh = self:addObject("thresh",app.ParameterAdapter())

  -- comparison block
  local compare = self:addObject("compare",app.Comparator())
  local thresh = self:addObject("thresh",app.ParameterAdapter())
  local reset = self:addObject("reset",app.Comparator())
  local sum = self:addObject("sum",app.Sum())
  local flip = self:addObject("flip",app.Multiply())

  -- output control
  local outputNegOne = self:addObject("outputNegOne",app.Constant())
  local outputOffset = self:addObject("outputOffset",app.ConstantOffset())
  local outputVCA = self:addObject("outputVCA",app.Multiply())

  comparator:setTriggerMode()
  compare:setGateMode()
  reset:setTriggerMode()
  rectify:setOptionValue("Type",3) --full rectification
  one:hardSet("Value",1.0)
  negOne:hardSet("Value",-1.0)
  thresh:hardSet("Gain",1.0)
  outputNegOne:hardSet("Value",1.0)
  outputOffset:hardSet("Offset",0.0)

  -- register exported ports
  self:addMonoBranch("trig",comparator,"In",comparator,"Out")
  self:addMonoBranch("prob",probOffset,"In",probOffset,"Out")

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

function WeightedCoinToss:onShowMenu(objects,branches)
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
