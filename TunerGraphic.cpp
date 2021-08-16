#define BUILDOPT_VERBOSE
#define BUILDOPT_DEBUG_LEVEL 10
#include <TunerGraphic.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <hal/log.h>

TunerGraphic::TunerGraphic(int left, int bottom, int width, int height) : od::Graphic(left, bottom, width, height)

{
}

TunerGraphic::~TunerGraphic()
{
  if (mpTuner)
  {
    mpTuner->release();
  }
}

const float freqs[108] = {16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87, 32.7, 34.65, 36.71, 38.89, 41.2, 43.65, 46.25, 49, 51.91, 55, 58.27, 61.74, 65.41, 69.3, 73.42, 77.78, 82.41, 87.31, 92.5, 98, 103.83, 110, 116.54, 123.47, 130.81, 138.59, 146.83, 155.56, 164.81, 174.61, 185, 196, 207.65, 220, 233.08, 246.94, 261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392, 415.3, 440, 466.16, 493.88, 523.25, 554.37, 587.33, 622.25, 659.25, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77, 1046.5, 1108.73, 1174.66, 1244.51, 1318.51, 1396.91, 1479.98, 1567.98, 1661.22, 1760, 1864.66, 1975.53, 2093, 2217.46, 2349.32, 2489.02, 2637.02, 2793.83, 2959.96, 3135.96, 3322.44, 3520, 3729.31, 3951.07, 4186.01, 4434.92, 4698.63, 4978.03, 5274.04, 5587.65, 5919.91, 6271.93, 6644.88, 7040, 7458.62, 7902.13};
const char *notes[108] = {"C0", "C#0/Db0", "D0", "D#0/Eb0", "E0", "F0", "F#0/Gb0", "G0", "G#0/Ab0", "A0", "A#0/Bb0", "B0", "C1", "C#1/Db1", "D1", "D#1/Eb1", "E1", "F1", "F#1/Gb1", "G1", "G#1/Ab1", "A1", "A#1/Bb1", "B1", "C2", "C#2/Db2", "D2", "D#2/Eb2", "E2", "F2", "F#2/Gb2", "G2", "G#2/Ab2", "A2", "A#2/Bb2", "B2", "C3", "C#3/Db3", "D3", "D#3/Eb3", "E3", "F3", "F#3/Gb3", "G3", "G#3/Ab3", "A3", "A#3/Bb3", "B3", "C4", "C#4/Db4", "D4", "D#4/Eb4", "E4", "F4", "F#4/Gb4", "G4", "G#4/Ab4", "A4", "A#4/Bb4", "B4", "C5", "C#5/Db5", "D5", "D#5/Eb5", "E5", "F5", "F#5/Gb5", "G5", "G#5/Ab5", "A5", "A#5/Bb5", "B5", "C6", "C#6/Db6", "D6", "D#6/Eb6", "E6", "F6", "F#6/Gb6", "G6", "G#6/Ab6", "A6", "A#6/Bb6", "B6", "C7", "C#7/Db7", "D7", "D#7/Eb7", "E7", "F7", "F#7/Gb7", "G7", "G#7/Ab7", "A7", "A#7/Bb7", "B7", "C8", "C#8/Db8", "D8", "D#8/Eb8", "E8", "F8", "F#8/Gb8", "G8", "G#8/Ab8", "A8", "A#8/Bb8", "B8"};
void TunerGraphic::draw(od::FrameBuffer &fb)
{


  if (mpTuner)
  {
    currentFreq = mpTuner->frequency;

    // determine the highest note stop
    for (int i = 0; i < 108; i++)
    {
      if (freqs[i] >= currentFreq)
      {
        // topIndex = i;
        targetIndex = i - 1;
        break;
      }
    }

    float halfwayFreq = (freqs[targetIndex + 1] - freqs[targetIndex]) / 2;
    if (currentFreq <= freqs[targetIndex] + halfwayFreq)
    {
      scale = (currentFreq - freqs[targetIndex]) / halfwayFreq;
      noteIndex = targetIndex;
    }
    else
    {
      scale = (currentFreq - freqs[targetIndex + 1]) / halfwayFreq;
      noteIndex = targetIndex + 1;
    }

    int centerX = mWorldLeft + mWidth / 2;
    int centerY = mWorldBottom + mHeight / 2;
    // logDebug(1, "scale: %f", scale);

    if (targetIndex >= 0)
    {
      int offset = floor(strlen(notes[noteIndex]) / 2 * 16);
      fb.text(WHITE, centerX - offset + 2, centerY, notes[noteIndex], 16);
      fb.line(WHITE, centerX, centerY - 20, centerX, centerY - 13);
      fb.box(WHITE, centerX - 80, centerY - 18, centerX + 80, centerY - 15);
      fb.text(WHITE, mWorldLeft + 2, mWorldBottom + 2, "b", 10);
      fb.text(WHITE, centerX + 74, mWorldBottom + 2, "#", 10);
      if (scale >= 0)
      {
        fb.fill(WHITE, centerX, centerY - 18, centerX + (80 * scale), centerY - 16);
      }
      else
      {
        fb.fill(WHITE, centerX + (80 * scale), centerY - 18, centerX, centerY - 16);
      }
    }
    else
    {
      fb.text(WHITE, mWorldLeft + 6, centerY, "No note data", 10);
    }
  }
}

void TunerGraphic::follow(Tuner *pTuner)
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