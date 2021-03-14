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

local ABSwitch = Class{}
ABSwitch:include(Unit)

function ABSwitch:init(args)
  args.title = "AB Switch"
  args.mnemonic = "AB"
  Unit.init(self,args)
end

function ABSwitch:onLoadGraph(channelCount)
  local a = self:addObject("a",app.ConstantGain())
  local b = self:addObject("b",app.ConstantGain())
  local sum = self:addObject("sum",app.Sum())
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:addMonoBranch("inA", a, "In", a,"Out")
  self:addMonoBranch("inB", b, "In", b,"Out")

  
  local one = self:addObject("one",app.Constant())
  one:hardSet("Value",1.0)
  local negOne = self:addObject("negOne",app.Constant())
  negOne:hardSet("Value",-1.0)
  local invert = self:addObject("invert",app.Multiply())
  local sub = self:addObject("sub",app.Sum())
  local vcaA = self:addObject("vcaA",app.Multiply())
  local vcaB = self:addObject("vcaB",app.Multiply())

  local ab = self:addObject("ab",app.Comparator())
  ab:setToggleMode()


  self:addMonoBranch("ab",ab,"In",ab,"Out")
    
  connect(b,"Out",vcaA,"Left")
  connect(ab,"Out",vcaA,"Right")
  connect(vcaA,"Out",sum,"Left")
  connect(a,"Out",vcaB,"Left")
  connect(ab,"Out",invert,"Left")
  connect(negOne,"Out",invert,"Right")
  connect(invert,"Out",sub,"Left")
  connect(one,"Out",sub,"Right")
  connect(sub,"Out",vcaB,"Right")
  connect(vcaB,"Out",sum,"Right")
  connect(sum,"Out",self,"Out1")

  if channelCount > 1 then
    connect(sum,"Out",self,"Out2")
  end

  
end

local views = {
  expanded = {"ab","a","b"},
  collapsed = {},
  input = {}
}

function ABSwitch:onLoadViews(objects,branches)
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

  controls.ab = Gate {
    button = "ab",
    description = "Output A/B",
    branch = branches.ab,
    comparator = objects.ab,
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


return ABSwitch
