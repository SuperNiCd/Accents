-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local InputGate = require "Unit.ViewControl.InputGate"
local ModeSelect = require "Unit.MenuControl.OptionControl"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local ClockedRandomGate = Class{}
ClockedRandomGate:include(Unit)

function ClockedRandomGate:init(args)
  args.title = "Clocked Random Gate"
  args.mnemonic = "RG"
  Unit.init(self,args)
end

function ClockedRandomGate:onLoadGraph(channelCount)
  local tap = self:createObject("TapTempo","tap")
  tap:setBaseTempo(120)
  local clock = self:createObject("ClockInSeconds","clock")
  local tapEdge = self:createObject("Comparator","tapEdge")
  local syncEdge = self:createObject("Comparator","syncEdge")
  local width = self:createObject("ParameterAdapter","width")
  local multiplier = self:createObject("ParameterAdapter","multiplier")
  local divider = self:createObject("ParameterAdapter","divider")

  local random = self:createObject("WhiteNoise","random")
  local rectify = self:createObject("Rectify","rectify")
  local compare = self:createObject("Comparator","compare")
  local prob = self:createObject("ConstantOffset","prob")
  local probOffset = self:createObject("ParameterAdapter","probOffset")
  local thresh = self:createObject("ParameterAdapter","thresh")
  local one = self:createObject("Constant","one")
  local negOne = self:createObject("Constant","negOne")
  local sum = self:createObject("Sum","sum")
  local invert = self:createObject("Multiply","invert")
  local sh = self:createObject("TrackAndHold","sh")
  local shEdge = self:createObject("Comparator","shEdge")
  local vca = self:createObject("Multiply","vca")

  -- set parameters
  compare:hardSet("Hysteresis",0.0)
  compare:setGateMode()
  rectify:optionSet("Type",3) --full rectification
  one:hardSet("Value",1.0)
  negOne:hardSet("Value",-1.0)
  shEdge:setTriggerMode()
  thresh:hardSet("Gain",1.0)

  -- tie parameters
  tie(clock,"Period",tap,"Base Period")
  tie(clock,"Pulse Width",width,"Out")
  tie(clock,"Multiplier",multiplier,"Out")
  tie(clock,"Divider",divider,"Out")
  tie(prob,"Offset",probOffset,"Out")
  tie(compare,"Threshold",thresh,"Out")

  -- register exported ports
  self:createMonoBranch("sync",syncEdge,"In",syncEdge,"Out")
  self:createMonoBranch("width",width,"In",width,"Out")
  self:createMonoBranch("multiplier",multiplier,"In",multiplier,"Out")
  self:createMonoBranch("divider",divider,"In",divider,"Out")
  self:createMonoBranch("prob",probOffset,"In",probOffset,"Out")

  -- connect objects
  connect(self,"In1",tapEdge,"In")
  connect(tapEdge,"Out",tap,"In")
  --connect(clock,"Out",self,"Out1")
  connect(syncEdge,"Out",clock,"Sync")
  connect(random,"Out",rectify,"In")
  connect(rectify,"Out",sh,"In")
  connect(shEdge,"Out",sh,"Track")
  connect(clock,"Out",shEdge,"In")
  connect(sh,"Out",compare,"In")
  connect(compare,"Out",vca,"Left")
  connect(clock,"Out",vca,"Right")

  connect(prob,"Out",invert,"Left")
  connect(negOne,"Out",invert,"Right")
  connect(invert,"Out",sum,"Left")
  connect(one,"Out",sum,"Right")
  connect(sum,"Out",thresh,"In")

  connect(vca,"Out",self,"Out1")

  if channelCount>1 then
    connect(vca,"Out",self,"Out2")
  end
end

function ClockedRandomGate:setAny()
  local map = Encoder.getMap("[1,32]")
  self.controls.mult:setBiasMap(map)
  self.controls.mult:setBiasPrecision(3)
  self.controls.div:setBiasMap(map)
  self.controls.div:setBiasPrecision(3)
end

function ClockedRandomGate:setRational()
  local map = Encoder.getMap("int[1,32]")
  self.controls.mult:setBiasMap(map)
  self.controls.mult:setBiasPrecision(0)
  self.controls.div:setBiasMap(map)
  self.controls.div:setBiasPrecision(0)
end

local menu = {"infoHeader","rename","load","save","edit","rational"}

function ClockedRandomGate:onLoadMenu(objects,branches)
  local controls = {}

  controls.rational = ModeSelect {
    description = "Allowed Mult/Div",
    option = objects.clock:getOption("Rational"),
    choices = {"any","rational only"},
    boolean = true,
    onUpdate = function(choice)
      if choice=="any" then
        self:setAny()
      else
        self:setRational()
      end
    end
  }
  return controls, menu
end

function ClockedRandomGate:deserialize(t)
  Unit.deserialize(self,t)
  local Serialization = require "Persist.Serialization"
  local rational = Serialization.get("objects/clock/options/Rational",t)
  if rational and rational==0 then
    self:setAny()
  end
end

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local probMap = linMap(0,1,0.1,0.01,0.001,0.001)

local views = {
  expanded = {"tap","prob","mult","div","sync","width"},
  collapsed = {},
}

function ClockedRandomGate:onLoadViews(objects,branches)
  local controls = {}

  controls.tap = InputGate {
    button = "clock",
    description = "Clock or Tap",
    unit = self,
    comparator = objects.tapEdge,
  }

  controls.mult = GainBias {
    button = "mult",
    description = "Clock Multiplier",
    branch = branches.multiplier,
    gainbias = objects.multiplier,
    range = objects.multiplier,
    biasMap = Encoder.getMap("int[1,32]"),
    biasPrecision = 0,
    initialBias = 1
  }

  controls.div = GainBias {
    button = "div",
    description = "Clock Divider",
    branch = branches.divider,
    gainbias = objects.divider,
    range = objects.divider,
    biasMap = Encoder.getMap("int[1,32]"),
    biasPrecision = 0,
    initialBias = 1
  }

  controls.sync = Gate {
    button = "sync",
    description = "Sync",
    branch = branches.sync,
    comparator = objects.syncEdge,
  }

  controls.width = GainBias {
    button = "width",
    description = "Pulse Width",
    branch = branches.width,
    gainbias = objects.width,
    range = objects.width,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.5
  }

  controls.prob = GainBias {
    button = "prob",
    description = "Gate Probability",
    branch = branches.prob,
    gainbias = objects.probOffset,
    range = objects.probOffset,
    biasMap = probMap,
    biasUnits = app.unitNone,
    initialBias = 1.0
  }

  return controls, views
end

return ClockedRandomGate
