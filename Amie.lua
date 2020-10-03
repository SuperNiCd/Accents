-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local Pitch = require "Unit.ViewControl.Pitch"
local GainBias = require "Unit.ViewControl.GainBias"
local Fader = require "Unit.ViewControl.Fader"
local Gate = require "Unit.ViewControl.Gate"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Amie = Class{}
Amie:include(Unit)

function Amie:init(args)
  args.title = "Amie"
  args.mnemonic = "AM"
  Unit.init(self,args)
end

function Amie:onLoadGraph(channelCount)

    --carrier
    local carrier = self:createObject("SineOscillator","carrier")
    local ctune = self:createObject("ConstantOffset","ctune")
    local ctuneRange = self:createObject("MinMax","ctuneRange")
    local cf0 = self:createObject("GainBias","cf0")
    local cf0Range = self:createObject("MinMax","cf0Range")
    local climgain = self:createObject("ConstantGain","climgain")
    local climiter = self:createObject("Limiter","climiter")
    local cfdbk = self:createObject("GainBias","cfdbk")
    local cfdbkRange = self:createObject("MinMax","cfdbkRange")
    connect(cfdbk,"Out",cfdbkRange,"In")

    -- modulator
    local modulator = self:createObject("SineOscillator","modulator")
    local mRatio = self:createObject("GainBias","mRatio")
    local mRatioRange = self:createObject("MinMax","mRatioRange")
    local mRatioVCA = self:createObject("Multiply","mRatioVCA")
    local mlimgain = self:createObject("GainBias","mlimgain")
    local mlimiter = self:createObject("Limiter","mlimiter")
    local mfdbk = self:createObject("GainBias","mfdbk")
    local mfdbkRange = self:createObject("MinMax","mfdbkRange")
    connect(mfdbk,"Out",mfdbkRange,"In")

    -- AM VCA
    local amvca = self:createObject("Multiply","amvca")
    local amIndex = self:createObject("GainBias","amIndex")
    local amIndexRange = self:createObject("MinMax","amIndexRange")

    -- wet/dry mixer
    local mixer = self:createObject("CrossFade","mixer")
    local wet = self:createObject("GainBias","wet")
    local wetRange = self:createObject("MinMax","wetRange")

    -- output volume control
    local vca = self:createObject("Multiply","vca")
    local level = self:createObject("GainBias","level")
    local levelRange = self:createObject("MinMax","levelRange")

    --tuning
    connect(ctune,"Out",ctuneRange,"In")
    connect(ctune,"Out",carrier,"V/Oct")
    connect(ctune,"Out",modulator,"V/Oct")
    connect(cf0,"Out",carrier,"Fundamental")
    connect(cf0,"Out",cf0Range,"In")
    connect(mRatio,"Out",mRatioRange,"In")
    connect(cf0,"Out",mRatioVCA,"Left")
    connect(mRatio,"Out",mRatioVCA,"Right")
    connect(mRatioVCA,"Out",modulator,"Fundamental")
  
    -- audio path
    connect(carrier,"Out",climgain,"In")
    connect(climgain,"Out",climiter,"In")
    connect(climiter,"Out",amvca,"Left")
    connect(modulator,"Out",mlimgain,"In")
    connect(mlimgain,"Out",mlimiter,"In")
    connect(mlimiter,"Out",amvca,"Right")
    connect(amvca,"Out",mixer,"A")
    connect(climiter,"Out",mixer,"B")
    connect(mixer,"Out",vca,"Left")
    connect(wet,"Out",wetRange,"In")
    connect(wet,"Out",mixer,"Fade")
    connect(level,"Out",levelRange,"In")
    connect(level,"Out",vca,"Right")
    connect(vca,"Out",self,"Out1")

    connect(cfdbk,"Out",carrier,"Feedback")
    connect(mfdbk,"Out",modulator,"Feedback")


    if channelCount==2 then
        connect(vca,"Out",self,"Out2")
    end

    self:createMonoBranch("level",level,"In",level,"Out")
    self:createMonoBranch("tune",ctune,"In",ctune,"Out")
    self:createMonoBranch("f0",cf0,"In",cf0,"Out")
    self:createMonoBranch("ratio",mRatio,"In",mRatio,"Out")
    self:createMonoBranch("wet",wet,"In",wet,"Out")
    self:createMonoBranch("cfdbk",cfdbk,"In",cfdbk,"Out")
    self:createMonoBranch("mfdbk",mfdbk,"In",mfdbk,"Out")
end
      
    local views = {
        expanded = {"tune","freq","ratio","csat","cfdbk","msat","mfdbk","wet","level"},
        collapsed = {},
      }
      
      local function linMap(min,max,superCoarse,coarse,fine,superFine)
        local map = app.LinearDialMap(min,max)
        map:setSteps(superCoarse,coarse,fine,superFine)
        return map
      end
      
      local ratioMap = linMap(0,24,1,0.5,0.01,0.001)
      local wetMap = linMap(0,1,1,0.1,0.01,0.001)
      local fdbkMap = linMap(-1,1,1,0.1,0.01,0.001)
      local driveMap = linMap(1,6,1,0.1,0.01,0.01)
      
      function Amie:onLoadViews(objects,branches)
        local controls = {}
      
        controls.tune = Pitch {
            button = "V/oct",
            branch = branches.tune,
            description = "V/oct",
            offset = objects.ctune,
            range = objects.ctuneRange
          }
      
        controls.freq = GainBias {
          button = "f0",
          description = "Fundamental",
          branch = branches.f0,
          gainbias = objects.cf0,
          range = objects.cf0Range,
          biasMap = Encoder.getMap("oscFreq"),
          biasUnits = app.unitHertz,
          initialBias = 27.5,
          gainMap = Encoder.getMap("freqGain"),
          scaling = app.octaveScaling
        }
      
        controls.ratio = GainBias {
          button = "ratio",
          description = "AM Ratio",
          branch = branches.ratio,
          gainbias = objects.mRatio,
          biasMap = ratioMap,
          range = objects.mRatioRange,
          initialBias = 1.0,
        }

        controls.csat = Fader {
            button = "car sat",
            description = "Carrier Saturation",
            param = objects.climgain:getParameter("Gain"),
            map = driveMap,
            initial = 1.0
            -- units = app.unitDecibels,
          }

          controls.msat = Fader {
            button = "mod sat",
            description = "Modulator Saturation",
            param = objects.mlimgain:getParameter("Gain"),
            map = driveMap,
            initial = 1.0
            -- units = app.unitDecibels,
          }

          controls.cfdbk = GainBias {
            button = "carFdbk",
            description = "Carrier Feedback",
            branch = branches.cfdbk,
            gainbias = objects.cfdbk,
            biasMap = fdbkMap,
            range = objects.cfdbkRange,
            initialBias = 0.0,
          }

          controls.mfdbk = GainBias {
            button = "modFdbk",
            description = "Modulator Feedback",
            branch = branches.mfdbk,
            gainbias = objects.mfdbk,
            biasMap = fdbkMap,
            range = objects.mfdbkRange,
            initialBias = 0.0,
          }

      
        controls.wet = GainBias {
            button = "wet",
            description = "0 car 1 ringmod",
            branch = branches.wet,
            gainbias = objects.wet,
            biasMap = wetMap,
            range = objects.wetRange,
            initialBias = 0.5,
          }

          controls.level = GainBias {
            button = "level",
            description = "Level",
            branch = branches.level,
            gainbias = objects.level,
            range = objects.levelRange,
            initialBias = 0.5,
          }
      
        return controls, views
      end
      
      return Amie