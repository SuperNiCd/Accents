local app = app
local libAccents = require "Accents.libAccents"
local Class = require "Base.Class"
local Unit = require "Unit"
local Gate = require "Unit.ViewControl.Gate"
local Fader = require "Unit.ViewControl.Fader"
local GainBias = require "Unit.ViewControl.GainBias"

local VoltageVault = Class {}
VoltageVault:include(Unit)

function VoltageVault:init(args)
  args.title = "Voltage Vault"
  args.mnemonic = "VV"
  Unit.init(self, args)
end


function VoltageVault:onLoadGraph(channelCount)
  local sh = self:addObject("sh", libAccents.VoltageVault())
  local trig = self:addObject("trig", app.Comparator())
  local bptrig = self:addObject("bptrig",app.Comparator())
  local sumtrig = self:addObject("sumtrig",app.Comparator())
  local index = self:addObject("index",app.ParameterAdapter())
  local indexRange = self:addObject("indexRange",app.MinMax())
  trig:setTriggerMode()
  bptrig:setToggleMode()
  sumtrig:setToggleMode()

  connect(trig, "Out", sh, "Track")
  connect(bptrig, "Out", sh, "Bypass")
  connect(sumtrig, "Out", sh, "SumInput")
  connect(self, "In1", sh, "In")
  connect(index,"Out",indexRange,"In")
  tie(sh, "Index", index, "Out")
  connect(sh, "Out", self, "Out1")

  self:addMonoBranch("trig", trig, "In", trig, "Out")
  self:addMonoBranch("bypass", bptrig, "In", bptrig, "Out")
  self:addMonoBranch("sum", sumtrig, "In", sumtrig, "Out")
  self:addMonoBranch("index", index, "In", index, "Out")

  if channelCount == 2 then
    connect(sh,"Out",self,"Out2")
  end
end

local views = {
  expanded = {"trig","index","bypass","sum"},
  collapsed = {}
}

local function intMap(min,max)
  local map = app.LinearDialMap(min,max)
  map:setSteps(5,1,0.25,0.25);
  map:setRounding(1)
  return map
end

local indexMap = intMap(0,127) 

function VoltageVault:onLoadViews(objects, branches)
  local controls = {}

  controls.trig = Gate {
    button = "store",
    branch = branches.trig,
    description = "Trigger to store val",
    comparator = objects.trig,
  }

  controls.index = GainBias {
    button = "index",
    description = "Vault Slot",
    branch = branches.index,
    gainbias = objects.index,
    range = objects.indexRange,
    biasMap = indexMap,
    biasPrecision = 0,
    gainMap = indexMap,
    initialBias = 0,
  }


  controls.bypass = Gate {
    button = "bypass",
    description = "Pass thru Input",
    branch = branches.bypass,
    comparator = objects.bptrig,
  }

  controls.sum = Gate {
    button = "sum",
    description = "Add Input to Vault Val",
    branch = branches.sum,
    comparator = objects.sumtrig,
  }  
    return controls, views
end

function VoltageVault:serialize()
  local t = Unit.serialize(self)
  local vaults = {}
  for i = 0, 127 do 
    vaults[i] = self.objects.sh:getVaults(i)
  end
  t.vaults = vaults
  return t
end

function VoltageVault:deserialize(t)
  Unit.deserialize(self, t)
  if t.vaults then
    for i = 0,127 do 
      self.objects.sh:setVaults(i, t.vaults[i])
    end
  end
end

return VoltageVault
