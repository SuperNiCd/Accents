-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.MenuControl.OptionControl"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local CarouselClockDivider = Class{}
CarouselClockDivider:include(Unit)

function CarouselClockDivider:init(args)
  args.title = "Carousel Clock Divider"
  args.mnemonic = "CD"
  Unit.init(self,args)
end

function CarouselClockDivider:onLoadGraph( channelCount)
  local trig = self:addObject("trig",app.Comparator())
  trig:setTriggerMode()
  local rotate = self:addObject("rotate",app.Comparator())
  rotate:setTriggerMode()
  local reset = self:addObject("reset",app.Comparator())
  rotate:setTriggerMode()

  local masterCounter = self:addObject("masterCounter",libcore.Counter())
  local counter1 = self:addObject("counter1",libcore.Counter())
  local counter2 = self:addObject("counter2",libcore.Counter())
  local counter3 = self:addObject("counter3",libcore.Counter())
  local counter4 = self:addObject("counter4",libcore.Counter())
  masterCounter:hardSet("Start",1)
  counter1:hardSet("Start",1)
  counter2:hardSet("Start",1)
  counter3:hardSet("Start",1)
  counter4:hardSet("Start",1)
  masterCounter:hardSet("Step Size",1)
  counter1:hardSet("Step Size",1)
  counter2:hardSet("Step Size",1)
  counter3:hardSet("Step Size",1)
  counter4:hardSet("Step Size",1)
  masterCounter:hardSet("Gain",0.1)
  counter1:hardSet("Gain",0.01)
  counter2:hardSet("Gain",0.01)
  counter3:hardSet("Gain",0.01)
  counter4:hardSet("Gain",0.01)
  masterCounter:setOptionValue("Wrap",1)
  counter1:setOptionValue("Wrap",1)
  counter2:setOptionValue("Wrap",1)
  counter3:setOptionValue("Wrap",1)
  counter4:setOptionValue("Wrap",1)

  local masterFinish = self:addObject("masterFinish",app.ParameterAdapter())
  local finish1 = self:addObject("finish1",app.ParameterAdapter())
  local finish2 = self:addObject("finish2",app.ParameterAdapter())
  local finish3 = self:addObject("finish3",app.ParameterAdapter())
  local finish4 = self:addObject("finish4",app.ParameterAdapter())

  local vca1 = self:addObject("vca1",app.Multiply())
  local vca2 = self:addObject("vca2",app.Multiply())
  local vca3 = self:addObject("vca3",app.Multiply())
  local vca4 = self:addObject("vca4",app.Multiply())

  local comp1 = self:addObject("comp1",app.Comparator())
  local comp2 = self:addObject("comp2",app.Comparator())
  local comp3 = self:addObject("comp3",app.Comparator())
  local comp4 = self:addObject("comp4",app.Comparator())
  local compThreshold1 = self:addObject("compThreshold1",app.ParameterAdapter())
  local compThreshold2 = self:addObject("compThreshold2",app.ParameterAdapter())
  local compThreshold3 = self:addObject("compThreshold3",app.ParameterAdapter())
  local compThreshold4 = self:addObject("compThreshold4",app.ParameterAdapter())
  local compGain1 = self:addObject("compGain1",app.ConstantOffset())
  local compGain2 = self:addObject("compGain2",app.ConstantOffset())
  local compGain3 = self:addObject("compGain3",app.ConstantOffset())
  local compGain4 = self:addObject("compGain4",app.ConstantOffset())
  comp1:setGateMode()
  comp2:setGateMode()
  comp3:setGateMode()
  comp4:setGateMode()
  comp1:hardSet("Hysteresis",0.0)
  comp2:hardSet("Hysteresis",0.0)
  comp3:hardSet("Hysteresis",0.0)
  comp4:hardSet("Hysteresis",0.0)
  compThreshold1:hardSet("Gain",0.01)
  compThreshold2:hardSet("Gain",0.01)
  compThreshold3:hardSet("Gain",0.01)
  compThreshold4:hardSet("Gain",0.01)
  compGain1:hardSet("Gain",0.01)
  compGain2:hardSet("Gain",0.01)
  compGain3:hardSet("Gain",0.01)
  compGain4:hardSet("Gain",0.01)

  tie(counter1,"Finish",finish1,"Out")
  tie(counter2,"Finish",finish2,"Out")
  tie(counter3,"Finish",finish3,"Out")
  tie(counter4,"Finish",finish4,"Out")
  tie(masterCounter,"Finish",masterFinish,"Out")

  tie(comp1,"Threshold",compThreshold1,"Out")
  tie(comp2,"Threshold",compThreshold2,"Out")
  tie(comp3,"Threshold",compThreshold3,"Out")
  tie(comp4,"Threshold",compThreshold4,"Out")

  tie(compGain1,"Offset",finish1,"Out")
  tie(compGain2,"Offset",finish2,"Out")
  tie(compGain3,"Offset",finish3,"Out")
  tie(compGain4,"Offset",finish4,"Out")

  local bump1 = self:addObject("bump1",libcore.BumpMap())
  local bump2 = self:addObject("bump2",libcore.BumpMap())
  local bump3 = self:addObject("bump3",libcore.BumpMap())
  local bump4 = self:addObject("bump4",libcore.BumpMap())
  bump1:hardSet("Center",0.1)
  bump2:hardSet("Center",0.2)
  bump3:hardSet("Center",0.3)
  bump4:hardSet("Center",0.4)
  bump1:hardSet("Width",0.05)
  bump2:hardSet("Width",0.05)
  bump3:hardSet("Width",0.05)
  bump4:hardSet("Width",0.05)
  bump1:hardSet("Height",1.0)
  bump2:hardSet("Height",1.0)
  bump3:hardSet("Height",1.0)
  bump4:hardSet("Height",1.0)
  bump1:hardSet("Fade",0.0)
  bump2:hardSet("Fade",0.0)
  bump3:hardSet("Fade",0.0)
  bump4:hardSet("Fade",0.0)

  local outMix1 = self:addObject("outMix1",app.Sum())
  local outMix2 = self:addObject("outMix2",app.Sum())
  local outMix3 = self:addObject("outMix3",app.Sum())

  connect(compGain1,"Out",compThreshold1,"In")
  connect(compGain2,"Out",compThreshold2,"In")
  connect(compGain3,"Out",compThreshold3,"In")
  connect(compGain4,"Out",compThreshold4,"In")


  connect(self,"In1",trig,"In")
  connect(trig,"Out",counter1,"In")
  connect(trig,"Out",counter2,"In")
  connect(trig,"Out",counter3,"In")
  connect(trig,"Out",counter4,"In")

  connect(rotate,"Out",masterCounter,"In")

  connect(masterCounter,"Out",bump1,"In")
  connect(masterCounter,"Out",bump2,"In")
  connect(masterCounter,"Out",bump3,"In")
  connect(masterCounter,"Out",bump4,"In")

  connect(counter1,"Out",comp1,"In")
  connect(counter2,"Out",comp2,"In")
  connect(counter3,"Out",comp3,"In")
  connect(counter4,"Out",comp4,"In")

  connect(comp1,"Out",vca1,"Left")
  connect(comp2,"Out",vca2,"Left")
  connect(comp3,"Out",vca3,"Left")
  connect(comp4,"Out",vca4,"Left")

  connect(bump1,"Out",vca1,"Right")
  connect(bump2,"Out",vca2,"Right")
  connect(bump3,"Out",vca3,"Right")
  connect(bump4,"Out",vca4,"Right")

  connect(vca1,"Out",outMix1,"Left")
  connect(vca2,"Out",outMix1,"Right")
  connect(outMix1,"Out",outMix2,"Left")
  connect(vca3,"Out",outMix2,"Right")
  connect(outMix2,"Out",outMix3,"Left")
  connect(vca4,"Out",outMix3,"Right")

  connect(reset,"Out",counter1,"Reset")
  connect(reset,"Out",counter2,"Reset")
  connect(reset,"Out",counter3,"Reset")
  connect(reset,"Out",counter4,"Reset")

  connect(outMix3,"Out",self,"Out1")

  self:addMonoBranch("rotate",rotate,"In",rotate,"Out")
  self:addMonoBranch("masterFinish",masterFinish,"In",masterFinish,"Out")
  self:addMonoBranch("finish1",finish1,"In",finish1,"Out")
  self:addMonoBranch("finish2",finish2,"In",finish2,"Out")
  self:addMonoBranch("finish3",finish3,"In",finish3,"Out")
  self:addMonoBranch("finish4",finish4,"In",finish4,"Out")
  self:addMonoBranch("reset",reset,"In",reset,"Out")

  if channelCount > 1 then
    connect(counter1,"Out",self,"Out2")
  end

  rotate:simulateRisingEdge()
  rotate:simulateFallingEdge()
  reset:simulateRisingEdge()
  reset:simulateFallingEdge()
end

local menu = {
  "infoHeader","rename","load","save","edit"
}

local function intMap(min,max)
  local map = app.LinearDialMap(min,max)
  map:setSteps(5,1,0.25,0.25);
  map:setRounding(1)
  return map
end

local divMap = intMap(2,96)
local sizeMap = intMap(1,4)

local views = {
  expanded = {"input","rotate","d1","d2","d3","d4","size","reset"},
  collapsed = {},
}

function CarouselClockDivider:onLoadViews(objects,branches)
  local controls = {}

--   controls.scope = OutputScope {
--     monitor = self,
--     width = 4*ply,
--   }

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    unit = self,
    comparator = objects.trig,
  }

  controls.rotate = Gate {
    button = "rotate",
    description = "Rotate Carousel",
    branch = branches.rotate,
    comparator = objects.rotate,
    param = objects.masterCounter:getParameter("Value"),
    readoutPrecision = 0
  }

   controls.d1 = GainBias {
    button = "d1",
    description = "Divider 1",
    branch = branches.finish1,
    gainbias = objects.finish1,
    range = objects.finish1,
    biasMap = divMap,
    biasPrecision = 0,
    initialBias = 24
  }

  controls.d2 = GainBias {
    button = "d2",
    description = "Divider 2",
    branch = branches.finish2,
    gainbias = objects.finish2,
    range = objects.finish2,
    biasMap = divMap,
    biasPrecision = 0,
    initialBias = 24
  }

  controls.d3 = GainBias {
    button = "d3",
    description = "Divider 3",
    branch = branches.finish3,
    gainbias = objects.finish3,
    range = objects.finish3,
    biasMap = divMap,
    biasPrecision = 0,
    initialBias = 24
  }

  controls.d4 = GainBias {
    button = "d4",
    description = "Divider 4",
    branch = branches.finish4,
    gainbias = objects.finish4,
    range = objects.finish4,
    biasMap = divMap,
    biasPrecision = 0,
    initialBias = 24
  }

  controls.size = GainBias {
    button = "size",
    description = "Carousel Size",
    branch = branches.masterFinish,
    gainbias = objects.masterFinish,
    range = objects.masterFinish,
    biasMap = sizeMap,
    biasPrecision = 0,
    initialBias = 4
  }

  controls.reset = Gate {
    button = "reset",
    description = "Reset All Dividers",
    branch = branches.reset,
    comparator = objects.reset,
    param = objects.counter1:getParameter("Value"),
    readoutPrecision = 0
  }

  return controls, views
end

return CarouselClockDivider
