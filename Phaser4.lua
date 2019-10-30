-- luacheck: globals app os verboseLevel connect tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local ModeSelect = require "Unit.MenuControl.OptionControl"
local SamplePool = require "Sample.Pool"
local SamplePoolInterface = require "Sample.Pool.Interface"
local SampleEditor = require "Sample.Editor"
local Slices = require "Sample.Slices"
local Path = require "Path"
local Encoder = require "Encoder"
local Utils = require "Utils"
local ply = app.SECTION_PLY

local Phaser4 = Class{}
Phaser4:include(Unit)

function Phaser4:init(args)
  args.title = "Phaser"
  args.mnemonic = "Ph"
  Unit.init(self,args)
end

function Phaser4:onLoadGraph(channelCount)
    if channelCount==2 then
      self:loadStereoGraph()
    else
      self:loadMonoGraph()
    end
  end

function Phaser4:loadStereoGraph()
    self:loadMonoGraph()
    local localDSP = {}
    local dryVCAR = self:createObject("Multiply","dryVCAR")
    local wetVCAR = self:createObject("Multiply","wetVCAR")
    local outSumR = self:createObject("Sum","outSumR")

    local modPhase = self:createObject("Delay","modPhase",1)
    modPhase:allocateTimeUpTo(0.25)
    modPhase:hardSet("Left Delay", 0.25)

    for i = 1,4 do 
        localDSP["feedBackMixR" .. i] = self:createObject("Sum","feedBackMixR" .. i)
        localDSP["feedBackGainR" .. i] = self:createObject("ConstantGain","feedBackGainR" .. i)
        localDSP["feedForwardMixR" .. i] = self:createObject("Sum","feedForwardMixR" .. i)
        localDSP["feedForwardGainR" .. i] = self:createObject("ConstantGain","feedForwardGainR" .. i)
        localDSP["limiterR" .. i] = self:createObject("Limiter","limiterR" .. i)
        localDSP["modGainBiasR" .. i] = self:createObject("ParameterAdapter","modGainBiasR" ..i)
        localDSP["modGainBiasR" .. i]:hardSet("Bias", (i*.001) + .001)
        localDSP["modGainBiasR" .. i]:hardSet("Gain", .002)

        connect(localDSP["feedBackMixR" .. i],"Out",self.objects["delay" ..i],"Right In")
        connect(self.objects["delay" ..i],"Right Out",localDSP["feedForwardMixR" .. i],"Left")
        connect(localDSP["feedBackMixR" .. i],"Out",localDSP["feedForwardMixR" .. i],"Right")
        connect(localDSP["feedForwardGainR" .. i],"Out",localDSP["feedForwardMixR" .. i],"Right")
        connect(self.objects["delay" ..i],"Right Out",localDSP["feedBackGainR" .. i],"In")
        connect(localDSP["feedBackGainR" .. i],"Out",localDSP["limiterR" .. i],"In")
        connect(localDSP["limiterR" .. i],"Out",localDSP["feedBackMixR" .. i],"Right")
        connect(modPhase,"Left Out",localDSP["modGainBiasR" .. i],"In")
        
        tie(localDSP["feedBackGainR" .. i],"Gain",self.objects.gainAdapter,"Out")
        tie(localDSP["feedForwardGainR" .. i],"Gain","negate",self.objects.gainAdapter,"Out")
        tie(self.objects["delay" ..i],"Right Delay",localDSP["modGainBiasR" .. i],"Out")
    end

    connect(self.objects.modVca,"Out", modPhase,"Left In")
    connect(self,"In2",dryVCAR,"Left")
    connect(self.objects.dryLevelSum,"Out",dryVCAR,"Right")
    connect(self.objects.wetLevel,"Out",wetVCAR,"Left")
    connect(wetVCAR,"Out",outSumR,"Left")
    connect(dryVCAR,"Out",outSumR,"Right")

    connect(self,"In2",localDSP["feedBackMixR1"],"Left")
    connect(localDSP["feedForwardMixR1"],"Out",localDSP["feedBackMixR2"],"Left")
    connect(localDSP["feedForwardMixR2"],"Out",localDSP["feedBackMixR3"],"Left")
    connect(localDSP["feedForwardMixR3"],"Out",localDSP["feedBackMixR4"],"Left")
    connect(localDSP["feedForwardMixR4"],"Out",wetVCAR,"Right")
    connect(outSumR,"Out",self,"Out2")
  end

function Phaser4:loadMonoGraph()

    local localDSP = {}
    local delayAdapter = self:createObject("ParameterAdapter","delayAdapter")
    local gainAdapter = self:createObject("ParameterAdapter","gainAdapter")
    gainAdapter:hardSet("Gain",0.3)
    local mod = self:createObject("SingleCycle","mod")
    local f0Range = self:createObject("MinMax","f0Range")
    local f0 = self:createObject("GainBias","f0")

    local libraryName = self.loadInfo.libraryName
    local sampleFilename = Path.join("1:/ER-301/libs",libraryName,"assets/xoxo.wav")
    local sample = SamplePool.load(sampleFilename)

    if not sample then
      local Overlay = require "Overlay"
      Overlay.mainFlashMessage("Could not load %s.",sampleFilename)
    else
      mod:setSample(sample.pSample,sample.slices.pSlices)
    end


    local wetLevel = self:createObject("GainBias","wetLevel")
    local wetLevelRange = self:createObject("MinMax","wetLevelRange")
    local one = self:createObject("Constant","one")
    local negOne = self:createObject("Constant","negOne")
    one:hardSet("Value", 1.0)
    negOne:hardSet("Value", -1.0)
    local invertingVCA = self:createObject("Multiply","invertingVCA")
    local dryVCA = self:createObject("Multiply","dryVCA")
    local wetVCA = self:createObject("Multiply","wetVCA")
    local dryLevelSum = self:createObject("Sum","dryLevelSum")
    local outSum = self:createObject("Sum","outSum")

    local scan = self:createObject("GainBias","scan")
    local scanRange = self:createObject("MinMax","scanRange")
    local modVca = self:createObject("Multiply","modVca")
    local modLevel = self:createObject("GainBias","modLevel")
    local modLevelRange = self:createObject("MinMax","modLevelRange")

    connect(f0,"Out",mod,"Fundamental")
    connect(f0,"Out",f0Range,"In")
    connect(scan,"Out",mod,"Scan")
    connect(scan,"Out",scanRange,"In")
    connect(modLevel,"Out",modVca,"Left")
    connect(mod,"Out",modVca,"Right")
    connect(modLevel,"Out",modLevelRange,"In")

    for i = 1,4 do 
        localDSP["delay" .. i] = self:createObject("Delay","delay" .. i,2)
        localDSP["delay" .. i]:allocateTimeUpTo(0.05)
        localDSP["feedBackMix" .. i] = self:createObject("Sum","feedBackMix" .. i)
        localDSP["feedBackGain" .. i] = self:createObject("ConstantGain","feedBackGain" .. i)
        localDSP["feedForwardMix" .. i] = self:createObject("Sum","feedForwardMix" .. i)
        localDSP["feedForwardGain" .. i] = self:createObject("ConstantGain","feedForwardGain" .. i)
        localDSP["limiter" .. i] = self:createObject("Limiter","limiter" .. i)
        localDSP["modGainBias" .. i] = self:createObject("ParameterAdapter","modGainBias" ..i)  
        localDSP["modGainBias" .. i]:hardSet("Bias", (i*.001) + .001)
        localDSP["modGainBias" .. i]:hardSet("Gain", .002)

        connect(localDSP["feedBackMix" .. i],"Out",localDSP["delay" .. i],"Left In")
        connect(localDSP["delay" .. i],"Left Out",localDSP["feedForwardMix" .. i],"Left")
        connect(localDSP["feedBackMix" .. i],"Out",localDSP["feedForwardMix" .. i],"Right")
        connect(localDSP["feedForwardGain" .. i],"Out",localDSP["feedForwardMix" .. i],"Right")
        connect(localDSP["delay" .. i],"Left Out",localDSP["feedBackGain" .. i],"In")
        connect(localDSP["feedBackGain" .. i],"Out",localDSP["limiter" .. i],"In")
        connect(localDSP["limiter" .. i],"Out",localDSP["feedBackMix" .. i],"Right")
        connect(modVca,"Out",localDSP["modGainBias" .. i],"In")

        tie(localDSP["feedBackGain" .. i],"Gain",gainAdapter,"Out")
        tie(localDSP["feedForwardGain" .. i],"Gain","negate",gainAdapter,"Out")
        tie(localDSP["delay" .. i],"Left Delay",localDSP["modGainBias" .. i],"Out")
    end

    connect(self,"In1",dryVCA,"Left")
    connect(wetLevel,"Out",invertingVCA,"Left")
    connect(negOne,"Out",invertingVCA,"Right")
    connect(one,"Out",dryLevelSum,"Left")
    connect(invertingVCA,"Out",dryLevelSum,"Right")
    connect(dryLevelSum,"Out",dryVCA,"Right")
    connect(dryVCA,"Out",outSum,"Right")
    connect(wetLevel,"Out",wetVCA,"Left")
    connect(wetVCA,"Out",outSum,"Left")
    connect(wetLevel,"Out",wetLevelRange,"In")

    connect(self,"In1",localDSP["feedBackMix1"],"Left")
    connect(localDSP["feedForwardMix1"],"Out",localDSP["feedBackMix2"],"Left")
    connect(localDSP["feedForwardMix2"],"Out",localDSP["feedBackMix3"],"Left")
    connect(localDSP["feedForwardMix3"],"Out",localDSP["feedBackMix4"],"Left")
    connect(localDSP["feedForwardMix4"],"Out",wetVCA,"Right")
    connect(outSum,"Out",self,"Out1")

    self:createMonoBranch("gain",gainAdapter,"In",gainAdapter,"Out")
    self:createMonoBranch("f0",f0,"In",f0,"Out")
    self:createMonoBranch("wet",wetLevel,"In",wetLevel,"Out")
    self:createMonoBranch("scan",scan,"In",scan,"Out")
    self:createMonoBranch("modLevel",modLevel,"In",modLevel,"Out")
end

local views = {
  expanded = {"gain","freq","scan","modLevel","wet"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
    local map = app.LinearDialMap(min,max)
    map:setSteps(superCoarse,coarse,fine,superFine)
    return map
  end

local freqMap = linMap(0,10,1,0.5,0.1,0.01)
local depthMap = linMap(0,0.5,0.2,0.1,0.01,0.001)
local wetMap = linMap(0,1,1,0.1,0.01,0.001)
local modLvlMap = linMap(0,1,0.5,0.1,0.01,0.001)
local scanMap = linMap(0.0,1.0,1.0,0.333,0.01,0.001)

function Phaser4:onLoadViews(objects,branches)
  local controls = {}

    controls.gain = GainBias {
        button = "depth",
        description = "Depth",
        branch = branches.gain,
        gainbias = objects.gainAdapter,
        range = objects.gainAdapter,
        biasMap = depthMap,
        biasUnits = app.unitNone,
        initialBias = 0.25
    }

    controls.freq = GainBias {
        button = "rate",
        description = "Modulation Rate",
        branch = branches.f0,
        gainbias = objects.f0,
        range = objects.f0Range,
        biasMap = freqMap,
        biasUnits = app.unitHertz,
        initialBias = 0.3
    }

    controls.scan = GainBias {
      button = "scan",
      description = "Modulation Waveform",
      branch = branches.scan,
      gainbias = objects.scan,
      range = objects.scanRange,
      biasMap = scanMap,
      biasUnits = app.unitNone,
      initialBias = 0.0
  }

    controls.modLevel = GainBias {
      button = "level",
      description = "Modulation Amount",
      branch = branches.modLevel,
      gainbias = objects.modLevel,
      range = objects.modLevelRange,
      biasMap = modLvlMap,
      biasUnits = app.unitNone,
      initialBias = 0.5
  }

    controls.wet = GainBias {
        button = "wet",
        description = "Wet/Dry Mix",
        branch = branches.wet,
        gainbias = objects.wetLevel,
        range = objects.wetLevelRange,
        biasMap = wetMap,
        biasUnits = app.unitNone,
        initialBias = 0.5
    }
    return controls, views
end

function Phaser4:onRemove()
  self.objects.delay1:deallocate()
  self.objects.delay2:deallocate()
  self.objects.delay3:deallocate()
  self.objects.delay4:deallocate()
  Unit.onRemove(self)
end

return Phaser4
