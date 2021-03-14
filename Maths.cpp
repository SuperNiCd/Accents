#define BUILDOPT_VERBOSE
#define BUILDOPT_DEBUG_LEVEL 10

#include </home/joe/Accents/Accents/Maths.h>
// #include <hal/simd.h>
#include <hal/ops.h>
#include <od/config.h>
#include <vector>
#include <hal/log.h>
#include <math.h>

Maths::Maths()
{
    addInput(mA);
    addInput(mB);
    addOutput(mOutput);
    addOption(mOperation);
}

Maths::~Maths()
{
}

void Maths::process()
{
    float *a = mA.buffer();
    float *b = mB.buffer();
    float *out = mOutput.buffer();

    switch (mOperation.value())
    {
    // Minimum of a and b - MIN(a,b)    
    case MATHS_CHOICE_MIN:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            if (a[i] > b[i])
            {
                out[i] = b[i];
            }
            else
            {
                out[i] = a[i];
            }
        }
        break;

    // Maximum of a and b - MAX(a,b)
    case MATHS_CHOICE_MAX:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            if (a[i] > b[i])
            {
                out[i] = a[i];
            }
            else
            {
                out[i] = b[i];
            }
        }
        break;

    // Average of a and b - MEAN(a,b)
    case MATHS_CHOICE_MEAN:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = (a[i] + b[i]) / 2;
        }
        break;

    // Divide a by b - divide by zero outputs 10,000
    case MATHS_CHOICE_DIV:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            if (b[i] == 0.0)
            {
                out[i] = 10000.0f;
            }
            else
            {
                out[i] = a[i] / b[i];
            }
        }
        break;        

    // Inverse(a) - 1/a - divide by zero outputs 10,000
    case MATHS_CHOICE_INV:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            if (b[i] == 0.0)
            {
                out[i] = 10000.0f;
            }
            else
            {
                out[i] = 1.0f / a[i];
            }
        }
        break;                

    // a%b - remainder when dividing a by b, divide by zero outputs 0
    case MATHS_CHOICE_MOD:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            if (b[i] == 0.0)
            {
                out[i] = 0.0f;
            }
            else
            {
                out[i] = fmod(a[i], b[i]);
            }
        }
        break;     

    case MATHS_CHOICE_TANH:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = tanh(a[i]);
        }
        break;        

    case MATHS_CHOICE_ATAN:
        for (int i = 0; i < FRAMELENGTH; i++)
        {
            out[i] = atan(a[i]);
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
