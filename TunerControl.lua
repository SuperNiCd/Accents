local app = app
local libAccents = require "Accents.libAccents"
local Class = require "Base.Class"
local ViewControl = require "Unit.ViewControl"
local ply = app.SECTION_PLY

local TunerControl = Class {}
TunerControl:include(ViewControl)

function TunerControl:init(args)
  local tuner = args.tuner or
                        app.logError("%s.init: tuner is missing.", self)

  ViewControl.init(self, "circle")
  self:setClassName("TunerControl")

  local width = args.width or (4 * ply)

  local graphic
  graphic = app.Graphic(0, 0, width, 64)
  self.pDisplay = libAccents.TunerGraphic(0, 0, width, 64)
  graphic:addChild(self.pDisplay)
  self:setMainCursorController(self.pDisplay)
  self:setControlGraphic(graphic)

  -- add spots
  for i = 1, (width // ply) do
    self:addSpotDescriptor{
      center = (i - 0.5) * ply
    }
  end

  local subGraphic = app.Graphic(0, 0, 128, 64)
  self.subDisplay = libAccents.TunerGraphicSub(0, 0, 128, 64)
  subGraphic:addChild(self.subDisplay)
  self.subGraphic = subGraphic

  self:follow(tuner)
end

function TunerControl:follow(tuner)
  self.pDisplay:follow(tuner)
  self.subDisplay:follow(tuner)
  self.tuner = tuner
end

return TunerControl