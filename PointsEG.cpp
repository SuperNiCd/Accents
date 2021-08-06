// #define BUILDOPT_VERBOSE
// #define BUILDOPT_DEBUG_LEVEL 10

#include <od/constants.h>
#include </home/joe/Accents/Accents/PointsEG.h>
#include <od/config.h>
#include <hal/ops.h>
#include <hal/log.h>

PointsEG::PointsEG()
{
    addInput(mGate);
    addParameter(mL1);
    addParameter(mL2);
    addParameter(mL3);
    addParameter(mL4);
    addParameter(mR1);
    addParameter(mR2);
    addParameter(mR3);
    addParameter(mR4);
    addParameter(mC1);
    addParameter(mC2);
    addParameter(mC3);
    addParameter(mC4);
    addOutput(mOutput);
    addOption(mGateHighFlavor);
    addOption(mRetrigger);
}

PointsEG::~PointsEG()
{
}

// inline float PointsEG::getSlope(float targetLevel, float currentLevel, float targetRate)
// {

//     return (targetLevel - currentLevel) / targetRate;
// }


// inline bool PointsEG::isStageComplete(float slope, float target, float current) 
// {
//     if (slope <=0 && current <= target)
//     {
//         return true;
//     }
//     else if (slope > 0 && current >= target) {
//         return true;
//     }
//     else return false;
// }

float PointsEG::getCurveValueAtT(float y1, float y2, float y3, float t)
{
    float curveYValue;
    curveYValue = ((1-t) * (1-t) * y1) + (2 * (1-t) * t * y2) + (t * t * y3);
    return curveYValue;
}


inline float PointsEG::next(float r1, float r2, float r3, float r4, float sustain)
{
    switch (mStage)
    {
    case 0: // waiting for trigger
        break;
    case 1: // stage 1 - travel to L1 at R1

        ///mSlope = getSlope(l1, mCapture, r1);
        

        // if (isStageComplete(mSlope,l1,mCurrentValue))
        if (mElapsedTime > r1)
        {
            mCapture = mCurrentValue;
            mElapsedTime = 0.0f;
            mStage = 2;
        }
        else
        {
            //mCurrentValue += (mSlope * globalConfig.samplePeriod);
            mCurrentValue = getCurveValueAtT(Y1, Y2, Y3, (mElapsedTime / r1));
        }
        break;
    case 2: // stage 2 - travel to L2 at R2
        //mSlope = getSlope(l2, mCapture, r2);
        //if (isStageComplete(mSlope,l2,mCurrentValue))
        if (mElapsedTime > r2)
        {
            mCapture = mCurrentValue;
            mElapsedTime = 0.0f;
            mStage = 3;
        }
        else
        {
            // mCurrentValue += (mSlope * globalConfig.samplePeriod);
            mCurrentValue = getCurveValueAtT(Y1, Y2, Y3, (mElapsedTime / r2));
        }
        break;
    case 3: // stage 3 - travel to L3 at R3
        // mSlope = getSlope(l3, mCapture, r3);

        // if (isStageComplete(mSlope,l3,mCurrentValue))
        if (mElapsedTime > r3)
        {
            mCapture = mCurrentValue;
            mElapsedTime = 0.0f;
            mStage = 4;
        }
        else
        {
            // mCurrentValue += (mSlope * globalConfig.samplePeriod);
            mCurrentValue = getCurveValueAtT(Y1, Y2, Y3, (mElapsedTime / r3));
        }
        break;        
    case 4: // stage 4 - sustain at L3
        if (mGateHighFlavor.value() == POINTS_HIGATE_LOOP)
        {
            mCapture = mCurrentValue;
            mElapsedTime = 0.0f;
            mStage = 1;
            break;
        }
        else
        {
            mCurrentValue = sustain;
        }

        break;
    case 5: // stage 5 - travel to L4 at R4
        // mSlope = getSlope(l4, mCapture, r4);
        // if (isStageComplete(mSlope,l4,mCurrentValue))
        if (mElapsedTime > r4)
        {
            mCapture = mCurrentValue;
            mElapsedTime = 0.0f;
            mStage = 0;
        }
        else
        {
            // mCurrentValue += (mSlope * globalConfig.samplePeriod);
            mCurrentValue = getCurveValueAtT(Y1, Y2, Y3, (mElapsedTime / r4));
        }
        break;
    }
    mElapsedTime += globalConfig.samplePeriod;
    return mCurrentValue;
}


void PointsEG::process()
{
    float *gate = mGate.buffer();
    float *out = mOutput.buffer();
    float l1 = mL1.value();
    float l2 = mL2.value();
    float l3 = mL3.value();
    float l4 = mL4.value();
    float r1 = mR1.value();
    float r2 = mR2.value();
    float r3 = mR3.value();
    float r4 = mR4.value();
    // Change Ls and Rs to params?
    float c1 = mC1.value();
    float c2 = mC2.value();
    float c3 = mC3.value();
    float c4 = mC4.value();
 
    for (int i = 0; i < FRAMELENGTH; i++)
    {
        if (mStage == 1 || mStage == 0)
        {
            if (mCapture > l1) { c1 = -c1; }
            // X1 = 0;
            Y1 = mCapture;
            // X2 = r1[0] / 2;
            Y2 = mCapture + ((l1 - mCapture) / 2) + (c1 * (l1 - mCapture) / 2);
            // X3 = r1[0];
            Y3 = l1;
        }
        else if (mStage == 2)
        {
            if (mCapture > l2) { c2 = -c2; }
            // X1 = 0;
            Y1 = mCapture;
            // X2 = r2[0] / 2;
            Y2 = mCapture + ((l2 - mCapture) / 2) + (c2 * (l2 - mCapture) / 2);
            // X3 = r2[0];
            Y3 = l2;
        }
        else if (mStage == 3)
        {
            if (mCapture > l3) { c3 = -c3; }
            // X1 = 0;
            Y1 = mCapture;
            // X2 = r3[0] / 2;
            Y2 = mCapture + ((l3 - mCapture) / 2) + (c3 * (l3 - mCapture) / 2);
            // X3 = r3[0];
            Y3 = l3;
        }
        else if (mStage == 5)
        {
            if (mCapture > l4) { c4 = -c4; }
            // X1 = 0;
            Y1 = mCapture;
            // X2 = r4[0] / 2;
            Y2 = mCapture + ((l4 - mCapture) / 2) + (c4 * (l4 - mCapture) / 2);
            // X3 = r4[0];
            Y3 = l4;
        }

        if ((mStage == 0 || mStage == 5))
        {
            // envelope is inactive
            if (gate[i] > 0.5f)
            {
                // turn on
                mStage = 1;
                if (mRetrigger.value() == POINTS_RETRIGGER_ANALOG) 
                {
                    mCapture = mCurrentValue;
                }
                else
                {
                    mCapture = l4;
                }
                mElapsedTime = 0.0f;
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
                mElapsedTime = 0.0f;
                if (mCapture > l4) { c4 = -c4; }
                // X1 = 0;
                Y1 = mCapture;
                // X2 = r4[0] / 2;
                Y2 = mCapture + ((l4 - mCapture) / 2) + (c4 * (l4 - mCapture) / 2);
                // X3 = r4[0];
                Y3 = l4;
            }
        }

        out[i] = next(MAX(0.0001f,r1), MAX(0.0001f,r2), MAX(0.0001f,r3), MAX(0.0001f,r4), l3);
        // if (++counter == 10)
        // {
        //     if (mStage != 0 and mStage !=5) { logDebug(1,"stage: %d, value: %f", mStage, mCurrentValue); }
        //     counter = 0;
        // }
    }
}
