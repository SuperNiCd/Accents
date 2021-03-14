local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local GainBias = require "Unit.ViewControl.GainBias"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Maths = Class{}
Maths:include(Unit)

function Maths:init(args)
  args.title = "Maths"
  args.mnemonic = "Ma"
  Unit.init(self,args)
end

function Maths:onLoadGraph()
  local a = self:addObject("a",app.ConstantGain())
  local b = self:addObject("b",app.ConstantGain())
  local sum = self:addObject("sum",app.Sum())
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:addMonoBranch("inA", a, "In", a,"Out")
  self:addMonoBranch("inB", b, "In", b,"Out")

  local negOne = self:addObject("negOne",app.Constant())
  negOne:hardSet("Value",-1.0)
  local one = self:addObject("one",app.Constant())
  one:hardSet("Value",1.0)

  local invert1 = self:addObject("invert1",app.Multiply())
  local invert2 = self:addObject("invert2",app.Multiply())
  local invert2C = self:addObject("invert2C",app.Constant())
  invert2C:hardSet("Value",-1.0)
  local invert3 = self:addObject("invert3",app.Multiply())
  local invert3C = self:addObject("invert3C",app.Constant())
  invert3C:hardSet("Value",1.0)

  local compare = self:addObject("compare",app.Comparator())
  compare:setGateMode()
  compare:hardSet("Hysteresis",0.0)
  compare:hardSet("Threshold",0.0)

  local vcaA = self:addObject("vcaA",app.Multiply())
  local vcaB = self:addObject("vcaB",app.Multiply())
  local selectSum1 = self:addObject("selectSum1",app.Sum())
  local selectSum1V = self:addObject("selectSum1V",app.Constant())
  local selectSum2 = self:addObject("selectSum2",app.Sum())
  local selectSum2V = self:addObject("selectSum2V",app.Constant())
  selectSum1V:hardSet("Value",0.0)
  selectSum2V:hardSet("Value",1.0)

  local minmaxMix = self:addObject("minmaxMix",app.Sum())

  local meanSum = self:addObject("meanSum",app.Sum())
  local meanVCA = self:addObject("meanVCA",app.Multiply())
  local meanVCAC = self:addObject("meanVCAC",app.Constant())
  meanVCAC:hardSet("Value",0.5)

  local selectMinMax = self:addObject("selectMinMax",app.Multiply())
  local selectMean = self:addObject("selectMean",app.Multiply())
  local selectMinMaxC = self:addObject("selectMinMaxC",app.Constant())
  local selectMeanC = self:addObject("selectMeanC",app.Constant())
  selectMinMaxC:hardSet("Value",1.0)
  selectMeanC:hardSet("Value",0.0)
  local finalMix = self:addObject("finalMix",app.Sum())

  -- mix/max
  connect(a,"Out",sum,"Left")
  connect(b,"Out",invert1,"Left")
  connect(negOne,"Out",invert1,"Right")
  connect(invert1,"Out",sum,"Right")
  connect(sum,"Out",compare,"In")
  connect(compare,"Out",invert3,"Left")
  connect(invert3C,"Out",invert3,"Right")
  connect(invert3,"Out",selectSum1,"Left")
  connect(selectSum1V,"Out",selectSum1,"Right")
  connect(a,"Out",vcaA,"Left")
  connect(selectSum1,"Out",vcaA,"Right")
  connect(compare,"Out",invert2,"Left")
  connect(invert2C,"Out",invert2,"Right")
  connect(invert2,"Out",selectSum2,"Left")
  connect(selectSum2V,"Out",selectSum2,"Right")
  connect(b,"Out",vcaB,"Left")
  connect(selectSum2,"Out",vcaB,"Right")
  connect(vcaA,"Out", minmaxMix,"Left")
  connect(vcaB,"Out",minmaxMix,"Right")
  connect(minmaxMix,"Out",selectMinMax,"Left")
  connect(selectMinMaxC,"Out",selectMinMax,"Right")
  connect(selectMinMax,"Out",finalMix,"Left")

  -- mean
  connect(a,"Out",meanSum,"Left")
  connect(b,"Out",meanSum,"Right")
  connect(meanSum,"Out",meanVCA,"Left")
  connect(meanVCAC,"Out",meanVCA,"Right")
  connect(meanVCA,"Out",selectMean,"Left")
  connect(selectMeanC,"Out",selectMean,"Right")
  connect(selectMean,"Out",finalMix,"Right")

  connect(finalMix,"Out",self,"Out1")
end

local views = {
  expanded = {"a","b"},
  collapsed = {},
  input = {}
}

function Maths:onLoadViews(objects,branches)
  local controls = {}

  controls.a = BranchMeter {
    button = "a",
    branch = branches.inA,
    faderParam = objects.a:getParameter("Gain")
  }

  controls.b = BranchMeter {
    button = "b",
    branch = branches.inB,
    faderParam = objects.b:getParameter("Gain")
  }

  self:addToMuteGroup(controls.a)
  self:addToMuteGroup(controls.b)

  return controls, views
end

local menu = {
  "setHeader",
  "max",
  "min",
  "mean",

  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function Maths:setOp(op)
  local objects = self.objects
  self.op = op

  if op=="MAX" then
    objects.selectSum1V:hardSet("Value",0.0)
    objects.selectSum2V:hardSet("Value",1.0)
    objects.invert2C:hardSet("Value",-1.0)
    objects.invert3C:hardSet("Value",1.0)
    objects.selectMinMaxC:hardSet("Value",1.0)
    objects.selectMeanC:hardSet("Value",0.0)
  elseif op=="MIN" then
    objects.selectSum1V:hardSet("Value",1.0)
    objects.selectSum2V:hardSet("Value",0.0)
    objects.invert2C:hardSet("Value",1.0)
    objects.invert3C:hardSet("Value",-1.0)
    objects.selectMinMaxC:hardSet("Value",1.0)
    objects.selectMeanC:hardSet("Value",0.0)
  elseif op=="MEAN" then
    objects.selectMinMaxC:hardSet("Value",0.0)
    objects.selectMeanC:hardSet("Value",1.0)
  end
end

function Maths:onShowMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Current op is: %s.", self.op)
  }

  controls.max = Task {
    description = "MAX",
    task = function()
      self:setOp("MAX")
    end
  }

  controls.min = Task {
    description = "MIN",
    task = function()
      self:setOp("MIN")
    end
  }

  controls.mean = Task {
    description = "MEAN",
    task = function()
      self:setOp("MEAN")
    end
  }

  return controls, menu
end

function Maths:onLoadFinished()
  self:setOp("MAX")
end

function Maths:serialize()
  local t = Unit.serialize(self)
  t.mathOp = self.op
  return t
end

function Maths:deserialize(t)
  Unit.deserialize(self,t)
  if t.mathOp then
    self:setOp(t.mathOp)
  end
end

return Maths
