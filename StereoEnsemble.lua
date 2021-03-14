local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local ModeSelect = require "Unit.MenuControl.OptionControl"
local Encoder = require "Encoder"
local Utils = require "Utils"
local ply = app.SECTION_PLY

local StereoEnsemble = Class{}
StereoEnsemble:include(Unit)

function StereoEnsemble:init(args)
  args.title = "Ensemble"
  args.mnemonic = "SE"
  Unit.init(self,args)
end

function StereoEnsemble:onLoadGraph(channelCount)
  local s2m = channelCount > 1 and self:addObject("s2m",app.StereoToMono()) or nil
  local lfo1 = self:addObject("lfo1",libcore.SineOscillator())
  local lfo2 = self:addObject("lfo2",libcore.SineOscillator())
  local lfo1f0 = self:addObject("lfo1f0",app.ConstantOffset())
  local lfo2f0 = self:addObject("lfo2f0",app.ConstantOffset())
  local lfo1f0Control = self:addObject("lfo1f0Control",app.ParameterAdapter())
  local phase1 = self:addObject("phase1",libcore.MicroDelay(1))
  local phase2 = self:addObject("phase2",libcore.MicroDelay(1))
  local delay1 = self:addObject("delay1",libcore.Delay(1))
  local delay2 = self:addObject("delay2",libcore.Delay(1))
  local delay3 = self:addObject("delay3",libcore.Delay(1))
  local delay1time = self:addObject("delay1time",app.ConstantOffset())
  local delay2time = self:addObject("delay2time",app.ConstantOffset())
  local delay3time = self:addObject("delay3time",app.ConstantOffset())
  local delay1adapter = self:addObject("delay1adapter",app.ParameterAdapter())
  local delay2adapter = self:addObject("delay2adapter",app.ParameterAdapter())
  local delay3adapter = self:addObject("delay3adapter",app.ParameterAdapter())
  local depthVCA = self:addObject("depthVCA",app.Multiply())
  local depthVCAGain = self:addObject("depthVCAGain",app.Constant())
  local mix1 = self:addObject("mix1",app.Sum())
  local mix2 = self:addObject("mix2",app.Sum())
  local mix3 = self:addObject("mix3",app.Sum())
  local dryMix = self:addObject("dryMix",app.Sum())
  local amtVCA = self:addObject("amtVCA",app.Multiply())
  local amtVCALevel = self:addObject("amtVCALevel",app.ConstantOffset())
  local amtVCALevelControl = self:addObject("amtVCALevelControl",app.ParameterAdapter())
  local modVCA = self:addObject("modVCA",app.Multiply())
  local modVCALevel = self:addObject("modVCALevel",app.ConstantOffset())

  lfo2f0:hardSet("Offset",1.0)
  phase1:hardSet("Delay",0.056)
  phase2:hardSet("Delay",0.112)
  delay1time:hardSet("Offset",0.020)
  delay2time:hardSet("Offset",0.030)
  delay3time:hardSet("Offset",0.040)
  delay1adapter:hardSet("Gain",1.0)
  delay2adapter:hardSet("Gain",1.0)
  delay3adapter:hardSet("Gain",1.0)
  depthVCAGain:hardSet("Value",0.001)
  delay1:allocateTimeUpTo(1.0)
  delay2:allocateTimeUpTo(1.0)
  delay3:allocateTimeUpTo(1.0)
  modVCALevel:hardSet("Offset",1.0)

  tie(lfo1f0,"Offset",lfo1f0Control,"Out")
  tie(amtVCALevel,"Offset",amtVCALevelControl,"Out")
  tie(delay1,"Left Delay",delay1adapter,"Out")
  tie(delay2,"Left Delay",delay2adapter,"Out")
  tie(delay3,"Left Delay",delay3adapter,"Out")

  self:addMonoBranch("amt",amtVCALevelControl,"In",amtVCALevelControl,"Out")
  self:addMonoBranch("rate",lfo1f0Control,"In",lfo1f0Control,"Out")

  connect(lfo1f0,"Out",lfo1,"Fundamental")
  connect(lfo2f0,"Out",lfo2,"Fundamental")
  connect(lfo2,"Out",modVCA,"Left")
  connect(modVCALevel,"Out",modVCA,"Right")
  connect(modVCA,"Out",lfo1f0,"In")

  connect(lfo1,"Out",amtVCA,"Left")
  connect(amtVCALevel,"Out",depthVCA,"Left")
  connect(depthVCAGain,"Out",depthVCA,"Right")
  connect(depthVCA,"Out",amtVCA,"Right")
  connect(amtVCA,"Out",delay1time,"In")
  connect(amtVCA,"Out",phase1,"In")
  connect(phase1,"Out",delay2time,"In")
  connect(amtVCA,"Out",phase2,"In")
  connect(phase2,"Out",delay3time,"In")
  connect(delay1time,"Out",delay1adapter,"In")
  connect(delay2time,"Out",delay2adapter,"In")
  connect(delay3time,"Out",delay3adapter,"In")

  if channelCount > 1 then
    connect(self,"In1",s2m,"Left In")
    connect(self,"In2",s2m,"Right In")
    connect(s2m,"Out",delay1,"Left In")
    connect(s2m,"Out",delay2,"Left In")
    connect(s2m,"Out",delay3,"Left In")

    connect(delay1,"Left Out",mix1,"Left")
    connect(delay2,"Left Out",mix1,"Right")
    connect(delay2,"Left Out",mix2,"Left")
    connect(delay3,"Left Out",mix2,"Right")
    connect(mix1,"Out",self,"Out1")
    connect(mix2,"Out",self,"Out2")
  else
    connect(self,"In1",delay1,"Left In")
    connect(self,"In1",delay2,"Left In")
    connect(delay1,"Left Out",mix1,"Left")
    connect(delay2,"Left Out",mix1,"Right")
    connect(mix1,"Out",mix2,"Left")
    connect(delay3,"Left Out",mix2,"Right")
    connect(mix2,"Out",dryMix,"Left")
    connect(self,"In1",dryMix,"Right")
    connect(dryMix,"Out",self,"Out1")
  end
end

local menu = {
  "optionsHeader",
  "routing",

  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function StereoEnsemble:onShowMenu(objects,branches)
  local controls = {}

  if objects.s2m then
    controls.optionsHeader = MenuHeader {
      description = "Input Routing Options"
    }

    controls.routing = ModeSelect {
      description = "Stereo-to-Mono Routing",
      option = objects.s2m:getOption("Routing"),
      choices = {"left","sum","right"},
      descriptionWidth = 2,
      muteOnChange = true
    }
  end

  return controls, menu
end

local views = {
  expanded = {"amt","rate"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local amtMap = linMap(-1,1,0.1,0.01,0.001,0.001)
local rateMap = linMap(0,6,1,0.1,0.01,0.001)

function StereoEnsemble:onLoadViews(objects,branches)
  local controls = {}

  controls.amt = GainBias {
    button = "depth",
    description = "Depth",
    branch = branches.amt,
    gainbias = objects.amtVCALevelControl,
    range = objects.amtVCALevelControl,
    biasMap = amtMap,
    biasUnits = app.unitNone,
    initialBias = 0.25
  }

  controls.rate = GainBias {
    button = "rate",
    description = "Rate",
    branch = branches.rate,
    gainbias = objects.lfo1f0Control,
    range = objects.lfo1f0Control,
    biasMap = rateMap,
    biasUnits = app.unitHertz,
    initialBias = 3.0
  }

  return controls, views
end

return StereoEnsemble
