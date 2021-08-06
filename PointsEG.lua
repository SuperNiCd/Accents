local app = app
local libcore = require "core.libcore"
local libAccents = require "Accents.libAccents"
local Class = require "Base.Class"
local Unit = require "Unit"
local GainBias = require "Unit.ViewControl.GainBias"
local InputGate = require "Unit.ViewControl.InputGate"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local OptionControl = require "Unit.MenuControl.OptionControl"
local Encoder = require "Encoder"

local Points = Class {}
Points:include(Unit)

function Points:init(args)
  args.title = "Points"
  args.mnemonic = "Pt"
  Unit.init(self, args)
end

function Points:onLoadGraph(channelCount)
  if channelCount == 2 then
    self:loadStereoGraph()
  else
    self:loadMonoGraph()
  end
end

function Points:loadMonoGraph()
  local gate = self:addObject("gate", app.Comparator())
  gate:setGateMode()
  local points = self:addObject("points", libAccents.PointsEG())
  local l1Adapter = self:addObject("l1Adapter", app.ParameterAdapter())
  local l2Adapter = self:addObject("l2Adapter", app.ParameterAdapter())
  local l3Adapter = self:addObject("l3Adapter", app.ParameterAdapter())
  local l4Adapter = self:addObject("l4Adapter", app.ParameterAdapter())
  local r1Adapter = self:addObject("r1Adapter", app.ParameterAdapter())
  local r2Adapter = self:addObject("r2Adapter", app.ParameterAdapter())
  local r3Adapter = self:addObject("r3Adapter", app.ParameterAdapter())
  local r4Adapter = self:addObject("r4Adapter", app.ParameterAdapter())
  -- local c1 = self:addObject("c1", app.GainBias())
  -- local l1Range = self:addObject("l1Range", app.MinMax())
  -- local l2Range = self:addObject("l2Range", app.MinMax())
  -- local l3Range = self:addObject("l3Range", app.MinMax())
  -- local l4Range = self:addObject("l4Range", app.MinMax())
  -- local r1Range = self:addObject("r1Range", app.MinMax())
  -- local r2Range = self:addObject("r2Range", app.MinMax())
  -- local r3Range = self:addObject("r3Range", app.MinMax())
  -- local r4Range = self:addObject("r4Range", app.MinMax())
  local c1Adapter = self:addObject("c1Adapter", app.ParameterAdapter())
  local c2Adapter = self:addObject("c2Adapter", app.ParameterAdapter())
  local c3Adapter = self:addObject("c3Adapter", app.ParameterAdapter())
  local c4Adapter = self:addObject("c4Adapter", app.ParameterAdapter())

  tie(points,"L1",l1Adapter,"Out")
  tie(points,"L2",l2Adapter,"Out")
  tie(points,"L3",l3Adapter,"Out")
  tie(points,"L4",l4Adapter,"Out")
  tie(points,"R1",r1Adapter,"Out")
  tie(points,"R2",r2Adapter,"Out")
  tie(points,"R3",r3Adapter,"Out")
  tie(points,"R4",r4Adapter,"Out")
  tie(points,"C1",c1Adapter,"Out")
  tie(points,"C2",c2Adapter,"Out")
  tie(points,"C3",c3Adapter,"Out")
  tie(points,"C4",c4Adapter,"Out")

  self:addMonoBranch("l1",l1Adapter,"In",l1Adapter,"Out")
  self:addMonoBranch("l2",l2Adapter,"In",l2Adapter,"Out")
  self:addMonoBranch("l3",l3Adapter,"In",l3Adapter,"Out")
  self:addMonoBranch("l4",l4Adapter,"In",l4Adapter,"Out")
  
  self:addMonoBranch("r1",r1Adapter,"In",r1Adapter,"Out")
  self:addMonoBranch("r2",r2Adapter,"In",r2Adapter,"Out")
  self:addMonoBranch("r3",r3Adapter,"In",r3Adapter,"Out")
  self:addMonoBranch("r4",r4Adapter,"In",r4Adapter,"Out")
  
  self:addMonoBranch("c1",c1Adapter,"In",c1Adapter,"Out")
  self:addMonoBranch("c2",c2Adapter,"In",c2Adapter,"Out")
  self:addMonoBranch("c3",c3Adapter,"In",c3Adapter,"Out")
  self:addMonoBranch("c4",c4Adapter,"In",c4Adapter,"Out")

  connect(self, "In1", gate, "In")
  connect(gate, "Out", points, "Gate")
  connect(points, "Out", self, "Out1")

  -- connect(l1, "Out", points, "L1")
  -- connect(l2, "Out", points, "L2")
  -- connect(l3, "Out", points, "L3")
  -- connect(l4, "Out", points, "L4")
  -- connect(r1, "Out", points, "R1")
  -- connect(r2, "Out", points, "R2")
  -- connect(r3, "Out", points, "R3")
  -- connect(r4, "Out", points, "R4")

  -- connect(l1, "Out", l1Range, "In")
  -- connect(l2, "Out", l2Range, "In")
  -- connect(l3, "Out", l3Range, "In")
  -- connect(l4, "Out", l4Range, "In")
  -- connect(r1, "Out", r1Range, "In")
  -- connect(r2, "Out", r2Range, "In")
  -- connect(r3, "Out", r3Range, "In")
  -- connect(r4, "Out", r4Range, "In")

  -- self:addMonoBranch("l1", l1, "In", l1, "Out")
  -- self:addMonoBranch("l2", l2, "In", l2, "Out")
  -- self:addMonoBranch("l3", l3, "In", l3, "Out")
  -- self:addMonoBranch("l4", l4, "In", l4, "Out")
  -- self:addMonoBranch("r1", r1, "In", r1, "Out")
  -- self:addMonoBranch("r2", r2, "In", r2, "Out")
  -- self:addMonoBranch("r3", r3, "In", r3, "Out")
  -- self:addMonoBranch("r4", r4, "In", r4, "Out")

end

function Points:loadStereoGraph()
  self:loadMonoGraph()
  connect(self.objects.points, "Out", self, "Out2")
end



local menu = {
    "changeViews",
    "changeViewExpanded",
    "changeViewLevelTime",
    "changeViewLevels",
    "changeViewRates",
    "changeViewCurves",
    "segmentViews",
    "changeSeg1",
    "changeSeg2",
    "changeSeg3",
    "changeSeg4",
    "setGateBehavior",
    -- "setGateSustain",
    -- "setGateLoop",
    "gateHigh",
    "retrigger",
    "infoHeader",
    "rename",
    "load",
    "save"
  }

local currentView = 'expanded'
function Points:changeView(view)
    currentView = view
    self:switchView(view)
end
  
  function Points:onShowMenu(objects,branches)
    local controls = {}

    controls.changeViews = MenuHeader {
      description = string.format("Categorized Views:")
    }
  
    controls.changeViewExpanded = Task {
      description = "all",
      task = function() self:changeView("expanded") end
    }

    controls.changeViewLevelTime = Task {
      description = "time/lvl",
      task = function() self:changeView("leveltime") end
    }
  
    controls.changeViewLevels = Task {
      description = "levels",
      task = function() self:changeView("levels") end
    }

    controls.changeViewRates = Task {
        description = "times",
        task = function() self:changeView("times") end
    }

    controls.changeViewCurves = Task {
      description = "curves",
      task = function() self:changeView("curves") end
  }    

  controls.segmentViews = MenuHeader {
    description = string.format("Segment Views:")
  }

  controls.changeSeg1 = Task {
    description = "1",
    task = function() self:changeView("seg1") end
  }  

  controls.changeSeg2 = Task {
    description = "2",
    task = function() self:changeView("seg2") end
  }  

  controls.changeSeg3 = Task {
    description = "3",
    task = function() self:changeView("seg3") end
  }  

  controls.changeSeg4 = Task {
    description = "4",
    task = function() self:changeView("seg4") end
  }  

    controls.setGateBehavior = MenuHeader {
        description = string.format("Gate Options:")
    }

    controls.gateHigh = OptionControl {
      description = "Held Gate",
      option = objects.points:getOption("GateHighFlavor"),
      choices = {
        "sustain",
        "loop"
      }
    }

    controls.retrigger = OptionControl {
      description = "Retrigger",
      option = objects.points:getOption("Retrigger"),
      choices = {
        "analog",
        "digital"
      }
    }

    -- controls.setGateSustain = Task {
    --     description = string.format("Sustain"),
    --     task = function()
    --         objects.points:setOptionValue("GateHighFlavor",1)
    --         self.GateHighFlavor = 1
    --     end
    -- }

    -- controls.setGateLoop = Task {
    --     description = string.format("Loop lvl 1 to lvl 3"),
    --     task = function()
    --         objects.points:setOptionValue("GateHighFlavor",2)
    --         self.GateHighFlavor = 2
    --     end
    -- }
  
    return controls, menu
  end

local views = {
  expanded = {
    "input",
    "r1",
    "l1",
    "c1",
    "r2",
    "l2",
    "c2",
    "r3",
    "l3",
    "c3",
    "r4",
    "l4",
    "c4"
  },
  leveltime = {
    "input",
    "r1",
    "l1",
    "r2",
    "l2",
    "r3",
    "l3",
    "r4",
    "l4",
  },
  levels = {
      "input",
      "l1",
      "l2",
      "l3",
      "l4"
  },
  times = {
      "input",
      "r1",
      "r2",
      "r3",
      "r4"
  },
  curves = {
    "input",
    "c1",
    "c2",
    "c3",
    "c4"
},
seg1 = {
  "input",
  "r1",
  "l1",
  "c1"
},
seg2 = {
  "input",
  "r2",
  "l2",
  "c2"
},
seg3 = {
  "input",
  "r3",
  "l3",
  "c3"
},
seg4 = {
  "input",
  "r4",
  "l4",
  "c4"
},
  collapsed = {}
}

function Points:onLoadViews(objects, branches)
  local controls = {}

  controls.input = InputGate {
    button = "input",
    description = "Unit Input",
    comparator = objects.gate
  }

  controls.l1 = GainBias {
    button = "level 1",
    branch = branches.l1,
    description = "Level of point 1",
    gainbias = objects.l1Adapter,
    range = objects.l1Adapter,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 1
  }

  controls.r1 = GainBias {
    button = "time 1",
    branch = branches.r1,
    description = "Time to reach lvl 1",
    gainbias = objects.r1Adapter,
    range = objects.r1Adapter,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.050
  }

  controls.c1 = GainBias {
    button = "curve 1",
    description = "Curve lvl 4-1",
    branch = branches.c1,
    gainbias = objects.c1Adapter,
    range = objects.c1Adapter,
    biasMap = Encoder.getMap("default"),
    biasUnits = app.unitNone,
    initialBias = 0.0
  }

  controls.l2 = GainBias {
    button = "level 2",
    branch = branches.l2,
    description = "Level of point 2",
    gainbias = objects.l2Adapter,
    range = objects.l2Adapter,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.99
  }

  controls.r2 = GainBias {
    button = "time 2",
    branch = branches.r2,
    description = "Time to reach lvl 2",
    gainbias = objects.r2Adapter,
    range = objects.r2Adapter,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.050
  }

  controls.c2 = GainBias {
    button = "curve 2",
    description = "Curve lvl 1-2",
    branch = branches.c2,
    gainbias = objects.c2Adapter,
    range = objects.c2Adapter,
    biasMap = Encoder.getMap("default"),
    biasUnits = app.unitNone,
    initialBias = 0.0
  }

  controls.l3 = GainBias {
    button = "level 3",
    branch = branches.l3,
    description = "Level of point 3",
    gainbias = objects.l3Adapter,
    range = objects.l3Adapter,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.75
  }

  controls.r3 = GainBias {
    button = "time 3",
    branch = branches.r3,
    description = "Time to reach lvl 3",
    gainbias = objects.r3Adapter,
    range = objects.r3Adapter,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.100
  }

  controls.c3 = GainBias {
    button = "curve 3",
    description = "Curve lvl 2-3",
    branch = branches.c3,
    gainbias = objects.c3Adapter,
    range = objects.c3Adapter,
    biasMap = Encoder.getMap("default"),
    biasUnits = app.unitNone,
    initialBias = 0.0
  }

  controls.l4 = GainBias {
    button = "level 4",
    branch = branches.l4,
    description = "Level of point 4",
    gainbias = objects.l4Adapter,
    range = objects.l4Adapter,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.000
  }

  controls.r4 = GainBias {
    button = "time 4",
    branch = branches.r4,
    description = "Time to reach lvl 4",
    gainbias = objects.r4Adapter,
    range = objects.r4Adapter,
    biasMap = Encoder.getMap("ADSR"),
    biasUnits = app.unitSecs,
    initialBias = 0.500
  }

  controls.c4 = GainBias {
    button = "curve 4",
    description = "Curve lvl 3-4",
    branch = branches.c4,
    gainbias = objects.c4Adapter,
    range = objects.c4Adapter,
    biasMap = Encoder.getMap("default"),
    biasUnits = app.unitNone,
    initialBias = 0.0
  }


  return controls, views
end

function Points:serialize()
  local t = Unit.serialize(self)
  t.GateHighFlavor = self.GateHighFlavor
  return t
end

function Points:deserialize(t)
  Unit.deserialize(self,t)
  if t.GateHighFlavor then
    self.GateHighFlavor=t.GateHighFlavor
  end
end

function Points:onLoadFinished(objects)
  self.objects.points:setOptionValue("GateHighFlavor",1)
end


return Points
