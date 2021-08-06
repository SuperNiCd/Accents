#pragma once

#include <od/objects/Object.h>
#include <vector> 

class VoltageVault : public od::Object
{
public:
  VoltageVault();
   ~VoltageVault();

#ifndef SWIGLUA
    virtual void process();
    od::Inlet mInput{"In"};
    od::Inlet mTrack{"Track"};
    od::Outlet mOutput{"Out"};
    od::Parameter mIndex{"Index", 0};
    od::Inlet mBypass{"Bypass"};
    od::Inlet mSumInput{"SumInput"};

#endif
    void setVaults(int, float);
    float getVaults(int);

protected:
  // Protected declarations are also omitted from the swig wrapper.  
  float vault[128] = { };


};