-- GLOBALS: app, os, verboseLevel, connect
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local LinearSamplingVCA = Class{}
LinearSamplingVCA:include(Unit)

function LinearSamplingVCA:init(args)
  args.title = "Linear Sampling VCA"
  args.mnemonic = "SX"
  Unit.init(self,args)
end

function LinearSamplingVCA:onLoadGraph(channelCount)
  if channelCount==2 then
    self:loadStereoGraph()
  else
    self:loadMonoGraph()
  end
end

function LinearSamplingVCA:loadMonoGraph()
  local vca = self:createObject("Multiply","vca")
  local level = self:createObject("GainBias","level")
  local levelRange = self:createObject("MinMax","levelRange")
  local compareRise = self:createObject("Comparator","compareRise")
  local compareFall = self:createObject("Comparator","compareFall")
  local sh = self:createObject("TrackAndHold","sh")
  local mixer = self:createObject("Sum","mixer")

  compareRise:setTriggerOnRiseMode()
  compareRise:hardSet("Threshold",0.0)
  compareRise:hardSet("Hysteresis",0.0)

  compareFall:setTriggerOnFallMode()
  compareFall:hardSet("Threshold",0.0)
  compareFall:hardSet("Hysteresis",0.0)

  connect(level,"Out",levelRange,"In")
--   connect(level,"Out",vca,"Left")
  connect(self,"In1",compareRise,"In")
  connect(self,"In1",compareFall,"In")
  connect(compareRise,"Out",mixer,"Left")
  connect(compareFall,"Out",mixer,"Right")
  connect(mixer,"Out",sh,"Track")
  connect(level,"Out",sh,"In")
  connect(sh,"Out",vca,"Left")
  connect(self,"In1",vca,"Right")
  connect(vca,"Out",self,"Out1")

  self:createMonoBranch("level",level,"In",level,"Out")
end

function LinearSamplingVCA:loadStereoGraph()
  local vca1 = self:createObject("Multiply","vca1")
  local vca2 = self:createObject("Multiply","vca2")
  local level = self:createObject("GainBias","level")
  local levelRange = self:createObject("MinMax","levelRange")

  local balance = self:createObject("StereoPanner","balance")
  local pan = self:createObject("GainBias","pan")
  local panRange = self:createObject("MinMax","panRange")

  local compareRise = self:createObject("Comparator","compareRise")
  local compareFall = self:createObject("Comparator","compareFall")
  local sh = self:createObject("TrackAndHold","sh")
  local mixer = self:createObject("Sum","mixer")

  compareRise:setTriggerOnRiseMode()
  compareRise:hardSet("Threshold",0.0)
  compareRise:hardSet("Hysteresis",0.0)

  compareFall:setTriggerOnFallMode()
  compareFall:hardSet("Threshold",0.0)
  compareFall:hardSet("Hysteresis",0.0)

  connect(level,"Out",levelRange,"In")

  connect(self,"In1",compareRise,"In")
  connect(self,"In1",compareFall,"In")
  connect(compareRise,"Out",mixer,"Left")
  connect(compareFall,"Out",mixer,"Right")
  connect(mixer,"Out",sh,"Track")
  connect(level,"Out",sh,"In")
  connect(sh,"Out",vca1,"Left")
  connect(sh,"Out",vca2,"Left")

  connect(self,"In1",vca1,"Right")
  connect(self,"In2",vca2,"Right")

  connect(vca1,"Out",balance,"Left In")
  connect(balance,"Left Out",self,"Out1")
  connect(vca2,"Out",balance,"Right In")
  connect(balance,"Right Out",self,"Out2")

  connect(pan,"Out",balance,"Pan")
  connect(pan,"Out",panRange,"In")

  self:createMonoBranch("level",level,"In",level,"Out")
  self:createMonoBranch("pan", pan, "In", pan,"Out")
end

function LinearSamplingVCA:onLoadViews(objects,branches)
  local views = {
    expanded = {"level"},
    collapsed = {},
  }

  local controls = {}

  controls.level = GainBias {
    button = "level",
    branch = branches.level,
    description = "Level",
    gainbias = objects.level,
    range = objects.levelRange,
    biasMap = Encoder.getMap("[-5,5]"),
    biasUnits = app.unitNone,
    initialBias = 0.0,
    gainMap = Encoder.getMap("gain"),
  }

  if objects.pan then
    controls.pan = GainBias {
      button = "pan",
      branch = branches.pan,
      description = "Pan",
      gainbias = objects.pan,
      range = objects.panRange,
      biasMap = Encoder.getMap("default"),
      biasUnits = app.unitNone,
    }

    views.expanded[2] = "pan"
  end

  return controls, views
end

return LinearSamplingVCA
