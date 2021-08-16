local app = app
local libcore = require "core.libcore"
local libAccents = require "Accents.libAccents"
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local GainBias = require "Unit.ViewControl.GainBias"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local MenuHeader = require "Unit.MenuControl.Header"
local Gate = require "Unit.ViewControl.Gate"
local TunerControl = require "Accents.TunerControl"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Tuner = Class {}
Tuner:include(Unit)

function Tuner:init(args)
    args.title = "Tuner"
    args.mnemonic = "--"
    Unit.init(self, args)
end

function Tuner:onLoadGraph(channelCount)
    local tuner = self:addObject("tuner", libAccents.Tuner())
    local index = self:addObject("index",app.ParameterAdapter())
    local indexRange = self:addObject("indexRange",app.MinMax())
    self:addMonoBranch("index", index, "In", index, "Out")
    connect(self, "In1", tuner, "In")
    connect(index,"Out",indexRange,"In")
    tie(tuner, "Index", index, "Out")
    connect(tuner,"Out", self, "Out1")
    if channelCount > 1 then
        connect(tuner, "Out", self, "Out2")
    end
end

local views = {
    expanded = {"circle"},
    collapsed = {},
    input = {}
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
    local map = app.LinearDialMap(min,max)
    map:setSteps(superCoarse,coarse,fine,superFine)
    return map
  end

local indexMap = linMap(0, 1.0, 1, 0.1, 0.01, 0.001)

function Tuner:onLoadViews(objects, branches)
    local controls = {}

    -- controls.index = GainBias {
    --     button = "index",
    --     description = "test",
    --     branch = branches.index,
    --     gainbias = objects.index,
    --     range = objects.indexRange,
    --     biasMap = indexMap,
    --     -- biasPrecision = 0,
    --     -- gainMap = indexMap,
    --     initialBias = 1.0,
    --   }

      controls.circle = TunerControl {
        tuner = objects.tuner
      }

    return controls, views
end

local menu = {"infoHeader", "rename", "load", "save", "edit"}

return Tuner
