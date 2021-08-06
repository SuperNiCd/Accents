local units = {

    -- {category="Essentials"},
    {title="Linear Sampling VCA", moduleName="LinearSamplingVCA",keywords="modulate, utility",category="Essentials"},
    {title="Xfade",moduleName="XFade",keywords="utility",category="Essentials"},

    -- {category = "Delays and Reverb"},


    -- {category="Filtering"},
    -- {title="Ladder BPF",moduleName="BespokeBPF",keywords="filter", category="Filtering"},


    -- {category="Modulation"},
   
    -- {category="Oscillators"},
    {title="Aliasing Pulse",moduleName="BespokeAliasingPulse",keywords="oscillator",category="Oscillators"},

    -- {title="DXEG",moduleName="DXEG",keywords="envelope",category="Envelopes"},
    {title="Points",moduleName="PointsEG",keywords="envelope",category="Envelopes"},
    

  --   {category="Mapping and Control"},
    {title="Compare",moduleName="Compare",keywords="mapping,control",category="Mapping and Control"},
    {title="Clocked Random Gate",moduleName="ClockedRandomGate",keywords="control",category="Mapping and Control"},
    {title="Motion Sensor",moduleName="MotionSensor",keywords="mapping",category="Mapping and Control"},
    {title="Weighted Coin Toss",moduleName="WeightedCoinToss",keywords="control",category="Mapping and Control"},
    {title="Pingable Scaled Random",moduleName="PingableScaledRandom",keywords="modulation",category="Mapping and Control"},
    {title="Maths",moduleName="MathsUnit",keywords="modulate",category="Mapping and Control"},
    {title="Logics",moduleName="Logics",keywords="mapping,control",category="Mapping and Control"},
    {title="Voltage Vault",moduleName="VoltageVault",keywords="mapping",category="Mapping and Control"},
    {title="Voltage Bank",moduleName="VoltageBank",keywords="mapping",category="Mapping and Control"},
    {title="Voltage Bank 4",moduleName="VoltageBank4",keywords="mapping",category="Mapping and Control"},
    {title="Voltage Bank 2",moduleName="VoltageBank2",keywords="mapping",category="Mapping and Control"},
    {title="Octave CV Shifter", moduleName="OctaveCVShifter",keywords="mapping",category="Mapping and Control"},
    {title="AB Switch", moduleName="ABSwitch",keywords="control",category="Mapping and Control"},

    -- {category="Timing"},
    {title="Carousel Clock Divider",moduleName="CarouselClockDivider",keywords="timing",category="Timing"},
    {title="Timed Gate", moduleName="TimedGate",keywords="timing",category="Timing"},
    
    -- {category="Experimental"},
    
    {title="Ladder BPF",moduleName="BespokeBPF",keywords="filter", category="Filtering",aliases={"Bespoke BPF"}},

    -- {category="Synthesizers"},
    {title="Amie",moduleName="Amie",keywords="oscillator",category="Synthesizers"},
    {title="Xoxoxo",moduleName="Xoxoxo",keywords="oscillator",category="Synthesizers"},
    {title="Xoxo",moduleName="Xoxo",keywords="oscillator",category="Synthesizers"},
    {title="Xo",moduleName="Xo",keywords="oscillator",category="Synthesizers"},
    {title="Phase Mod Matrix",moduleName="Xxxxxx",keywords="oscillator",category="Synthesizers",aliases={"Xxxxxx"}},

  --   {category = "Audio Effects"},
    {title="Rotary Speaker Simulator", moduleName="RotarySpeakerSim",keywords="effect",category="Audio Effects",channelCount=2},
    {title="Phaser", moduleName="Phaser4",keywords="effect",category="Audio Effects",category="Audio Effects"},
    {title="Ensemble",moduleName="StereoEnsemble",keywords="modulate, pitch",category="Audio Effects"},
    {title="Flanger",moduleName="Flanger",keywords="modulate, pitch",category = "Audio Effects"},
    {title="Ring Modulator",moduleName="Ringmod",keywords="pitch, modulate",category="Audio Effects"},
    {title="Scorpio Vocoder", moduleName="Scorpio", keywords="filter, modulate",category="Audio Effects"},
    {title="Bitwise", moduleName="Bitwise", keywords="combine", category="Audio Effects"}
  -- }
}
  return {
    title = "Accents",
    name = "accents",
    keyword = "accents",
    author = "Joe",
    units = units
  }
  