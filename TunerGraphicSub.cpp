#include <./TunerGraphicSub.h>
#include <math.h>
#include <stdio.h>


TunerGraphicSub::TunerGraphicSub(int left, int bottom, int width, int height) : od::Graphic(left, bottom, width, height)

{
}

TunerGraphicSub::~TunerGraphicSub()
{
    if (mpTuner)
    {
        mpTuner->release();
    }
}

void TunerGraphicSub::draw(od::FrameBuffer &fb)
{
    // const int CURSOR = 3;
    const int MARGIN = 2;
    if (mpTuner)
    {
        fb.text(WHITE, MARGIN, mHeight - 12, "Frequency (Hz)", 10);
        freq = mpTuner->frequency;
        char buffer[64];
        int ret = snprintf(buffer, sizeof buffer, "%.2f", freq);
        fb.text(WHITE, MARGIN, mHeight - 24, buffer, 14);
    }
}

void TunerGraphicSub::follow(Tuner *pTuner)
{
    if (mpTuner)
    {
        mpTuner->release();
    }
    mpTuner = pTuner;
    if (mpTuner)
    {
        mpTuner->attach();
    }
}