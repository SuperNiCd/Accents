local app = app
local Class = require "Base.Class"
local libAccents = require "Accents.libAccents"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local GainBias = require "Unit.ViewControl.GainBias"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Maths = Class{}
Maths:include(Unit)

function Maths:init(args)
  args.title = "Maths"
  args.mnemonic = "Ma"
  Unit.init(self,args)
end

function Maths:onLoadGraph()
  local maths = self:addObject("maths",libAccents.Maths())
  local a = self:addObject("a",app.ConstantGain())
  local b = self:addObject("b",app.ConstantGain())
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:addMonoBranch("inA", a, "In", a,"Out")
  self:addMonoBranch("inB", b, "In", b,"Out")

  connect(a,"Out",maths,"a")
  connect(b,"Out",maths,"b")
  connect(maths,"Out",self,"Out1")

end

local views = {
  expanded = {"a","b"},
  collapsed = {},
  input = {}
}

function Maths:onLoadViews(objects,branches)
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

  self:addToMuteGroup(controls.a)
  self:addToMuteGroup(controls.b)

  return controls, views
end

local menu = {
  "setHeader",
  "min",
  "max",
  "mean",
  "div",
  "inv",
  "mod",
  "tanh",
  "atan",

  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function Maths:setOp(op)
  local objects = self.objects
  self.op = op

  if op=="MIN" then
    objects.maths:setOptionValue("Operation",1)
  elseif op=="MAX" then
    objects.maths:setOptionValue("Operation",2)
  elseif op=="MEAN" then
    objects.maths:setOptionValue("Operation",3)
  elseif op=="DIV" then
    objects.maths:setOptionValue("Operation",4)    
  elseif op=="INV" then
    objects.maths:setOptionValue("Operation",5)       
  elseif op=="MOD" then
    objects.maths:setOptionValue("Operation",6)    
  elseif op=="TANH" then
    objects.maths:setOptionValue("Operation",7)   
  elseif op=="ATAN" then
    objects.maths:setOptionValue("Operation",8)             
  end
end

function Maths:onShowMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Current op is: %s.", self.op)
  }

  controls.max = Task {
    description = "MAX",
    task = function()
      self:setOp("MAX")
    end
  }

  controls.min = Task {
    description = "MIN",
    task = function()
      self:setOp("MIN")
    end
  }

  controls.mean = Task {
    description = "MEAN",
    task = function()
      self:setOp("MEAN")
    end
  }

  controls.div = Task {
    description = "DIV",
    task = function()
      self:setOp("DIV")
    end
  }  

  controls.inv = Task {
    description = "INV",
    task = function()
      self:setOp("INV")
    end
  }    

  controls.mod = Task {
    description = "MOD",
    task = function()
      self:setOp("MOD")
    end
  }      

  controls.tanh = Task {
    description = "TANH",
    task = function()
      self:setOp("TANH")
    end
  }    
  
  controls.atan = Task {
    description = "ATAN",
    task = function()
      self:setOp("ATAN")
    end
  }      

  return controls, menu
end

function Maths:onLoadFinished()
  self:setOp("MIN")
end

function Maths:serialize()
  local t = Unit.serialize(self)
  t.mathOp = self.op
  return t
end

function Maths:deserialize(t)
  Unit.deserialize(self,t)
  if t.mathOp then
    self:setOp(t.mathOp)
  end
end

return Maths
