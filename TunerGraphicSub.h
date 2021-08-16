#pragma once

#include <od/graphics/Graphic.h>
#include <Tuner.h>

class TunerGraphicSub : public od::Graphic
{
public:
  TunerGraphicSub(int left, int bottom, int width, int height);
  virtual ~TunerGraphicSub();

#ifndef SWIGLUA
  virtual void draw(od::FrameBuffer &fb);
#endif

  void follow(Tuner *pTuner);

private:
  Tuner *mpTuner = 0;
  float freq = 0.0f;
};