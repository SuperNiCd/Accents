local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local Pitch = require "Unit.ViewControl.Pitch"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local Fader = require "Unit.ViewControl.Fader"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Ringmod = Class{}
Ringmod:include(Unit)

function Ringmod:init(args)
  args.title = "Ring Mod"
  args.mnemonic = "RM"
  args.version = 1
  Unit.init(self,args)
end

function Ringmod:onLoadGraph(channelCount)
  -- input, vca, sine osc

  -- create sine osc
  local modulator = self:addObject("modulator",libcore.SineOscillator())

  -- create multipliers
  local mult1 = self:addObject("mult1",app.Multiply())
  local mult2 = self:addObject("mult2",app.Multiply())

  -- create f0 gainbias & minmax
  local f0 = self:addObject("f0",app.GainBias())
  local f0Range = self:addObject("f0Range",app.MinMax())

  -- connect unit input to vca/multipler
  connect(self,"In1",mult1,"Left")
  if channelCount > 1 then
    connect(self,"In2",mult2,"Left")
  end

  -- connect vca/multiplier to unit output
  connect(mult1,"Out",self,"Out1")
  if channelCount > 1 then
    connect(mult2,"Out",self,"Out2")
  end

  -- connect sine osc to right Inlet of vca/multiplier
  connect(modulator,"Out",mult1,"Right")
  if channelCount > 1 then
    connect(modulator,"Out",mult2,"Right")
  end

  connect(f0,"Out",modulator,"Fundamental")
  connect(f0,"Out",f0Range,"In")

  self:addMonoBranch("f0",f0,"In",f0,"Out")
end

local views = {
  expanded = {"freq"},
  collapsed = {},
}

function Ringmod:onLoadViews(objects,branches)
  local controls = {}
  
  controls.freq = GainBias {
    button = "f0",
    description = "Fundamental",
    branch = branches.f0,
    gainbias = objects.f0,
    range = objects.f0Range,
    biasMap = Encoder.getMap("oscFreq"),
    biasUnits = app.unitHertz,
    initialBias = 200.0,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }
  return controls, views
end

return Ringmod
