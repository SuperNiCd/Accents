
#include <od/objects/Object.h>

#define POINTS_HIGATE_SUSTAIN 1
#define POINTS_HIGATE_LOOP 2

#define POINTS_RETRIGGER_ANALOG 1
#define POINTS_RETRIGGER_DIGITAL 2

class PointsEG : public od::Object
{
public:
    PointsEG();
    virtual ~PointsEG();

#ifndef SWIGLUA
    virtual void process();
    od::Parameter mL1{"L1"};
    od::Parameter mL2{"L2"};
    od::Parameter mL3{"L3"};
    od::Parameter mL4{"L4"};
    od::Parameter mR1{"R1"};
    od::Parameter mR2{"R2"};
    od::Parameter mR3{"R3"};
    od::Parameter mR4{"R4"};
    od::Parameter mC1{"C1",0.0f};
    od::Parameter mC2{"C2",0.0f};
    od::Parameter mC3{"C3",0.0f};
    od::Parameter mC4{"C4",0.0f};
    od::Inlet mGate{"Gate"};
    od::Outlet mOutput{"Out"};
    od::Option mGateHighFlavor{"GateHighFlavor"};
    od::Option mRetrigger{"Retrigger",1};
#endif

private:
    float next(float r1, float r2, float r3, float r4, float sustain);
    // float getSlope(float targetLevel, float currentLevel, float targetRate);
    // bool isStageComplete(float slope, float target, float current);
    float getCurveValueAtT(float y1, float y2, float y3, float t);

    int mStage = 0;
    float mCapture = 0.0f;
    // float mSlope = 0.0f;
    float mCurrentValue = 0.0f;
    float mElapsedTime = 0.0f;

    // float X1, X2, X3, 
    float Y1, Y2, Y3 = 0.0f;
    // int counter = 0;



};
