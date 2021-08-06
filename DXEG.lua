local app = app
local libcore = require "core.libcore"
local libAccents = require "Accents.libAccents"
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local InputGate = require "Unit.ViewControl.InputGate"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Encoder = require "Encoder"

local DXEG = Class {}
DXEG:include(Unit)

function DXEG:init(args)
  args.title = "DXEG"
  args.mnemonic = "Dx"
  Unit.init(self, args)
end

function DXEG:onLoadGraph(channelCount)
  if channelCount == 2 then
    self:loadStereoGraph()
  else
    self:loadMonoGraph()
  end
end

function DXEG:loadMonoGraph()
  local gate = self:addObject("gate", app.Comparator())
  gate:setGateMode()
  local dxeg = self:addObject("dxeg", libAccents.DXEG())
  local l1 = self:addObject("l1", app.GainBias())
  local l2 = self:addObject("l2", app.GainBias())
  local l3 = self:addObject("l3", app.GainBias())
  local l4 = self:addObject("l4", app.GainBias())
  local r1 = self:addObject("r1", app.GainBias())
  local r2 = self:addObject("r2", app.GainBias())
  local r3 = self:addObject("r3", app.GainBias())
  local r4 = self:addObject("r4", app.GainBias())
  local l1Range = self:addObject("l1Range", app.MinMax())
  local l2Range = self:addObject("l2Range", app.MinMax())
  local l3Range = self:addObject("l3Range", app.MinMax())
  local l4Range = self:addObject("l4Range", app.MinMax())
  local r1Range = self:addObject("r1Range", app.MinMax())
  local r2Range = self:addObject("r2Range", app.MinMax())
  local r3Range = self:addObject("r3Range", app.MinMax())
  local r4Range = self:addObject("r4Range", app.MinMax())

  connect(self, "In1", gate, "In")
  connect(gate, "Out", dxeg, "Gate")
  connect(dxeg, "Out", self, "Out1")

  connect(l1, "Out", dxeg, "L1")
  connect(l2, "Out", dxeg, "L2")
  connect(l3, "Out", dxeg, "L3")
  connect(l4, "Out", dxeg, "L4")
  connect(r1, "Out", dxeg, "R1")
  connect(r2, "Out", dxeg, "R2")
  connect(r3, "Out", dxeg, "R3")
  connect(r4, "Out", dxeg, "R4")

  connect(l1, "Out", l1Range, "In")
  connect(l2, "Out", l2Range, "In")
  connect(l3, "Out", l3Range, "In")
  connect(l4, "Out", l4Range, "In")
  connect(r1, "Out", r1Range, "In")
  connect(r2, "Out", r2Range, "In")
  connect(r3, "Out", r3Range, "In")
  connect(r4, "Out", r4Range, "In")

  self:addMonoBranch("l1", l1, "In", l1, "Out")
  self:addMonoBranch("l2", l2, "In", l2, "Out")
  self:addMonoBranch("l3", l3, "In", l3, "Out")
  self:addMonoBranch("l4", l4, "In", l4, "Out")
  self:addMonoBranch("r1", r1, "In", r1, "Out")
  self:addMonoBranch("r2", r2, "In", r2, "Out")
  self:addMonoBranch("r3", r3, "In", r3, "Out")
  self:addMonoBranch("r4", r4, "In", r4, "Out")

end

function DXEG:loadStereoGraph()
  self:loadMonoGraph()
  connect(self.objects.dxeg, "Out", self, "Out2")
end

function DXEG:setOp(op)
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

local menu = {
    "changeViews",
    "changeViewExpanded",
    "changeViewLevels",
    "changeViewRates",
    "setGateBehavior",
    "setGateSustain",
    "setGateLoop",
    "infoHeader",
    "rename",
    "load",
    "save"
  }

local currentView = 'expanded'
function DXEG:changeView(view)
    currentView = view
    self:switchView(view)
end
  
  function DXEG:onShowMenu(objects,branches)
    local controls = {}

    controls.changeViews = MenuHeader {
      description = string.format("Views:")
    }
  
    controls.changeViewExpanded = Task {
      description = "all",
      task = function() self:changeView("expanded") end
    }
  
    controls.changeViewLevels = Task {
      description = "levels",
      task = function() self:changeView("levels") end
    }

    controls.changeViewRates = Task {
        description = "rates",
        task = function() self:changeView("times") end
    }

    controls.setGateBehavior = MenuHeader {
        description = string.format("At lvl 3 if gate high:")
    }

    controls.setGateSustain = Task {
        description = string.format("Sustain"),
        task = function()
            objects.dxeg:setOptionValue("GateHighFlavor",1)
            self.GateHighFlavor = 1
        end
    }

    controls.setGateLoop = Task {
        description = string.format("Loop lvl 1 to lvl 3"),
        task = function()
            objects.dxeg:setOptionValue("GateHighFlavor",2)
            self.GateHighFlavor = 2
        end
    }
  
    return controls, menu
  end

local views = {
  expanded = {
    "input",
    "r1",
    "l1",
    "r2",
    "l2",
    "r3",
    "l3",
    "r4",
    "l4"
  },
  levels = {
      "input",
      "l1",
      "l2",
      "l3",
      "l4"
  },
  rates = {
      "input",
      "r1",
      "r2",
      "r3",
      "r4"
  },
  collapsed = {}
}

function DXEG:onLoadViews(objects, branches)
  local controls = {}

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    comparator = objects.gate
  }

  controls.l1 = GainBias {
    button = "lvl 1",
    branch = branches.l1,
    description = "Level of point 1",
    gainbias = objects.l1,
    range = objects.l1Range,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 1
  }

  controls.r1 = GainBias {
    button = "time 1",
    branch = branches.r1,
    description = "Time to reach lvl 1",
    gainbias = objects.r1,
    range = objects.r1Range,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.050
  }

  controls.l2 = GainBias {
    button = "lvl 2",
    branch = branches.l2,
    description = "Level of point 2",
    gainbias = objects.l2,
    range = objects.l2Range,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.99
  }

  controls.r2 = GainBias {
    button = "time 2",
    branch = branches.r2,
    description = "Time to reach lvl 2",
    gainbias = objects.r2,
    range = objects.r2Range,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.050
  }

  controls.l3 = GainBias {
    button = "lvl 3",
    branch = branches.l3,
    description = "Level of point 3",
    gainbias = objects.l3,
    range = objects.l3Range,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.75
  }

  controls.r3 = GainBias {
    button = "time 3",
    branch = branches.r3,
    description = "Time to reach lvl 3",
    gainbias = objects.r3,
    range = objects.r3Range,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.100
  }

  controls.l4 = GainBias {
    button = "lvl 4",
    branch = branches.l4,
    description = "Level of point 4",
    gainbias = objects.l4,
    range = objects.l4Range,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.000
  }

  controls.r4 = GainBias {
    button = "time 4",
    branch = branches.r4,
    description = "Time to reach lvl 4",
    gainbias = objects.r4,
    range = objects.r4Range,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.500
  }

  function DXEG:serialize()
    local t = Unit.serialize(self)
    t.GateHighFlavor = self.GateHighFlavor
    return t
  end
  
  function DXEG:deserialize(t)
    Unit.deserialize(self,t)
    if t.GateHighFlavor then
      self.GateHighFlavor=t.GateHighFlavor
    end
  end

  function DXEG:onLoadFinished(objects)
    self.objects.dxeg:setOptionValue("GateHighFlavor",1)
  end

  return controls, views
end

return DXEG
