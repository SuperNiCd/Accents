-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local ModeSelect = require "Unit.ViewControl.OptionControl"
local InputGate = require "Unit.ViewControl.InputGate"
local OutputScope = require "Unit.ViewControl.OutputScope"
local GainBias = require "Unit.ViewControl.GainBias"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local GainBias = require "Unit.ViewControl.GainBias"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Logics = Class{}
Logics:include(Unit)

function Logics:init(args)
  args.title = "Logics"
  args.mnemonic = "Lg"
  Unit.init(self,args)
end

function Logics:onLoadGraph(channelCount)

  -- create input circuit objects
  local a = self:createObject("ConstantGain","a")
  local b = self:createObject("ConstantGain","b")
  local sum = self:createObject("Sum","sum")
  a:hardSet("Gain",1.0)
  b:hardSet("Gain",1.0)
  a:setClampInDecibels(-59.9)
  b:setClampInDecibels(-59.9)
  self:createMonoBranch("inA", a, "In", a,"Out")
  self:createMonoBranch("inB", b, "In", b,"Out")
  local compA = self:createObject("Comparator","compA")
  local compB = self:createObject("Comparator","compB")
  compA:hardSet("Hysteresis",0.0)
  compB:hardSet("Hysteresis",0.0)
  compA:setGateMode()
  compB:setGateMode()
  local modA = self:createObject("Multiply","modA")
  local modB = self:createObject("Multiply","modB")

  -- create control objects
  local threshold = self:createObject("ParameterAdapter","threshold")
  local thresholdOutlet = self:createObject("Constant","thresholdOutlet")
  tie(compA,"Threshold",threshold,"Out")
  tie(compB,"Threshold",threshold,"Out")
  tie(thresholdOutlet,"Value",threshold,"Out")
  self:createMonoBranch("threshold",threshold,"In",threshold,"Out")

  local truth = self:createObject("GainBias","truth")
  local falsth = self:createObject("GainBias","falsth")
  local truthRange = self:createObject("MinMax","truthRange")
  local falsthRange = self:createObject("MinMax","falsthRange")

  self:createMonoBranch("true",truth,"In",truth,"Out")
  self:createMonoBranch("false",falsth,"In",falsth,"Out")

  -- create AND logic objects
  local ANDSum1 = self:createObject("Sum","ANDSum1")
  local ANDSum2 = self:createObject("Sum","ANDSum2")
  local compAND = self:createObject("Comparator","compAND")
  compAND:setGateMode()
  compAND:hardSet("Hysteresis",0.0)
  local ANDThreholdAdapter = self:createObject("ParameterAdapter","ANDThreholdAdapter")
  ANDThreholdAdapter:hardSet("Gain",1.0)

  -- create OR logic objects
  local ORSum = self:createObject("Sum","ORSum")
  local compOR = self:createObject("Comparator","compOR")
  compOR:setGateMode()
  compOR:hardSet("Hysteresis",0.0)

  -- create XOR logic objects
  local compXORA = self:createObject("Comparator","compXORA")
  local compXORB = self:createObject("Comparator","compXORB")
  local XORSum1 = self:createObject("Sum","XORSum1")
  local XORSum2 = self:createObject("Sum","XORSum2")
  local XORSum3 = self:createObject("Sum","XORSum3")
  local XORMult1 = self:createObject("Multiply","XORMult1")
  local XORMult2 = self:createObject("Multiply","XORMult2")
  local XORConst = self:createObject("Constant","XORConst")
  XORConst:hardSet("Value",-1.0)
  local compXOR = self:createObject("Comparator","compXOR")
  compXOR:setGateMode()
  compXOR:hardSet("Hysteresis",0.0)
  compXORA:setGateMode()
  compXORA:hardSet("Hysteresis",0.0)
  compXORB:setGateMode()
  compXORB:hardSet("Hysteresis",0.0)

  -- create selection circuit objects
  local selectMult1 = self:createObject("Multiply","selectMult1")
  local selectMult2 = self:createObject("Multiply","selectMult2")
  local selectMult3 = self:createObject("Multiply","selectMult3")
  local selectMult4 = self:createObject("Multiply","selectMult4")
  local ANDSelectorConst = self:createObject("Constant","ANDSelectorConst")
  local ORSelectorConst = self:createObject("Constant","ORSelectorConst")
  local XORSelectorConst = self:createObject("Constant","XORSelectorConst")
  local NOTInverterConst = self:createObject("Constant","NOTInverterConst")
  ANDSelectorConst:hardSet("Value",1.0)
  ORSelectorConst:hardSet("Value",0.0)
  XORSelectorConst:hardSet("Value",0.0)
  NOTInverterConst:hardSet("Value",-1.0)
  local selectMix1 = self:createObject("Sum","selectMix1")
  local selectMix2 = self:createObject("Sum","selectMix2")
  local selectMix3 = self:createObject("Sum","selectMix3")
  local NOTOffsetConst = self:createObject("Constant","NOTOffsetConst")
  NOTOffsetConst:hardSet("Value",0.0)

  -- create output objects
  local outMult1 = self:createObject("Multiply","outMult1")
  local outMult2 = self:createObject("Multiply","outMult2")
  local outMult3 = self:createObject("Multiply","outMult3")
  local outSum1 = self:createObject("Sum","outSum1")
  local outSum2 = self:createObject("Sum","outSum2")
  local negOne = self:createObject("Constant","negOne")
  local one = self:createObject("Constant","one")
  negOne:hardSet("Value",-1.0)
  one:hardSet("Value",1.0)

  -- wire input circuit
  connect(a,"Out",compA,"In")
  connect(b,"Out",compB,"In")
  connect(compA,"Out",modA,"Left")
  connect(compB,"Out",modB,"Left")
  connect(thresholdOutlet,"Out",modA,"Right")
  connect(thresholdOutlet,"Out",modB,"Right")

  -- wire AND logic
  connect(modA,"Out",ANDSum1,"Left")
  connect(modB,"Out",ANDSum1,"Right")
  connect(thresholdOutlet,"Out",ANDSum2,"Left")
  connect(thresholdOutlet,"Out",ANDSum2,"Right")
  connect(ANDSum1,"Out",compAND,"In")
  tie(compAND,"Threshold",ANDThreholdAdapter,"Out")
  connect(ANDSum2,"Out",ANDThreholdAdapter,"In")
  -- compAND to selection circuit input

  --wire OR logic
  connect(modA,"Out",ORSum,"Left")
  connect(modB,"Out",ORSum,"Right")
  connect(ORSum,"Out",compOR,"In")
  tie(compOR,"Threshold",threshold,"Out")
  -- compOR to selection circuit input


  --wire XOR logic
  connect(compOR,"Out",XORSum1,"Left")
  connect(compAND,"Out",XORMult1,"Left")
  connect(XORConst,"Out",XORMult1,"Right")
  connect(XORMult1,"Out",XORSum1,"Right")
  -- XORSum1 to selection circuit

  --wire selection circuit
  connect(compAND,"Out",selectMult1,"Left")
  connect(ANDSelectorConst,"Out",selectMult1,"Right")
  connect(compOR,"Out",selectMult2,"Left")
  connect(ORSelectorConst,"Out",selectMult2,"Right")
  connect(XORSum1,"Out",selectMult3,"Left")
  connect(XORSelectorConst,"Out",selectMult3,"Right")
  connect(selectMult1,"Out",selectMix1,"Left")
  connect(selectMult2,"Out",selectMix1,"Right")
  connect(selectMix1,"Out",selectMix2,"Left")
  connect(selectMult3,"Out",selectMix2,"Right")
  connect(selectMix2,"Out",selectMult4,"Left")
  connect(NOTInverterConst,"Out",selectMult4,"Right")
  connect(selectMult4,"Out",selectMix3,"Left")
  connect(NOTOffsetConst,"Out",selectMix3,"Right")
  --selectMix3 to output circuit

  --connect output circuit
  connect(truth,"Out",outMult1,"Left")
  connect(falsth,"Out",outMult2,"Left")
  connect(truth,"Out",truthRange,"In")
  connect(falsth,"Out",falsthRange,"In")
  connect(selectMix3,"Out",outMult3,"Left")
  connect(selectMix3,"Out",outMult1,"Right")
  connect(negOne,"Out",outMult3,"Right")
  connect(outMult3,"Out",outSum1,"Left")
  connect(one,"Out",outSum1,"Right")
  connect(outSum1,"Out",outMult2,"Right")
  connect(outMult1,"Out",outSum2,"Left")
  connect(outMult2,"Out",outSum2,"Right")
  connect(outSum2,"Out",self,"Out1")
  -- connect(XORSum1,"Out",self,"Out1")

  if channelCount > 1 then
    connect(outSum2,"Out",self,"Out2")
  end

end

local views = {
  expanded = {"a","b","threhold","truth","falseth"},
  collapsed = {},
  input = {}
}

function Logics:onLoadViews(objects,branches)
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

  controls.threhold = GainBias {
    button = "threshold",
    description = "Truth Threhold",
    branch = branches.threshold,
    gainbias = objects.threshold,
    range = objects.threshold,
    biasMap = Encoder.getMap("default"),
    initialBias = 0.1,
  }

  controls.truth = GainBias {
    button = "true",
    description = "True Output",
    branch = branches["true"],
    gainbias = objects.truth,
    range = objects.truthRange,
    biasMap = Encoder.getMap("default"),
    initialBias = 1.0,
  }


  controls.falseth = GainBias {
    button = "false",
    description = "False Output",
    branch = branches["false"],
    gainbias = objects.falsth,
    range = objects.falsthRange,
    biasMap = Encoder.getMap("default"),
    initialBias = 0.0,
  }

  self:addToMuteGroup(controls.a)
  self:addToMuteGroup(controls.b)

  return controls, views
end

local menu = {
  "setHeader",
  "opAND",
  "opOR",
  "opXOR",
  "opNAND",
  "opNOR",
  "opXNOR",
  
  "infoHeader",
  "rename",
  "load",
  "save",
  "edit"
}

local op = "AND"

function Logics:setOp(op)
    local objects = self.objects
    self.op = op
    if op=="AND" then
      objects.ANDSelectorConst:hardSet("Value",1.0)
      objects.ORSelectorConst:hardSet("Value",0.0)
      objects.XORSelectorConst:hardSet("Value",0.0)
      objects.NOTInverterConst:hardSet("Value",1.0)
      objects.NOTOffsetConst:hardSet("Value",0.0)
    elseif op=="OR" then
      objects.ANDSelectorConst:hardSet("Value",0.0)
      objects.ORSelectorConst:hardSet("Value",1.0)
      objects.XORSelectorConst:hardSet("Value",0.0)
      objects.NOTInverterConst:hardSet("Value",1.0)
      objects.NOTOffsetConst:hardSet("Value",0.0)
    elseif op=="XOR" then
      objects.ANDSelectorConst:hardSet("Value",0.0)
      objects.ORSelectorConst:hardSet("Value",0.0)
      objects.XORSelectorConst:hardSet("Value",1.0)
      objects.NOTInverterConst:hardSet("Value",1.0)
      objects.NOTOffsetConst:hardSet("Value",0.0)
    elseif op=="NAND" then
      objects.ANDSelectorConst:hardSet("Value",1.0)
      objects.ORSelectorConst:hardSet("Value",0.0)
      objects.XORSelectorConst:hardSet("Value",0.0)
      objects.NOTInverterConst:hardSet("Value",-1.0)
      objects.NOTOffsetConst:hardSet("Value",1.0)
    elseif op=="NOR" then
      objects.ANDSelectorConst:hardSet("Value",0.0)
      objects.ORSelectorConst:hardSet("Value",1.0)
      objects.XORSelectorConst:hardSet("Value",0.0)
      objects.NOTInverterConst:hardSet("Value",-1.0)
      objects.NOTOffsetConst:hardSet("Value",1.0)
    elseif op=="XNOR" then
      objects.ANDSelectorConst:hardSet("Value",0.0)
      objects.ORSelectorConst:hardSet("Value",0.0)
      objects.XORSelectorConst:hardSet("Value",1.0)
      objects.NOTInverterConst:hardSet("Value",-1.0)
      objects.NOTOffsetConst:hardSet("Value",1.0)
    end
end

function Logics:onLoadMenu(objects,branches)
  local controls = {}

  controls.setHeader = MenuHeader {
    description = string.format("Current op is: %s.",self.op)
  }

  controls.opAND = Task {
    description = "AND",
    task = function()
      self:setOp("AND")
    end
  }

  controls.opOR = Task {
    description = "OR",
    task = function()
        self:setOp("OR")
    end
  }

  controls.opXOR = Task {
    description = "XOR",
    task = function()
      self:setOp("XOR")
    end
  }

  controls.opNAND = Task {
    description = "NAND",
    task = function()
      self:setOp("NAND")
    end
  }

  controls.opNOR = Task {
    description = "NOR",
    task = function()
      self:setOp("NOR")
    end
  }

  controls.opXNOR = Task {
    description = "XNOR",
    task = function()
      self:setOp("XNOR")
    end
  }
  return controls, menu
end

function Logics:onLoadFinished()
  self:setOp("AND")
end

function Logics:serialize()
  local t = Unit.serialize(self)
  t.logicOp = self.op
  return t
end

function Logics:deserialize(t)
  Unit.deserialize(self,t)
  if t.logicOp then
    self:setOp(t.logicOp)
  end
end
return Logics
