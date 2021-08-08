#define BUILDOPT_VERBOSE
#define BUILDOPT_DEBUG_LEVEL 10

#include </home/joe/Accents/Bitwise.h>
// #include <hal/simd.h>
#include <hal/ops.h>
#include <od/config.h>
#include <hal/log.h>
#include <math.h>

Bitwise::Bitwise()
{
    addInput(mA);
    addInput(mB);
    addOutput(mOutput);
    addOption(mOperation);
}

Bitwise::~Bitwise()
{
}

void Bitwise::process()
{
    float *a = mA.buffer();
    float *b = mB.buffer();
    float *out = mOutput.buffer();

    switch (mOperation.value())
    {
    case BITWISE_CHOICE_AONLY:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = a[i];
        }
        break;

    case BITWISE_CHOICE_BONLY:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = b[i];
        }
        break;        

    case BITWISE_CHOICE_AND:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = aVal & bVal;
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }
        break;

    case BITWISE_CHOICE_OR:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = aVal | bVal;
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }
        break;

    case BITWISE_CHOICE_XOR:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = aVal ^ bVal;
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }                
        break;

    case BITWISE_CHOICE_NAND:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = ~(aVal & bVal);
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }
        break;

    case BITWISE_CHOICE_NOR:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = ~(aVal & bVal);
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }
        break;

    case BITWISE_CHOICE_XNOR:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            aVal = a[i] * INT32_MAX;
            bVal = b[i] * INT32_MAX;
            opVal = ~(aVal & bVal);
            outVal = (float) opVal / INT32_MAX;
            out[i] = outVal;
        }
        break;                        


    default:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = a[i];
        }
        break;
    }
}
