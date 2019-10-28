-- luacheck: globals app os verboseLevel connect tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
local ModeSelect = require "Unit.MenuControl.OptionControl"
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

    local localDSP = {}
    local delayAdapter = self:createObject("ParameterAdapter","delayAdapter")
    local gainAdapter = self:createObject("ParameterAdapter","gainAdapter")
    local mod = self:createObject("SineOscillator","mod")
    local f0Range = self:createObject("MinMax","f0Range")
    local f0 = self:createObject("GainBias","f0")
    local modPhase = self:createObject("Delay","modPhase",1)
    modPhase:allocateTimeUpTo(0.25)
    modPhase:hardSet("Left Delay", 0.25)

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
    local loopFBMix = self:createObject("Sum","loopFBMix")
    local loopFBVCA = self:createObject("Multiply","loopFBVCA")
    local loopFBLimiter = self:createObject("Limiter","looopFBLimiter")
    local loopFBLevel = self:createObject("GainBias","loopFBLevel")
    local loopFBLevelRange = self:createObject("MinMax","loopFBLevelRange")


    local dryVCAR = self:createObject("Multiply","dryVCAR")
    local wetVCAR = self:createObject("Multiply","wetVCAR")
    local outSumR = self:createObject("Sum","outSumR")
    local loopFBMixR = self:createObject("Sum","loopFBMixR")
    local loopFBVCAR = self:createObject("Multiply","loopFBVCAR")
    local loopFBLimiterR = self:createObject("Limiter","looopFBLimiterR")

    connect(f0,"Out",mod,"Fundamental")
    connect(f0,"Out",f0Range,"In")
    connect(loopFBLevel,"Out",loopFBLevelRange,"In")

    for i = 1,4 do 
        localDSP["delay" .. i] = self:createObject("Delay","delay" .. i,2)
        localDSP["delay" .. i]:allocateTimeUpTo(0.05)
        localDSP["feedBackMix" .. i] = self:createObject("Sum","feedBackMix" .. i)
        localDSP["feedBackGain" .. i] = self:createObject("ConstantGain","feedBackGain" .. i)
        localDSP["feedForwardMix" .. i] = self:createObject("Sum","feedForwardMix" .. i)
        localDSP["feedForwardGain" .. i] = self:createObject("ConstantGain","feedForwardGain" .. i)
        localDSP["limiter" .. i] = self:createObject("Limiter","limiter" .. i)
        localDSP["feedBackMixR" .. i] = self:createObject("Sum","feedBackMixR" .. i)
        localDSP["feedBackGainR" .. i] = self:createObject("ConstantGain","feedBackGainR" .. i)
        localDSP["feedForwardMixR" .. i] = self:createObject("Sum","feedForwardMixR" .. i)
        localDSP["feedForwardGainR" .. i] = self:createObject("ConstantGain","feedForwardGainR" .. i)
        localDSP["limiterR" .. i] = self:createObject("Limiter","limiterR" .. i)
        localDSP["modGainBias" .. i] = self:createObject("ParameterAdapter","modGainBias" ..i)
        localDSP["modGainBiasR" .. i] = self:createObject("ParameterAdapter","modGainBiasR" ..i)
        localDSP["modGainBias" .. i]:hardSet("Bias", (i*.001) + .001)
        localDSP["modGainBiasR" .. i]:hardSet("Bias", (i*.001) + .001)
        localDSP["modGainBias" .. i]:hardSet("Gain", .002)
        localDSP["modGainBiasR" .. i]:hardSet("Gain", .002)

        connect(localDSP["feedBackMix" .. i],"Out",localDSP["delay" .. i],"Left In")
        connect(localDSP["feedBackMixR" .. i],"Out",localDSP["delay" .. i],"Right In")
        connect(localDSP["delay" .. i],"Left Out",localDSP["feedForwardMix" .. i],"Left")
        connect(localDSP["delay" .. i],"Right Out",localDSP["feedForwardMixR" .. i],"Left")
        connect(localDSP["feedBackMix" .. i],"Out",localDSP["feedForwardMix" .. i],"Right")
        connect(localDSP["feedBackMixR" .. i],"Out",localDSP["feedForwardMixR" .. i],"Right")
        connect(localDSP["feedForwardGain" .. i],"Out",localDSP["feedForwardMix" .. i],"Right")
        connect(localDSP["feedForwardGainR" .. i],"Out",localDSP["feedForwardMixR" .. i],"Right")
        connect(localDSP["delay" .. i],"Left Out",localDSP["feedBackGain" .. i],"In")
        connect(localDSP["delay" .. i],"Right Out",localDSP["feedBackGainR" .. i],"In")
        connect(localDSP["feedBackGain" .. i],"Out",localDSP["limiter" .. i],"In")
        connect(localDSP["feedBackGainR" .. i],"Out",localDSP["limiterR" .. i],"In")
        connect(localDSP["limiter" .. i],"Out",localDSP["feedBackMix" .. i],"Right")
        connect(localDSP["limiterR" .. i],"Out",localDSP["feedBackMixR" .. i],"Right")

        connect(mod,"Out",localDSP["modGainBias" .. i],"In")
        connect(mod,"Out", modPhase,"Left In")
        connect(modPhase,"Left Out",localDSP["modGainBiasR" .. i],"In")

        tie(localDSP["feedBackGain" .. i],"Gain",gainAdapter,"Out")
        tie(localDSP["feedBackGainR" .. i],"Gain",gainAdapter,"Out")
        tie(localDSP["feedForwardGain" .. i],"Gain","negate",gainAdapter,"Out")
        tie(localDSP["feedForwardGainR" .. i],"Gain","negate",gainAdapter,"Out")
        tie(localDSP["delay" .. i],"Left Delay",localDSP["modGainBias" .. i],"Out")
        tie(localDSP["delay" .. i],"Right Delay",localDSP["modGainBiasR" .. i],"Out")
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

    connect(self,"In1",loopFBMix,"Left")
    connect(loopFBMix,"Out",localDSP["feedBackMix1"],"Left")
    connect(localDSP["feedForwardMix1"],"Out",localDSP["feedBackMix2"],"Left")
    connect(localDSP["feedForwardMix2"],"Out",localDSP["feedBackMix3"],"Left")
    connect(localDSP["feedForwardMix3"],"Out",localDSP["feedBackMix4"],"Left")
    connect(localDSP["feedForwardMix4"],"Out",wetVCA,"Right")
    connect(localDSP["feedForwardMix4"],"Out",loopFBVCA,"Left")
    connect(loopFBLevel,"Out",loopFBVCA,"Right")
    connect(loopFBVCA,"Out",loopFBLimiter,"In")
    connect(loopFBLimiter,"Out",loopFBMix,"Right")
    connect(outSum,"Out",self,"Out1")

    if channelCount==2 then
        connect(self,"In2",dryVCAR,"Left")
        connect(dryLevelSum,"Out",dryVCAR,"Right")
        connect(wetLevel,"Out",wetVCAR,"Left")
        connect(wetVCAR,"Out",outSumR,"Left")
        connect(dryVCAR,"Out",outSumR,"Right")

        connect(self,"In1",loopFBMixR,"Left")
        connect(loopFBMixR,"Out",localDSP["feedBackMixR1"],"Left")
        connect(localDSP["feedForwardMixR1"],"Out",localDSP["feedBackMixR2"],"Left")
        connect(localDSP["feedForwardMixR2"],"Out",localDSP["feedBackMixR3"],"Left")
        connect(localDSP["feedForwardMixR3"],"Out",localDSP["feedBackMixR4"],"Left")
        connect(localDSP["feedForwardMixR4"],"Out",wetVCAR,"Right")
        connect(localDSP["feedForwardMix4"],"Out",loopFBVCAR,"Left")
        connect(loopFBLevel,"Out",loopFBVCAR,"Right")
        connect(loopFBVCAR,"Out",loopFBLimiterR,"In")
        connect(loopFBLimiterR,"Out",loopFBMixR,"Right")
        connect(outSumR,"Out",self,"Out2")
    end

    self:createMonoBranch("gain",gainAdapter,"In",gainAdapter,"Out")
    self:createMonoBranch("f0",f0,"In",f0,"Out")
    self:createMonoBranch("wet",wetLevel,"In",wetLevel,"Out")
    self:createMonoBranch("loopFB",loopFBLevel,"In",loopFBLevel,"Out")
end

local views = {
  expanded = {"gain","freq","wet","loopFB"},
  collapsed = {},
}

local function linMap(min,max,n)
  local map = app.LinearDialMap(min,max)
  map:setCoarseRadix(n)
  return map
end

local delayMap = linMap(0,0.05,100)

function Phaser4:onLoadViews(objects,branches)
  local controls = {}

    controls.gain = GainBias {
        button = "gain",
        description = "Loop Gain",
        branch = branches.gain,
        gainbias = objects.gainAdapter,
        range = objects.gainAdapter,
        biasMap = nil,
        biasUnits = app.unitNone,
        initialBias = 0.18
    }

    controls.freq = GainBias {
        button = "f0",
        description = "Fundamental",
        branch = branches.f0,
        gainbias = objects.f0,
        range = objects.f0Range,
        biasMap = Encoder.getMap("oscFreq"),
        biasUnits = app.unitHertz,
        initialBias = 1.0,
        gainMap = Encoder.getMap("freqGain"),
        scaling = app.octaveScaling
    }

    controls.wet = GainBias {
        button = "wet",
        description = "Wet/Dry Mix",
        branch = branches.wet,
        gainbias = objects.wetLevel,
        range = objects.wetLevelRange,
        biasMap = nil,
        biasUnits = app.unitNone,
        initialBias = 0.5
    }

    controls.loopFB = GainBias {
        button = "feedback",
        description = "Feedback",
        branch = branches.loopFB,
        gainbias = objects.loopFBLevel,
        range = objects.loopFBLevelRange,
        biasMap = nil,
        biasUnits = app.unitNone,
        initialBias = 0.0
    }

    return controls, views
end

function Phaser4:onRemove()
  self.objects.delay1:deallocate()
  Unit.onRemove(self)
end

return Phaser4
