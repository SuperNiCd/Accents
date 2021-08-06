// #define BUILDOPT_VERBOSE
// #define BUILDOPT_DEBUG_LEVEL 10

#include <od/constants.h>
#include </home/joe/Accents/Accents/DXEG.h>
#include <od/config.h>
#include <hal/ops.h>
#include <hal/log.h>

DXEG::DXEG()
{
    addInput(mGate);
    addInput(mL1);
    addInput(mL2);
    addInput(mL3);
    addInput(mL4);
    addInput(mR1);
    addInput(mR2);
    addInput(mR3);
    addInput(mR4);
    addOutput(mOutput);
    addOption(mGateHighFlavor);
}

DXEG::~DXEG()
{
}

inline float DXEG::getSlope(float targetLevel, float currentLevel, float targetRate)
{

    return (targetLevel - currentLevel) / targetRate;
}

inline bool DXEG::isStageComplete(float slope, float target, float current) 
{
    if (slope <=0 && current <= target)
    {
        return true;
    }
    else if (slope > 0 && current >= target) {
        return true;
    }
    else return false;
}


inline float DXEG::next(float l1, float l2, float l3, float l4, float r1, float r2, float r3, float r4)
{
    switch (mStage)
    {
    case 0: // waiting for trigger
        break;
    case 1: // stage 1 - travel to L1 at R1
        mSlope = getSlope(l1, mCapture, r1);
        if (isStageComplete(mSlope,l1,mCurrentValue))
        {
            mCapture = mCurrentValue;
            mStage = 2;
        }
        else
        {
            mCurrentValue += (mSlope * globalConfig.samplePeriod);
        }
        break;
    case 2: // stage 2 - travel to L2 at R2
        mSlope = getSlope(l2, mCapture, r2);
        if (isStageComplete(mSlope,l2,mCurrentValue))
        {
            mCapture = mCurrentValue;
            mStage = 3;
        }
        else
        {
            mCurrentValue += (mSlope * globalConfig.samplePeriod);
        }
        break;
    case 3: // stage 3 - travel to L3 at R3
        mSlope = getSlope(l3, mCapture, r3);
        if (isStageComplete(mSlope,l3,mCurrentValue))
        {
            mCapture = mCurrentValue;
            mStage = 4;
        }
        else
        {
            mCurrentValue += (mSlope * globalConfig.samplePeriod);
        }
        break;        
    case 4: // stage 4 - sustain at L3
        if (mGateHighFlavor.value() == DXEG_HIGATE_LOOP)
        {
            mCapture = mCurrentValue;
            mStage = 1;
        }
        else
        {
            mCurrentValue = l3;
        }
        break;
    case 5: // stage 5 - travel to L4 at R4
        mSlope = getSlope(l4, mCapture, r4);
        if (isStageComplete(mSlope,l4,mCurrentValue))
        {
            mCapture = mCurrentValue;
            mStage = 0;
        }
        else
        {
            mCurrentValue += (mSlope * globalConfig.samplePeriod);
        }
        break;
    }

    return mCurrentValue;
}


void DXEG::process()
{
    float *gate = mGate.buffer();
    float *out = mOutput.buffer();
    float *l1 = mL1.buffer();
    float *l2 = mL2.buffer();
    float *l3 = mL3.buffer();
    float *l4 = mL4.buffer();
    float *r1 = mR1.buffer();
    float *r2 = mR2.buffer();
    float *r3 = mR3.buffer();
    float *r4 = mR4.buffer();

    for (int i = 0; i < FRAMELENGTH; i++)
    {
        if ((mStage == 0 || mStage == 5))
        {
            // envelope is inactive
            if (gate[i] > 0.5f)
            {
                // turn on
                mStage = 1;
                mCapture = mCurrentValue;
            }
        }
        else
        {
            // envelope is active
            if (gate[i] < 0.5f)
            {
                // turn off
                mStage = 5;
                mCapture = mCurrentValue;
            }
        }

        
        out[i] = next(l1[i], l2[i], l3[i], l4[i], MAX(0.0001f,r1[i]), MAX(0.0001f,r2[i]), MAX(0.0001f,r3[i]), MAX(0.0001f,r4[i]));
    }
}
