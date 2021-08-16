#pragma once

#include <od/graphics/Graphic.h>
#include <Tuner.h>

class TunerGraphic : public od::Graphic
{
public:
  TunerGraphic(int left, int bottom, int width, int height);
  virtual ~TunerGraphic();

#ifndef SWIGLUA
  virtual void draw(od::FrameBuffer &fb);
#endif

  void follow(Tuner *pTuner);

private:
  Tuner *mpTuner = 0;
  float currentFreq = 0.0f;
  int topIndex = 1;
  int targetIndex = 1;
};