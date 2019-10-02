-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local RotarySim = Class{}
RotarySim:include(Unit)

function RotarySim:init(args)
  args.title = "Rotary Speaker Sim"
  args.mnemonic = "RS"
  Unit.init(self,args)
end


function RotarySim:onLoadGraph()

    local half = self:createObject("ConstantOffset","half")
    half:hardSet("Offset",0.5)
    local one = self:createObject("ConstantOffset","one")
    one:hardSet("Offset",1.0)
    local smallGain = self:createObject("ConstantOffset","smallGain")
    smallGain:hardSet("Offset",0.001)

    local equalizerHi = self:createObject("Equalizer3","equalizerHi")
    connect(one,"Out",equalizerHi,"High Gain")
    connect(half,"Out",equalizerHi,"Mid Gain")
    connect(self,"In1",equalizerHi,"In")

    local equalizerLo = self:createObject("Equalizer3","equalizerLo")
    connect(one,"Out",equalizerLo,"Low Gain")
    connect(half,"Out",equalizerLo,"Mid Gain")
    connect(self,"In2",equalizerLo,"In")

    tie(equalizerLo,"Low Freq",equalizerHi,"Low Freq")
    tie(equalizerLo,"High Freq",equalizerHi,"High Freq")

    self.objects.equalizer = self.objects.equalizerHi

    local panHi = self:createObject("MonoPanner","panHi")
    local panLo = self:createObject("MonoPanner","panLo")
    local dHi = self:createObject("DopplerDelay","dHi",0.1)
    local dLo = self:createObject("DopplerDelay","dLo",0.1)

    local modHiPan = self:createObject("SineOscillator","modHiPan")
    local modLoPan = self:createObject("SineOscillator","modLoPan")
    local modHiDly = self:createObject("SineOscillator","modHiDly")
    local modLoDly = self:createObject("SineOscillator","modLoDly")

    local lMix = self:createObject("Sum","lMix")
    local rMix = self:createObject("Sum","rMix")

    connect(equalizerHi,"Out",dHi,"In")
    connect(dHi,"Out",panHi,"In")
    connect(equalizerLo,"Out",dLo,"In")
    connect(dLo,"Out",panLo,"In")

    local modHiLvl = self:createObject("GainBias","modHiLvl")
    local modHiLvlRange = self:createObject("MinMax","modHiLvlRange")
    local modLoLvl = self:createObject("GainBias","modLoLvl")
    local modLoLvlRange = self:createObject("MinMax","modLoLvlRange")

    local modLoDlyVCA = self:createObject("Multiply","modLoDlyVCA")
    local modHiDlyVCA = self:createObject("Multiply","modHiDlyVCA")
    local dHiVCA = self:createObject("Multiply","dHiVCA")
    local dLoVCA = self:createObject("Multiply","dLoVCA")
    local dHiMix = self:createObject("Sum","dHiMix")
    local dLoMix = self:createObject("Sum","dLoMix")
    

    connect(modHiLvl,"Out",modHiLvlRange,"In")
    connect(modLoLvl,"Out",modLoLvlRange,"In")

    connect(modHiLvl,"Out",modHiPan,"Fundamental")
    connect(modLoLvl,"Out",modLoPan,"Fundamental")

    connect(modHiPan,"Out",panHi,"Pan")
    connect(modLoPan,"Out",panLo,"Pan")

    connect(modHiDly,"Out",dHiVCA,"Left")
    connect(modLoDly,"Out",dLoVCA,"Left")
    connect(smallGain,"Out",dHiVCA,"Right")
    connect(smallGain,"Out",dLoVCA,"Right")
    connect(dHiVCA,"Out",dHiMix,"Left")
    connect(dLoVCA,"Out",dLoMix,"Left")
    connect(smallGain,"Out",dHiMix,"Right")
    connect(smallGain,"Out",dLoMix,"Right")
    connect(dHiMix,"Out",dHi,"Delay")
    connect(dLoMix,"Out",dLo,"Delay")

    local modHiFreqVCA = self:createObject("Multiply","modHiFreqVCA")
    local modLoFreqVCA = self:createObject("Multiply","modLoFreqVCA")

    connect(modHiLvl,"Out",modHiFreqVCA,"Left")
    connect(modLoLvl,"Out",modLoFreqVCA,"Left")
    connect(half,"Out",modHiFreqVCA,"Right")
    connect(half,"Out",modLoFreqVCA,"Right")
    connect(modHiFreqVCA,"Out",modHiDly,"Fundamental")
    connect(modLoFreqVCA,"Out",modLoDly,"Fundamental")

    self:createMonoBranch("modHiLvl",modHiLvl,"In",modHiLvl,"Out")
    self:createMonoBranch("modLoLvl",modLoLvl,"In",modLoLvl,"Out")

    connect(panHi,"Left",lMix,"Left")
    connect(panLo,"Left",lMix,"Right")
    connect(panHi,"Right",rMix,"Left")
    connect(panLo,"Right",rMix,"Right")

    connect(lMix,"Out",self,"Out1")
    connect(rMix,"Out",self,"Out2")

end

local views = {
  expanded = {"modLoLvl","modHiLvl","lowFreq","highFreq"},
  collapsed = {},
}

local function linMap(min,max,superCoarse,coarse,fine,superFine)
    local map = app.LinearDialMap(min,max)
    map:setSteps(superCoarse,coarse,fine,superFine)
    return map
end

local freqMap = linMap(0.1,10,2,1,0.1,0.01)

function RotarySim:onLoadViews(objects,branches)
    local controls = {}

    controls.lowFreq = Fader {
    button = "lo xover",
    description = "Low Crossover",
    param = objects.equalizer:getParameter("Low Freq"),
    monitor = self,
    map = Encoder.getMap("filterFreq"),
    units = app.unitHertz,
    scaling = app.octaveScaling
    }

    controls.highFreq = Fader {
    button = "hi xover",
    description = "High Crossover",
    param = objects.equalizer:getParameter("High Freq"),
    monitor = self,
    map = Encoder.getMap("filterFreq"),
    units = app.unitHertz,
    scaling = app.octaveScaling
    }

    controls.modHiLvl = GainBias {
    button = "hi freq",
    description = "Hi rotation freq",
    branch = branches.modHiLvl,
    gainbias = objects.modHiLvl,
    range = objects.modHiLvlRange,
    biasMap = freqMap,
    biasUnits = app.unitHertz,
    initialBias = 4,
    }

    controls.modLoLvl = GainBias {
    button = "lo freq",
    description = "Lo rotation freq",
    branch = branches.modLoLvl,
    gainbias = objects.modLoLvl,
    range = objects.modLoLvlRange,
    biasMap = freqMap,
    biasUnits = app.unitHertz,
    initialBias = 0.5,
    }

  return controls, views
end

return RotarySim
