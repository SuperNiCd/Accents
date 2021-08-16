#define BUILDOPT_VERBOSE
#define BUILDOPT_DEBUG_LEVEL 10

#include <./Tuner.h>
#include <hal/ops.h>
// #include <hal/simd.h>
// #include <hal/ops.h>
#include <od/config.h>
// #include <vector>
#include <hal/log.h>

ConfigData globalConfig;

// const std::vector<int> notes = { };
Tuner::Tuner()
{
    addInput(mInput);
    addOutput(mOutput);
    addParameter(mIndex);
}

Tuner::~Tuner()
{
}

void Tuner::process()
{
    float *out = mOutput.buffer();
    float *in = mInput.buffer();
    // radiusIndex = mIndex.value();

    for (int i = 0; i < FRAMELENGTH; i++)
    {
        out[i] = in[i];
        if (lastSampleValue < 0.0f && in[i] >= 0.0f)
        {

            frequency = (frequency + (1 / (ticksSinceLastZeroCrossing * globalConfig.samplePeriod)))/2;
            // logDebug(1, "ticksSinceLastZeroCrossing=%d, freq=%f", ticksSinceLastZeroCrossing, frequency);
            ticksSinceLastZeroCrossing = 0;
        }
        else
        {
            ticksSinceLastZeroCrossing++;
        }
        lastSampleValue = in[i];
    }
}
