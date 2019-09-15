-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
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
  local a = self:createObject("ConstantGain","a")
  local b = self:createObject("ConstantGain","b")
  local sum = self:createObject("Sum","sum")
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:createMonoBranch("inA", a, "In", a,"Out")
  self:createMonoBranch("inB", b, "In", b,"Out")

  
  local one = self:createObject("Constant","one")
  one:hardSet("Value",1.0)
  local negOne = self:createObject("Constant","negOne")
  negOne:hardSet("Value",-1.0)
  local invert = self:createObject("Multiply","invert")
  local sub = self:createObject("Sum","sub")
  local vcaA = self:createObject("Multiply","vcaA")
  local vcaB = self:createObject("Multiply","vcaB")

  local ab = self:createObject("Comparator","ab")
  ab:setToggleMode()


  self:createMonoBranch("ab",ab,"In",ab,"Out")
    
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
