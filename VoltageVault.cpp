#define BUILDOPT_VERBOSE
#define BUILDOPT_DEBUG_LEVEL 10

#include </home/joe/Accents/Accents/VoltageVault.h>
#include <hal/ops.h>
#include <hal/simd.h>
#include <hal/ops.h>
#include <od/config.h>
#include <vector>
#include <hal/log.h>

VoltageVault::VoltageVault()
{
  addInput(mInput);
  addInput(mTrack);
  addOutput(mOutput);
  addParameter(mIndex);
  addInput(mBypass);
  addInput(mSumInput);
}

VoltageVault::~VoltageVault()
{
}

void VoltageVault::setVaults(int i, float v)
{
  vault[i] = v;
}

float VoltageVault::getVaults(int i)
{
  return vault[i];
}

void VoltageVault::process()
{
  int index = mIndex.roundTarget();
  // float value = getCurrentVaultValue(index);
  float value = vault[index];
  float *in = mInput.buffer();
  float *track = mTrack.buffer();
  float *bypass = mBypass.buffer();
  float *out = mOutput.buffer();
  float32x4_t thresh = vdupq_n_f32(0.5f);
  float *sum = mSumInput.buffer();
  // logDebug(1,"Index: %d, Value: %f",index,value);

  for (int i = 0; i < FRAMELENGTH; i += 4)
  {
    float32x4_t x = vld1q_f32(track + i);
    uint32_t high[4];
    vst1q_u32(high, vcgtq_f32(x, thresh));

    float32x4_t y = vld1q_f32(bypass + i);
    uint32_t bphigh[4];
    vst1q_u32(bphigh, vcgtq_f32(y, thresh));

    float32x4_t z = vld1q_f32(sum + i);
    uint32_t sumhigh[4];
    vst1q_u32(sumhigh, vcgtq_f32(z, thresh));

    for (int j = 0; j < 4; j++)
    {
      if (high[j])
      {
        value = in[i + j];
      }
      if (bphigh[j])
      {
        out[i + j] = in[i + j];
      }
      else
      {
        if (sumhigh[j])
        {
          out[i + j] = value + in[i + j];
        }
        else
        {
          out[i + j] = value;
        }
      }
    }
  }

  vault[index] = value;
}
