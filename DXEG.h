
#include <od/objects/Object.h>

#define DXEG_HIGATE_SUSTAIN 1
#define DXEG_HIGATE_LOOP 2

class DXEG : public od::Object
{
public:
    DXEG();
    virtual ~DXEG();

#ifndef SWIGLUA
    virtual void process();
    od::Inlet mL1{"L1"};
    od::Inlet mL2{"L2"};
    od::Inlet mL3{"L3"};
    od::Inlet mL4{"L4"};
    od::Inlet mR1{"R1"};
    od::Inlet mR2{"R2"};
    od::Inlet mR3{"R3"};
    od::Inlet mR4{"R4"};
    od::Inlet mGate{"Gate"};
    od::Outlet mOutput{"Out"};
    od::Option mGateHighFlavor{"GateHighFlavor"};
#endif

private:
    float next(float l1, float l2, float l3, float l4, float r1, float r2, float r3, float r4);
    float getSlope(float targetLevel, float currentLevel, float targetRate);
    bool isStageComplete(float slope, float target, float current);

    int mStage = 0;
    float mCapture = 0.0f;
    float mSlope = 0.0f;
    float mCurrentValue = 0.0f;
};
