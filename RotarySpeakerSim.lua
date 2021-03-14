local app = app
local libcore = require "core.libcore"
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

    local half = self:addObject("half",app.ConstantOffset())
    half:hardSet("Offset",0.5)
    local one = self:addObject("one",app.ConstantOffset())
    one:hardSet("Offset",1.0)
    local smallGain = self:addObject("smallGain",app.ConstantOffset())
    smallGain:hardSet("Offset",0.001)

    local equalizerHi = self:addObject("equalizerHi",libcore.Equalizer3())
    connect(one,"Out",equalizerHi,"High Gain")
    connect(half,"Out",equalizerHi,"Mid Gain")
    connect(self,"In1",equalizerHi,"In")

    local equalizerLo = self:addObject("equalizerLo",libcore.Equalizer3())
    connect(one,"Out",equalizerLo,"Low Gain")
    connect(half,"Out",equalizerLo,"Mid Gain")
    connect(self,"In2",equalizerLo,"In")

    tie(equalizerLo,"Low Freq",equalizerHi,"Low Freq")
    tie(equalizerLo,"High Freq",equalizerHi,"High Freq")

    self.objects.equalizer = self.objects.equalizerHi

    local panHi = self:addObject("panHi",app.MonoPanner())
    local panLo = self:addObject("panLo",app.MonoPanner())
    local dHi = self:addObject("dHi",libcore.DopplerDelay(0.1))
    local dLo = self:addObject("dLo",libcore.DopplerDelay(0.1))

    local modHiPan = self:addObject("modHiPan",libcore.SineOscillator())
    local modLoPan = self:addObject("modLoPan",libcore.SineOscillator())
    local modHiDly = self:addObject("modHiDly",libcore.SineOscillator())
    local modLoDly = self:addObject("modLoDly",libcore.SineOscillator())

    local lMix = self:addObject("lMix",app.Sum())
    local rMix = self:addObject("rMix",app.Sum())

    connect(equalizerHi,"Out",dHi,"In")
    connect(dHi,"Out",panHi,"In")
    connect(equalizerLo,"Out",dLo,"In")
    connect(dLo,"Out",panLo,"In")

    local modHiLvl = self:addObject("modHiLvl",app.GainBias())
    local modHiLvlRange = self:addObject("modHiLvlRange",app.MinMax())
    local modLoLvl = self:addObject("modLoLvl",app.GainBias())
    local modLoLvlRange = self:addObject("modLoLvlRange",app.MinMax())

    local modLoDlyVCA = self:addObject("modLoDlyVCA",app.Multiply())
    local modHiDlyVCA = self:addObject("modHiDlyVCA",app.Multiply())
    local dHiVCA = self:addObject("dHiVCA",app.Multiply())
    local dLoVCA = self:addObject("dLoVCA",app.Multiply())
    local dHiMix = self:addObject("dHiMix",app.Sum())
    local dLoMix = self:addObject("dLoMix",app.Sum())
    

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

    local modHiFreqVCA = self:addObject("modHiFreqVCA",app.Multiply())
    local modLoFreqVCA = self:addObject("modLoFreqVCA",app.Multiply())

    connect(modHiLvl,"Out",modHiFreqVCA,"Left")
    connect(modLoLvl,"Out",modLoFreqVCA,"Left")
    connect(half,"Out",modHiFreqVCA,"Right")
    connect(half,"Out",modLoFreqVCA,"Right")
    connect(modHiFreqVCA,"Out",modHiDly,"Fundamental")
    connect(modLoFreqVCA,"Out",modLoDly,"Fundamental")

    self:addMonoBranch("modHiLvl",modHiLvl,"In",modHiLvl,"Out")
    self:addMonoBranch("modLoLvl",modLoLvl,"In",modLoLvl,"Out")

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
