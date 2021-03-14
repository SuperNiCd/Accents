local app = app
local libcore = require "core.libcore"
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
local Accents = require "Accents"
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
    local dryVCAR = self:addObject("dryVCAR",app.Multiply())
    local wetVCAR = self:addObject("wetVCAR",app.Multiply())
    local outSumR = self:addObject("outSumR",app.Sum())

    local modPhase = self:addObject("modPhase",libcore.Delay(1))
    modPhase:allocateTimeUpTo(0.25)
    modPhase:hardSet("Left Delay", 0.25)

    for i = 1,4 do 
        localDSP["feedBackMixR" .. i] = self:addObject("feedBackMixR" .. i,app.Sum())
        localDSP["feedBackGainR" .. i] = self:addObject("feedBackGainR" .. i,app.ConstantGain())
        localDSP["feedForwardMixR" .. i] = self:addObject("feedForwardMixR" .. i,app.Sum())
        localDSP["feedForwardGainR" .. i] = self:addObject("feedForwardGainR" .. i,app.ConstantGain())
        localDSP["limiterR" .. i] = self:addObject("limiterR" .. i,libcore.Limiter())
        localDSP["modGainBiasR" .. i] = self:addObject("modGainBiasR" ..i,app.ParameterAdapter())
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
    local delayAdapter = self:addObject("delayAdapter",app.ParameterAdapter())
    local gainAdapter = self:addObject("gainAdapter",app.ParameterAdapter())
    gainAdapter:hardSet("Gain",0.3)
    local mod = self:addObject("mod",libcore.SingleCycle())
    local f0Range = self:addObject("f0Range",app.MinMax())
    local f0 = self:addObject("f0",app.GainBias())

    local libraryName = self.loadInfo.libraryName
    local sampleFilename = Path.join(Accents:getInstallationPath(),"xoxo.wav")
    local sample = SamplePool.load(sampleFilename)

    if not sample then
      local Overlay = require "Overlay"
      Overlay.mainFlashMessage("Could not load %s.",sampleFilename)
    else
      mod:setSample(sample.pSample,sample.slices.pSlices)
    end


    local wetLevel = self:addObject("wetLevel",app.GainBias())
    local wetLevelRange = self:addObject("wetLevelRange",app.MinMax())
    local one = self:addObject("one",app.Constant())
    local negOne = self:addObject("negOne",app.Constant())
    one:hardSet("Value", 1.0)
    negOne:hardSet("Value", -1.0)
    local invertingVCA = self:addObject("invertingVCA",app.Multiply())
    local dryVCA = self:addObject("dryVCA",app.Multiply())
    local wetVCA = self:addObject("wetVCA",app.Multiply())
    local dryLevelSum = self:addObject("dryLevelSum",app.Sum())
    local outSum = self:addObject("outSum",app.Sum())

    local scan = self:addObject("scan",app.GainBias())
    local scanRange = self:addObject("scanRange",app.MinMax())
    local modVca = self:addObject("modVca",app.Multiply())
    local modLevel = self:addObject("modLevel",app.GainBias())
    local modLevelRange = self:addObject("modLevelRange",app.MinMax())

    connect(f0,"Out",mod,"Fundamental")
    connect(f0,"Out",f0Range,"In")
    connect(scan,"Out",mod,"Scan")
    connect(scan,"Out",scanRange,"In")
    connect(modLevel,"Out",modVca,"Left")
    connect(mod,"Out",modVca,"Right")
    connect(modLevel,"Out",modLevelRange,"In")

    for i = 1,4 do 
        localDSP["delay" .. i] = self:addObject("delay" .. i,libcore.Delay(2))
        localDSP["delay" .. i]:allocateTimeUpTo(0.05)
        localDSP["feedBackMix" .. i] = self:addObject("feedBackMix" .. i,app.Sum())
        localDSP["feedBackGain" .. i] = self:addObject("feedBackGain" .. i,app.ConstantGain())
        localDSP["feedForwardMix" .. i] = self:addObject("feedForwardMix" .. i,app.Sum())
        localDSP["feedForwardGain" .. i] = self:addObject("feedForwardGain" .. i,app.ConstantGain())
        localDSP["limiter" .. i] = self:addObject("limiter" .. i,libcore.Limiter())
        localDSP["modGainBias" .. i] = self:addObject("modGainBias" ..i,app.ParameterAdapter()) 
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

    self:addMonoBranch("gain",gainAdapter,"In",gainAdapter,"Out")
    self:addMonoBranch("f0",f0,"In",f0,"Out")
    self:addMonoBranch("wet",wetLevel,"In",wetLevel,"Out")
    self:addMonoBranch("scan",scan,"In",scan,"Out")
    self:addMonoBranch("modLevel",modLevel,"In",modLevel,"Out")
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
