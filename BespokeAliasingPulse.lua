-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local Pitch = require "Unit.ViewControl.Pitch"
local GainBias = require "Unit.ViewControl.GainBias"
local Fader = require "Unit.ViewControl.Fader"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local AliasingPulse = Class{}
AliasingPulse:include(Unit)

function AliasingPulse:init(args)
  args.title = "Aliasing Pulse"
  args.mnemonic = "AP"
  Unit.init(self,args)
end

function AliasingPulse:onLoadGraph(channelCount)
  if channelCount==2 then
    self:loadStereoGraph()
  else
    self:loadMonoGraph()
  end
end

function AliasingPulse:loadMonoGraph()
  -- create objects
  local osc = self:addObject("osc",libcore.SineOscillator())
  local tune = self:addObject("tune",app.ConstantOffset())
  local tuneRange = self:addObject("tuneRange",app.MinMax())
  local f0 = self:addObject("f0",app.GainBias())
  local f0Range = self:addObject("f0Range",app.MinMax())
  local vca = self:addObject("vca",app.Multiply())
  local level = self:addObject("level",app.GainBias())
  local levelRange = self:addObject("levelRange",app.MinMax())
  local bump = self:addObject("bump",libcore.BumpMap())
  local width = self:addObject("width",app.ParameterAdapter())
  local oscVca = self:addObject("oscVca",app.Multiply())
  local oscVcaMult = self:addObject("oscVcaMult",app.Constant())
  local compVca = self:addObject("compVca",app.Multiply())
  local compVcaMult = self:addObject("compVcaMult",app.Constant())
  local offset = self:addObject("offset",app.ConstantOffset())
  local sync = self:addObject("sync",app.Comparator())
  sync:setTriggerMode()

  tie(bump,"Width",width,"Out")

  bump:hardSet("Height",1.0)
  bump:hardSet("Fade",0.0)
  oscVcaMult:hardSet("Value",0.5)
  offset:hardSet("Offset",-0.5)
  compVcaMult:hardSet("Value",2.0)

  connect(tune,"Out",tuneRange,"In")
  connect(tune,"Out",osc,"V/Oct")

  connect(f0,"Out",osc,"Fundamental")
  connect(f0,"Out",f0Range,"In")

  connect(level,"Out",levelRange,"In")
  connect(level,"Out",vca,"Left")

  connect(osc,"Out",oscVca,"Left")
  connect(sync,"Out",osc,"Sync")
  connect(oscVcaMult,"Out",oscVca,"Right")
  connect(oscVca,"Out",bump,"In")
  connect(bump,"Out",offset,"In")
  connect(offset,"Out",compVca,"Left")
  connect(compVcaMult,"Out",compVca,"Right")
  connect(compVca,"Out",vca,"Right")
  connect(vca,"Out",self,"Out1")

  self:addMonoBranch("level",level,"In",level,"Out")
  self:addMonoBranch("tune",tune,"In",tune,"Out")
  self:addMonoBranch("f0",f0,"In",f0,"Out")
  self:addMonoBranch("width",width,"In",width,"Out")
  self:addMonoBranch("sync",sync,"In",sync,"Out")

end

function AliasingPulse:loadStereoGraph()
  self:loadMonoGraph()
  connect(self.objects.vca,"Out",self,"Out2")
end

local views = {
  expanded = {"tune","freq","width","sync","level"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local widthMap = linMap(0,1,0.1,0.01,0.001,0.001)

function AliasingPulse:onLoadViews(objects,branches)
  local controls = {}

  controls.tune = Pitch {
    button = "V/oct",
    branch = branches.tune,
    description = "V/oct",
    offset = objects.tune,
    range = objects.tuneRange
  }

  controls.freq = GainBias {
    button = "f0",
    description = "Fundamental",
    branch = branches.f0,
    gainbias = objects.f0,
    range = objects.f0Range,
    biasMap = Encoder.getMap("oscFreq"),
    biasUnits = app.unitHertz,
    initialBias = 27.5,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.level = GainBias {
    button = "level",
    description = "Level",
    branch = branches.level,
    gainbias = objects.level,
    range = objects.levelRange,
    initialBias = 0.5,
  }


  controls.width = GainBias {
    button = "width",
    description = "Pulse Width",
    branch = branches.width,
    gainbias = objects.width,
    range = objects.width,
    biasMap = widthMap,
    initialBias = 0.5,
  }

  controls.sync = Gate {
    button = "sync",
    description = "Sync",
    branch = branches.sync,
    comparator = objects.sync,
  }

  return controls, views
end

return AliasingPulse
