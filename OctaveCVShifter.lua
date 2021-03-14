local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local OctaveCVShifter = Class{}
OctaveCVShifter:include(Unit)

function OctaveCVShifter:init(args)
  args.title = "Octave CV Shifter"
  args.mnemonic = "OS"
  Unit.init(self,args)
end

function OctaveCVShifter:onLoadGraph(channelCount)
  --create objects
  local offset = self:addObject("offset",app.ConstantOffset())
  local offsetAdapter = self:addObject("offsetAdapter",app.ParameterAdapter())
  local fixedGain = self:addObject("fixedGain",app.Constant())
  local gain = self:addObject("gain",app.Multiply())
  local mix = self:addObject("mix",app.Sum())
  local quant = self:addObject("quant",libcore.GridQuantizer())

  fixedGain:hardSet("Value",0.1)
  quant:hardSet("Levels",10)

  -- register exported ports
  self:addMonoBranch("octave",offsetAdapter,"In",offsetAdapter,"Out")

  -- connect objects
  connect(self,"In1",mix,"Left")
  connect(offset,"Out",gain,"Left")
  connect(fixedGain,"Out",gain,"Right")
  connect(gain,"Out",quant,"In")
  connect(quant,"Out",mix,"Right")
  connect(mix,"Out",self,"Out1")
  tie(offset,"Offset",offsetAdapter,"Out")

  if channelCount>1 then
    connect(mix,"Out",self,"Out2")
  end
end

local views = {
  expanded = {"octave"},
  collapsed = {},
}

local function intMap(min,max)
  local map = app.LinearDialMap(min,max)
  map:setSteps(5,1,0.25,0.25);
  map:setRounding(1)
  return map
end

local octaveMap = intMap(-4,4)

function OctaveCVShifter:onLoadViews(objects,branches)
  local controls = {}

  controls.octave = GainBias {
    button = "octave",
    description = "Octave Offset",
    branch = branches.octave,
    gainbias = objects.offsetAdapter,
    range = objects.offsetAdapter,
    biasMap = octaveMap,
    biasPrecision = 0,
    initialBias = 0
  }

  return controls, views
end

local menu = {
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

return OctaveCVShifter
