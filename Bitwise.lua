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

local Bitwise = Class{}
Bitwise:include(Unit)

function Bitwise:init(args)
  args.title = "Bitwise"
  args.mnemonic = "BW"
  Unit.init(self,args)
end

function Bitwise:onLoadGraph()
  local bitwise = self:addObject("bitwise",libAccents.Bitwise())
  local a = self:addObject("a",app.ConstantGain())
  local b = self:addObject("b",app.ConstantGain())
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:addMonoBranch("inA", a, "In", a,"Out")
  self:addMonoBranch("inB", b, "In", b,"Out")

  connect(a,"Out",bitwise,"a")
  connect(b,"Out",bitwise,"b")
  connect(bitwise,"Out",self,"Out1")

end

local views = {
  expanded = {"a","b"},
  collapsed = {},
  input = {}
}

function Bitwise:onLoadViews(objects,branches)
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
  "a",
  "b",
  "andop",
  "orop",
  "xorop",
  "nandop",
  "norop",
  "xnorop",

  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

function Bitwise:setOp(op)
  local objects = self.objects
  self.op = op

  if op=="AONLY" then
    objects.bitwise:setOptionValue("Operation",1)
  elseif op=="BONLY" then
    objects.bitwise:setOptionValue("Operation",2)
  elseif op=="AND" then
    objects.bitwise:setOptionValue("Operation",3)
  elseif op=="OR" then
    objects.bitwise:setOptionValue("Operation",4)    
  elseif op=="XOR" then
    objects.bitwise:setOptionValue("Operation",5)       
  elseif op=="NAND" then
    objects.bitwise:setOptionValue("Operation",6)       
  elseif op=="NOR" then
    objects.bitwise:setOptionValue("Operation",7)       
  elseif op=="XNOR" then
    objects.bitwise:setOptionValue("Operation",8)       
  end    
end

function Bitwise:onShowMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Current op is: %s.", self.op)
  }

  controls.a = Task {
    description = "AONLY",
    task = function()
      self:setOp("AONLY")
    end
  }

  controls.b = Task {
    description = "BONLY",
    task = function()
      self:setOp("BONLY")
    end
  }

  controls.andop = Task {
    description = "AND",
    task = function()
      self:setOp("AND")
    end
  }

  controls.orop = Task {
    description = "OR",
    task = function()
      self:setOp("OR")
    end
  }  

  controls.xorop = Task {
    description = "XOR",
    task = function()
      self:setOp("XOR")
    end
  }        

  controls.nandop = Task {
    description = "NAND",
    task = function()
      self:setOp("NAND")
    end
  }     
  
  controls.norop = Task {
    description = "NOR",
    task = function()
      self:setOp("NOR")
    end
  }     
  
  controls.xnorop = Task {
    description = "XNOR",
    task = function()
      self:setOp("XNOR")
    end
  }       

  return controls, menu
end

function Bitwise:onLoadFinished()
  self:setOp("AONLY")
end

function Bitwise:serialize()
  local t = Unit.serialize(self)
  t.mathOp = self.op
  return t
end

function Bitwise:deserialize(t)
  Unit.deserialize(self,t)
  if t.mathOp then
    self:setOp(t.mathOp)
  end
end
return Bitwise
