local app = app
local libcore = require "core.libcore"
local Class = require "Base.Class"
local Unit = require "Unit"
local Pitch = require "Unit.ViewControl.Pitch"
local GainBias = require "Unit.ViewControl.GainBias"
local Gate = require "Unit.ViewControl.Gate"
local InputGate = require "Unit.ViewControl.InputGate"
local Fader = require "Unit.ViewControl.Fader"
local SamplePool = require "Sample.Pool"
local SamplePoolInterface = require "Sample.Pool.Interface"
local SampleEditor = require "Sample.Editor"
local Slices = require "Sample.Slices"
local SlicingView = require "SlicingView"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local Path = require "Path"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Xoxoxo = Class{}
Xoxoxo:include(Unit)

function Xoxoxo:init(args)
  args.title = "Xoxoxo"
  args.mnemonic = "XO"
  Unit.init(self,args)
end

function Xoxoxo:onLoadGraph(channelCount)
    if channelCount==2 then
        self:loadStereoGraph()
    else
        self:loadMonoGraph()
    end
end

function Xoxoxo:loadMonoGraph()

    local localDSP = {}
    local Accents = require "Accents"
    local sampleFilename = Path.join(Accents:getInstallationPath(),"xoxo.wav")
    local sample = SamplePool.load(sampleFilename)

    if not sample then
      local Overlay = require "Overlay"
      Overlay.mainFlashMessage("Could not load %s.",sampleFilename)
    end

    local tune = self:addObject("tune",app.ConstantOffset())
    local tuneRange = self:addObject("tuneRange",app.MinMax())
    local f0 = self:addObject("f0",app.GainBias())
    local f0Range = self:addObject("f0Range",app.MinMax())
    local vca = self:addObject("vca",app.Multiply())
    local level = self:addObject("level",app.GainBias())
    local levelRange = self:addObject("levelRange",app.MinMax())
    local sync = self:addObject("sync",app.Comparator())
    -- local clip = self:addObject("Comparator","clip")
    -- sync:setTriggerMode()
    -- clip:setTriggerMode()
    -- clip:hardSet("Threshold",1.0)

    connect(tune,"Out",tuneRange,"In")
    connect(f0,"Out",f0Range,"In")
    connect(level,"Out",levelRange,"In")

    local opNames = {"A","B","C","D","E","F"}
    for i, name in ipairs(opNames) do
        localDSP["op" .. name] = self:addObject("op" .. name,libcore.SingleCycle())
        localDSP["op" .. name]:setSample(sample.pSample,sample.slices.pSlices)
        localDSP["op" .. name .. "ratio"] = self:addObject("op" .. name .. "ratio",app.GainBias())
        localDSP["op" .. name .. "ratioRange"] = self:addObject("op" .. name .. "ratioRange",app.MinMax())
        localDSP["op" .. name .. "ratioX"] = self:addObject("op" .. name .. "ratioX",app.Multiply())
        localDSP["op" .. name .. "outLevel"] = self:addObject("op" .. name .. "outLevel",app.GainBias())
        localDSP["op" .. name .. "outLevelRange"] = self:addObject("op" .. name .. "outLevelRange",app.MinMax())
        localDSP["op" .. name .. "outVCA"] = self:addObject("op" .. name .. "outVCA",app.Multiply())
        localDSP["op" .. name .. "scan"] = self:addObject("op" .. name .. "scan",app.GainBias())
        localDSP["op" .. name .. "scanRange"] = self:addObject("op" .. name .. "scanRange",app.MinMax())
        localDSP["op" .. name .. "tune"] = self:addObject("op" .. name .. "tune",app.GainBias())
        localDSP["op" .. name .. "tuneRange"] = self:addObject("op" .. name .. "tuneRange",app.MinMax())
        localDSP["op" .. name .. "tuneSum"] = self:addObject("op" .. name .. "tuneSum",app.Sum())
        localDSP["op" .. name .. "track"] = self:addObject("op" .. name .. "track",app.Comparator())
        localDSP["op" .. name .. "trackX"] = self:addObject("op" .. name .. "trackX",app.Multiply())
        localDSP["op" .. name .. "track"]:setToggleMode()
        localDSP["op" .. name .. "track"]:setOptionValue("State",1.0)
        connect(localDSP["op" .. name .. "track"],"Out",localDSP["op" .. name .. "trackX"],"Left")
        connect(localDSP["op" .. name .. "scan"],"Out",localDSP["op" .. name .. "scanRange"],"In")
        connect(localDSP["op" .. name .. "scan"],"Out",localDSP["op" .. name],"Slice Select")
        connect(localDSP["op" .. name .. "ratio"],"Out",localDSP["op" .. name .. "ratioX"],"Left")
        connect(f0,"Out",localDSP["op" .. name .. "ratioX"],"Right")
        connect(localDSP["op" .. name .. "ratioX"],"Out",localDSP["op" .. name .. "tuneSum"],"Left")
        connect(localDSP["op" .. name .. "tune"],"Out",localDSP["op" .. name .. "tuneSum"],"Right")
        connect(localDSP["op" .. name .. "tuneSum"],"Out",localDSP["op" .. name],"Fundamental")
        connect(localDSP["op" .. name .. "tune"],"Out",localDSP["op" .. name .. "tuneRange"],"In")
        connect(localDSP["op" .. name .. "ratio"],"Out",localDSP["op" .. name .. "ratioRange"],"In")
        connect(tune,"Out",localDSP["op" .. name .. "trackX"],"Right")
        connect(localDSP["op" .. name .. "trackX"],"Out",localDSP["op" .. name],"V/Oct")
        connect(sync,"Out",localDSP["op" .. name],"Sync")
        connect(localDSP["op" .. name],"Out",localDSP["op" .. name .. "outVCA"],"Left")
        connect(localDSP["op" .. name .. "outLevel"],"Out",localDSP["op" .. name .. "outVCA"],"Right")
        connect(localDSP["op" .. name .. "outLevel"],"Out",localDSP["op" .. name .. "outLevelRange"],"In")
        
    end

     for i, name in ipairs(opNames) do
        for j, name2 in ipairs(opNames) do
            localDSP["phase" .. name .. name2] = self:addObject("phase" .. name .. name2,app.GainBias())
            localDSP["phaseRange" .. name .. name2] = self:addObject("phaseRange" .. name .. name2,app.MinMax())
            connect(localDSP["phase" .. name .. name2],"Out",localDSP["phaseRange" .. name .. name2],"In")
            localDSP["phaseX" .. name .. name2] = self:addObject("phaseX" .. name .. name2,app.Multiply())
            connect(localDSP["phase" .. name .. name2],"Out",localDSP["phaseX" .. name .. name2],"Left")
            connect(localDSP["op" .. name],"Out",localDSP["phaseX" .. name .. name2],"Right")
            self:addMonoBranch(name .. "to" .. name2,localDSP["phase" .. name .. name2],"In",localDSP["phase" .. name .. name2],"Out")
        end
        for j = 1, 5 do
            localDSP["phaseMixer" .. name .. j] = self:addObject("phaseMixer" .. name .. j,app.Sum())
        end
    end

    for i, name in ipairs(opNames) do
        connect(localDSP["phaseXA" .. name],"Out",localDSP["phaseMixer" .. name .. "1"],"Left")
        connect(localDSP["phaseXB" .. name],"Out",localDSP["phaseMixer" .. name .. "1"],"Right")
        connect(localDSP["phaseXC" .. name],"Out",localDSP["phaseMixer" .. name .. "2"],"Left")
        connect(localDSP["phaseXD" .. name],"Out",localDSP["phaseMixer" .. name .. "2"],"Right")
        connect(localDSP["phaseXE" .. name],"Out",localDSP["phaseMixer" .. name .. "3"],"Left")
        connect(localDSP["phaseXF" .. name],"Out",localDSP["phaseMixer" .. name .. "3"],"Right")
        connect(localDSP["phaseMixer" .. name .. "1"],"Out",localDSP["phaseMixer" .. name .. "4"],"Left")
        connect(localDSP["phaseMixer" .. name .. "2"],"Out",localDSP["phaseMixer" .. name .. "4"],"Right")
        connect(localDSP["phaseMixer" .. name .. "4"],"Out",localDSP["phaseMixer" .. name .. "5"],"Left")
        connect(localDSP["phaseMixer" .. name .. "3"],"Out",localDSP["phaseMixer" .. name .. "5"],"Right")
        connect(localDSP["phaseMixer" .. name .. "5"],"Out",localDSP["op" .. name],"Phase")
    end 

    for i = 1, 5 do
        localDSP["outputMixer" .. i] = self:addObject("outputMixer" .. i,app.Sum())
    end
    connect(localDSP["opAoutVCA"],"Out",localDSP["outputMixer1"],"Left")
    connect(localDSP["opBoutVCA"],"Out",localDSP["outputMixer1"],"Right")
    connect(localDSP["opCoutVCA"],"Out",localDSP["outputMixer2"],"Left")
    connect(localDSP["opDoutVCA"],"Out",localDSP["outputMixer2"],"Right")
    connect(localDSP["opEoutVCA"],"Out",localDSP["outputMixer3"],"Left")
    connect(localDSP["opFoutVCA"],"Out",localDSP["outputMixer3"],"Right")
    connect(localDSP["outputMixer1"],"Out",localDSP["outputMixer4"],"Left")
    connect(localDSP["outputMixer2"],"Out",localDSP["outputMixer4"],"Right")
    connect(localDSP["outputMixer4"],"Out",localDSP["outputMixer5"],"Left")
    connect(localDSP["outputMixer3"],"Out",localDSP["outputMixer5"],"Right")

    connect(localDSP["outputMixer5"],"Out",vca,"Right")
    connect(level,"Out",vca,"Left")
    -- connect(localDSP["outputMixer5"],"Out",clip,"In")
    connect(vca,"Out",self,"Out1")

    self:addMonoBranch("level",level,"In",level,"Out")
    self:addMonoBranch("tune",tune,"In",tune,"Out")
    self:addMonoBranch("sync",sync,"In",sync,"Out")
    self:addMonoBranch("f0",f0,"In",f0,"Out")
    -- self:addMonoBranch("clip",clip,"In",clip,"Out")
    

    for i, name in ipairs(opNames) do
        self:addMonoBranch("ratio" .. name,localDSP["op" .. name .. "ratio"],"In",localDSP["op" .. name .. "ratio"],"Out")
        self:addMonoBranch("outLevel" .. name,localDSP["op" .. name .. "outLevel"],"In",localDSP["op" .. name .. "outLevel"],"Out")
        self:addMonoBranch("scan" .. name,localDSP["op" .. name .. "scan"],"In",localDSP["op" .. name .. "scan"],"Out")
        self:addMonoBranch("tune" .. name,localDSP["op" .. name .. "tune"],"In",localDSP["op" .. name .. "tune"],"Out")
        self:addMonoBranch("track" .. name,localDSP["op" .. name .. "track"],"In",localDSP["op" .. name .. "track"],"Out")
    end


end

function Xoxoxo:loadStereoGraph()
    self:loadMonoGraph()
    connect(self.objects.vca,"Out",self,"Out2")
end

local views = {
  expanded = {"tune","freq","sync","level"},
  outputs = {"outLevelA","outLevelB","outLevelC","outLevelD","outLevelE","outLevelF"},
  ratios = {"ratioA","ratioB","ratioC","ratioD","ratioE","ratioF"},
  scan = {"scanA","scanB","scanC","scanD","scanE","scanF"},
  tune = {"tuneA","tuneB","tuneC","tuneD","tuneE","tuneF"},
  track = {"trackA","trackB","trackC","trackD","trackE","trackF"},
  a = {"outLevelA","ratioA","scanA","tuneA","phaseAA","phaseAB","phaseAC","phaseAD","phaseAE","phaseAF","trackA"},
  b = {"outLevelB","ratioB","scanB","tuneB","phaseBA","phaseBB","phaseBC","phaseBD","phaseBE","phaseBF","trackB"},
  c = {"outLevelC","ratioC","scanC","tuneC","phaseCA","phaseCB","phaseCC","phaseCD","phaseCE","phaseCF","trackC"},
  d = {"outLevelD","ratioD","scanD","tuneD","phaseDA","phaseDB","phaseDC","phaseDD","phaseDE","phaseDF","trackD"},
  e = {"outLevelE","ratioE","scanE","tuneE","phaseEA","phaseEB","phaseEC","phaseED","phaseEE","phaseEF","trackE"},
  f = {"outLevelF","ratioF","scanF","tuneF","phaseFA","phaseFB","phaseFC","phaseFD","phaseFE","phaseFF","trackF"},
  aIn = {"phaseAA","phaseBA","phaseCA","phaseDA","phaseEA","phaseFA"},
  bIn = {"phaseAB","phaseBB","phaseCB","phaseDB","phaseEB","phaseFB"},
  cIn = {"phaseAC","phaseBC","phaseCC","phaseDC","phaseEC","phaseFC"},
  dIn = {"phaseAD","phaseBD","phaseCD","phaseDD","phaseED","phaseFD"},
  eIn = {"phaseAE","phaseBE","phaseCE","phaseDE","phaseEE","phaseFE"},
  fIn = {"phaseAF","phaseBF","phaseCF","phaseDF","phaseEF","phaseFF"},
  phaseAA = {"scope","phaseAA"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
    local map = app.LinearDialMap(min,max)
    map:setSteps(superCoarse,coarse,fine,superFine)
    return map
end

local ratioMap = linMap(0.0,24.0,1.0,1.0,0.1,0.01)
local scanMap = linMap(0.0,1.0,1.0,0.333,0.01,0.001)

function Xoxoxo:onLoadViews(objects,branches)
    local controls = {}

    local opNames = {"A","B","C","D","E","F"}

    for i, name in ipairs(opNames) do
        controls["outLevel" .. name] = GainBias {
            button = name .. " Out",
            description = name .. "to Output Lvl",
            branch = branches["outLevel" .. name],
            gainbias = objects["op" .. name .. "outLevel"],
            range = objects["op" .. name .. "outLevelRange"],
            biasMap = Encoder.getMap("[0,1]"),
            initialBias = 0.0
        }

        controls["ratio" .. name] = GainBias {
            button = name .. " Ratio",
            description = name .. "Freq Ratio",
            branch = branches["ratio" .. name],
            gainbias = objects["op" .. name .. "ratio"],
            range = objects["op" .. name .. "ratioRange"],
            biasMap = ratioMap,
            initialBias = 1.0
        }

        controls["scan" .. name] = GainBias {
            button = name .. " Scan",
            description = name .. "Table Scan",
            branch = branches["scan" ..  name],
            gainbias = objects["op" .. name .. "scan"],
            range = objects["op" .. name .. "scanRange"],
            biasMap = scanMap,
            initialBias = 0.0,
          }

          controls["tune" .. name] = GainBias {
            button = name .. " Fine",
            description = name .. " Fine Freq",
            branch = branches["tune" .. name],
            gainbias = objects["op" .. name .. "tune"],
            range = objects["op" .. name .. "tuneRange"],
            biasMap = Encoder.getMap("oscFreq"),
            biasUnits = app.unitHertz,
            initialBias = 0.0,
            gainMap = Encoder.getMap("freqGain"),
            scaling = app.octaveScaling
        }

        controls["track" .. name] = Gate {
            button = name .. "Track",
            description = name .. " Track V/Oct",
            branch = branches["track" .. name],
            comparator = objects["op" .. name .. "track"],
          }

        for j, name2 in ipairs(opNames) do
            controls["phase" .. name .. name2] = GainBias {
                button = name .. " to " .. name2,
                description = name .. " to " .. name2 .. "Phase Index",
                branch = branches[name .. "to" .. name2],
                gainbias = objects["phase" .. name .. name2],
                range = objects["phaseRange" .. name .. name2],
                biasMap = Encoder.getMap("[0,1]"),
                initialBias = 0.0
            }
        end 

    end

    controls.tune = Pitch {
        button = "V/oct",
        branch = branches.tune,
        description = "V/oct",
        offset = objects.tune,
        range = objects.tuneRange
    }

    controls.freq = GainBias {
        button = "f0",
        description = "Fundamental",
        branch = branches.f0,
        gainbias = objects.f0,
        range = objects.f0Range,
        biasMap = Encoder.getMap("oscFreq"),
        biasUnits = app.unitHertz,
        initialBias = 27.5,
        gainMap = Encoder.getMap("freqGain"),
        scaling = app.octaveScaling
    }


  controls.level = GainBias {
    button = "level",
    description = "Level",
    branch = branches.level,
    gainbias = objects.level,
    range = objects.levelRange,
    biasMap = Encoder.getMap("[-1,1]"),
    initialBias = 0.5,
  }

  controls.sync = Gate {
    button = "sync",
    description = "Sync",
    branch = branches.sync,
    comparator = objects.sync,
  }

--   controls.clip = InputGate {
--     button = "clip",
--     description = "Clip Detector",
--     comparator = objects.clip,
--   }

  return controls, views
end

function Xoxoxo:setSample(sample)
local opNames = {"A","B","C","D","E","F"}
if self.sample then
    self.sample:release(self)
    self.sample = nil
end
self.sample = sample
if self.sample then
    self.sample:claim(self)
end

if sample==nil or sample:getChannelCount()==0 then
    for i, name in ipairs(opNames) do
        self.objects["op" .. name]:setSample(nil,nil)
    end
else
    for i, name in ipairs(opNames) do
        self.objects["op" .. name]:setSample(sample.pSample,sample.slices.pSlices)
    end
end

if self.slicingView then
    self.slicingView:setSample(sample)
end
self:notifyControls("setSample",sample)
end

function Xoxoxo:showSampleEditor()
if self.sample then
    if self.slicingView==nil then
    self.slicingView = SlicingView(self,self.objects.opA)
    self.slicingView:setSample(self.sample)
    end
    self.slicingView:show()
else
    local Overlay = require "Overlay"
    Overlay.mainFlashMessage("You must first select a sample.")
end
end

function Xoxoxo:doDetachSample()
local Overlay = require "Overlay"
Overlay.mainFlashMessage("Sample detached.")
self:setSample()
end

function Xoxoxo:doAttachSampleFromCard()
local task = function(sample)
    if sample then
    local Overlay = require "Overlay"
    Overlay.mainFlashMessage("Attached sample: %s",sample.name)
    self:setSample(sample)
    end
end
local Pool = require "Sample.Pool"
Pool.chooseFileFromCard(self.loadInfo.id,task)
end

function Xoxoxo:doAttachSampleFromPool()
local chooser = SamplePoolInterface(self.loadInfo.id,"choose")
chooser:setDefaultChannelCount(self.channelCount)
chooser:highlight(self.sample)
local task = function(sample)
    if sample then
    local Overlay = require "Overlay"
    Overlay.mainFlashMessage("Attached sample: %s",sample.name)
    self:setSample(sample)
    end
end
chooser:subscribe("done",task)
chooser:show()
end

local menu = {
    "title",
    "changeViews",
    "changeViewMain",
    "changeViewOutputs",
    "changeViewRatios",
    "changeViewWTable",
    "changeViewTune",
    "changeViewTrack",
    "operatorViews",
    "changeViewA",
    "changeViewB",
    "changeViewC",
    "changeViewD",
    "changeViewE",
    "changeViewF",
    "changeViewPMIndex",
    "changeViewAIn",
    "changeViewBIn",
    "changeViewCIn",
    "changeViewDIn",
    "changeViewEIn",
    "changeViewFIn",
    "sampleHeader",
    "selectFromCard",
    "selectFromPool",
    "detachBuffer",
    "editSample",
    "infoHeader",
    "rename",
    "load",
    "save"
  }

local currentView = 'expanded'
function Xoxoxo:changeView(view)
    currentView = view
    self:switchView(view)
end
  
  function Xoxoxo:onShowMenu(objects,branches)
    local controls = {}

    controls.title = MenuHeader {
        description = string.format("XOXOXO - California Stars")
      }

    controls.operatorViews = MenuHeader {
        description = string.format("Operator Views:")
      }
  
    controls.changeViewA = Task {
        description = "A",
        task = function() self:changeView("a") end
    }

    controls.changeViewB = Task {
        description = "B",
        task = function() self:changeView("b") end
    }

    controls.changeViewC = Task {
        description = "C",
        task = function() self:changeView("c") end
    }

    controls.changeViewD = Task {
        description = "D",
        task = function() self:changeView("d") end
    }

    controls.changeViewE = Task {
        description = "E",
        task = function() self:changeView("e") end
    }

    controls.changeViewF = Task {
        description = "F",
        task = function() self:changeView("f") end
    }

    controls.changeViewPMIndex = MenuHeader {
        description = string.format("Phase Modulation Indices:")
      }

    controls.changeViewAIn = Task {
        description = "@A",
        task = function() self:changeView("aIn") end
    }  

    controls.changeViewBIn = Task {
        description = "@B",
        task = function() self:changeView("bIn") end
    }  

    controls.changeViewCIn = Task {
        description = "@C",
        task = function() self:changeView("cIn") end
    }  

    controls.changeViewDIn = Task {
        description = "@D",
        task = function() self:changeView("dIn") end
    }  

    controls.changeViewEIn = Task {
        description = "@E",
        task = function() self:changeView("eIn") end
    }  

    controls.changeViewFIn = Task {
        description = "@F",
        task = function() self:changeView("fIn") end
    }  

    controls.changeViews = MenuHeader {
      description = string.format("Aggregate Views:")
    }
  
    controls.changeViewMain = Task {
      description = "main",
      task = function() self:changeView("expanded") end
    }
  
    controls.changeViewOutputs = Task {
      description = "outputs",
      task = function() self:changeView("outputs") end
    }

    controls.changeViewRatios = Task {
        description = "ratios",
        task = function() self:changeView("ratios") end
    }

    controls.changeViewWTable = Task {
        description = "wtable",
        task = function() self:changeView("scan") end
    }

    controls.changeViewTune = Task {
        description = "freqs",
        task = function() self:changeView("tune") end
    }

    controls.changeViewTrack= Task {
        description = "track",
        task = function() self:changeView("track") end
    }
    controls.sampleHeader = MenuHeader {
        description = "Sample Menu"
      }
    
    controls.selectFromCard = Task {
    description = "Select from Card",
    task = function() self:doAttachSampleFromCard() end
    }

    controls.selectFromPool = Task {
    description = "Select from Pool",
    task = function() self:doAttachSampleFromPool() end
    }

    controls.detachBuffer = Task {
    description = "Detach Buffer",
    task = function() self:doDetachSample() end
    }

    controls.editSample = Task {
    description = "Edit Buffer",
    task = function() self:showSampleEditor() end
    }

    local sub = {}
    if self.sample then
      sub[1] = {
        position = app.GRID5_LINE1,
        justify = app.justifyLeft,
        text = "Attached Sample:"
      }
      sub[2] = {
        position = app.GRID5_LINE2,
        justify = app.justifyLeft,
        text = "+ "..self.sample:getFilenameForDisplay(24)
      }
      sub[3] = {
        position = app.GRID5_LINE3,
        justify = app.justifyLeft,
        text = "+ "..self.sample:getDurationText()
      }
      sub[4] = {
        position = app.GRID5_LINE4,
        justify = app.justifyLeft,
        text = string.format("+ %s %s %s",self.sample:getChannelText(), self.sample:getSampleRateText(), self.sample:getMemorySizeText())
      }
    else
      sub[1] = {
        position = app.GRID5_LINE3,
        justify = app.justifyCenter,
        text = "No sample attached."
      }
    end
    return controls, menu, sub
  end

function Xoxoxo:serialize()
local t = Unit.serialize(self)
local sample = self.sample
if sample then
    t.sample = SamplePool.serializeSample(sample)
end
return t
end

function Xoxoxo:deserialize(t)
Unit.deserialize(self,t)
if t.sample then
    local sample = SamplePool.deserializeSample(t.sample)
    if sample then
        self:setSample(sample)
    else
        local Utils = require "Utils"
        app.log("%s:deserialize: failed to load sample.",self)
        Utils.pp(t.sample)
    end
else
    local libraryName = self.loadInfo.libraryName
    local sampleFilename = Path.join("1:/ER-301/libs",libraryName,"assets/xoxo.wav")
    local sample = SamplePool.load(sampleFilename)

    if not sample then
      local Overlay = require "Overlay"
      Overlay.mainFlashMessage("Could not load %s.",sampleFilename)
    else
        self:setSample(sample)
    end
end
end

function Xoxoxo:onRemove()
self:setSample(nil)
Unit.onRemove(self)
end

return Xoxoxo
