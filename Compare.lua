local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local GainBias = require "Unit.ViewControl.GainBias"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local CompareUnit = Class{}
CompareUnit:include(Unit)

function CompareUnit:init(args)
  args.title = "Compare"
  args.mnemonic = "Cp"
  Unit.init(self,args)
end

function CompareUnit:onLoadGraph()
  -- create objects
  local compare = self:addObject("compare",app.Comparator())
  local threshold = self:addObject("threshold",app.ParameterAdapter())
  local hysteresis = self:addObject("hysteresis",app.ParameterAdapter())
  -- connect inputs/outputs
  connect(self,"In1",compare,"In")
  connect(compare,"Out",self,"Out1")

  tie(compare,"Hysteresis",hysteresis,"Out")
  self:addMonoBranch("hyst",hysteresis,"In",hysteresis,"Out")
  tie(compare,"Threshold", threshold, "Out")
  self:addMonoBranch("thresh",threshold,"In",threshold,"Out")
end

local views = {
  expanded = {"mode","input", "thresh", "hyst"},
  collapsed = {},
  input = {"scope","input"}
}

function CompareUnit:onLoadViews(objects,branches)
  local controls = {}

  controls.mode = ModeSelect {
    button = "o",
    description = "Type",
    option = objects.compare:getOption("Mode"),
    choices = {"toggle","gate","trigger"},
    muteOnChange = true
  }

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    unit = self,
    comparator = objects.compare,
  }

  controls.hyst = GainBias {
    button = "hyst",
    description = "Hysteresis",
    branch = branches.hyst,
    gainbias = objects.hysteresis,
    range = objects.hysteresis,
    biasMap = Encoder.getMap("unit"),
    -- biasUnits = app.unitSecs,
    initialBias = 0.03
  }

  controls.thresh = GainBias {
    button = "thresh",
    description = "Threshold",
    branch = branches.thresh,
    gainbias = objects.threshold,
    range = objects.threshold,
    biasMap = Encoder.getMap("default"),
    biasUnits = app.unitNone,
    initialBias = 0.10
  }

  return controls, views
end

return CompareUnit
