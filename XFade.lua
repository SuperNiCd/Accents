local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local GainBias = require "Unit.ViewControl.GainBias"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local MenuHeader = require "Unit.MenuControl.Header"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local XFade = Class{}
XFade:include(Unit)

function XFade:init(args)
  args.title = "XFade"
  args.mnemonic = "XF"
  Unit.init(self,args)
end

function XFade:onLoadGraph(channelCount)
  local a = self:addObject("a",app.ConstantGain())
  local b = self:addObject("b",app.ConstantGain())
  local crossfade = self:addObject("crossfade",app.CrossFade())
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  local level = self:addObject("level",app.GainBias())
  local levelRange = self:addObject("levelRange",app.MinMax())
  self:addMonoBranch("inA", a, "In", a,"Out")
  self:addMonoBranch("inB", b, "In", b,"Out")
  self:addMonoBranch("xfade",level,"In",level,"Out")

--   local vcaA = self:addObject("Multiply","vcaA")
--   local vcaB = self:addObject("Multiply","vcaB")




--   connect(a,"Out",vcaB,"Left")
--   connect(b,"Out",vcaA,"Left")
  connect(a,"Out",crossfade,"B")
  connect(b,"Out",crossfade,"A") 
  connect(level,"Out",levelRange,"In")
  connect(level,"Out",crossfade,"Fade")
  connect(crossfade,"Out",self,"Out1")

  if channelCount > 1 then
    connect(crossfade,"Out",self,"Out2")
  end

  
end

local function linMap(min,max,superCoarse,coarse,fine,superFine)
  local map = app.LinearDialMap(min,max)
  map:setSteps(superCoarse,coarse,fine,superFine)
  return map
end

local fadeMap = linMap(0,1,1,0.1,0.01,0.001)

local views = {
  expanded = {"a","b","crossfade"},
  collapsed = {},
  input = {}
}

function XFade:onLoadViews(objects,branches)
  local controls = {}

  controls.a = BranchMeter {
    button = "a",
    branch = branches.inA,
    faderParam = objects.a:getParameter("Gain")
  }

  controls.b = BranchMeter {
    button = "b",
    branch = branches.inB,
    faderParam = objects.b:getParameter("Gain")
  }

  controls.crossfade = GainBias {
    button = "xfade",
    description = "Crossfade",
    branch = branches.xfade,
    gainbias = objects.level,
    biasMap = fadeMap,
    biasUnits = app.unitNone,
    range = objects.levelRange,
    initialBias = 0.0,
  }

  self:addToMuteGroup(controls.a)
  self:addToMuteGroup(controls.b)

  return controls, views
end

local menu = {
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}


return XFade
