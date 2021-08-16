#pragma once

#include <od/objects/Object.h>
#include <vector> 

class Tuner : public od::Object
{
public:
  Tuner();
   ~Tuner();

#ifndef SWIGLUA
    virtual void process();
    od::Inlet mInput{"In"};
    od::Outlet mOutput{"Out"};
    od::Parameter mIndex{"Index", 0};

#endif
    // void setVaults(int, float);
    // float getVaults(int);

protected:
  friend class TunerGraphic;
  friend class TunerGraphicSub;
  // float radiusIndex = 0.0;
  float frequency = 0.0f;
  int ticksSinceLastZeroCrossing = 1;
  float lastSampleValue = 0.0f;
};