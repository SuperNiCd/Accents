-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Pitch = require "Unit.ViewControl.Pitch"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local BespokeBPF = Class{}
BespokeBPF:include(Unit)

function BespokeBPF:init(args)
  args.title = "Ladder BPF"
  args.mnemonic = "LB"
  Unit.init(self,args)
end

function BespokeBPF:onLoadGraph(channelCount)
  local lpfilter = self:addObject("filter",libcore.StereoLadderFilter())
  local hpfilter = self:addObject("filter",libcore.StereoLadderHPF())
  if channelCount==2 then
    connect(self,"In1",lpfilter,"Left In")
    connect(lpfilter,"Left Out",hpfilter,"Left In")
    connect(hpfilter,"Left Out",self,"Out1")
    connect(self,"In2",lpfilter,"Right In")
    connect(lpfilter,"Right Out",hpfilter,"Right In")
    connect(hpfilter,"Right Out",self,"Out2")
  else
    connect(self,"In1",lpfilter,"Left In")
    connect(lpfilter,"Left Out",hpfilter,"Left In")
    connect(hpfilter,"Left Out",self,"Out1")
  end

  local tune = self:addObject("tune",app.ConstantOffset())
  local tuneRange = self:addObject("tuneRange",app.MinMax())

  local f0 = self:addObject("f0",app.GainBias())
  local f0Range = self:addObject("f0Range",app.MinMax())

  local res = self:addObject("res",app.GainBias())
  local resRange = self:addObject("resRange",app.MinMax())

  local clipper = self:addObject("clipper",libcore.Clipper())
  clipper:setMaximum(0.999)
  clipper:setMinimum(0)

  local bw = self:addObject("bw",app.GainBias())
  local bwRange = self:addObject("bwRange",app.MinMax())

  local negate = self:addObject("negate",app.ConstantGain())
  negate:hardSet("Gain",-1)

  local addBw = self:addObject("addBw",app.Sum())
  local subBw = self:addObject("subBw",app.Sum())

  connect(tune,"Out",lpfilter,"V/Oct")
  connect(tune,"Out",hpfilter,"V/Oct")
  connect(tune,"Out",tuneRange,"In")


  connect(f0,"Out",addBw,"Left")
  connect(bw,"Out",addBw,"Right")
  connect(addBw,"Out",lpfilter,"Fundamental")
  --connect(addBw,"Out",hpfilter,"Fundamental")

  connect(f0,"Out",subBw,"Left")
  connect(bw,"Out",negate,"In")
  connect(negate,"Out",subBw,"Right")
  --connect(subBw,"Out",lpfilter,"Fundamental")
  connect(subBw,"Out",hpfilter,"Fundamental")

  connect(f0,"Out",f0Range,"In")
  connect(bw,"Out",bwRange,"In")

  connect(res, "Out",clipper,"In")
  connect(clipper,"Out",lpfilter,"Resonance")
  connect(clipper,"Out",hpfilter,"Resonance")
  connect(clipper,"Out",resRange,"In")

  self:addMonoBranch("tune",tune,"In",tune,"Out")
  self:addMonoBranch("Q",res,"In",res,"Out")
  self:addMonoBranch("f0",f0,"In",f0,"Out")
  self:addMonoBranch("bw",bw,"In",bw,"Out")
end

local views = {
  expanded = {"tune","freq","resonance","bandwidth"},
  collapsed = {},
}

function BespokeBPF:onLoadViews(objects,branches)
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
    branch = branches.f0,
    description = "Fundamental",
    gainbias = objects.f0,
    range = objects.f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 440,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.resonance = GainBias {
    button = "Q",
    branch = branches.Q,
    description = "Resonance",
    gainbias = objects.res,
    range = objects.resRange,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.25,
    gainMap = Encoder.getMap("[-10,10]")
  }

  controls.bandwidth = GainBias {
    button = "bw",
    branch = branches.bw,
    description = "Bandwidth",
    gainbias = objects.bw,
    range = objects.bwRange,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 1,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  return controls, views
end

return BespokeBPF
