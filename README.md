# drumSynth

Currently it consists of:

## snare drum

- noise generator plus an impulse (making a thump) into a resonant 
  bandpass filter with feedback and saturation into a 
  decay-sustain-release envelope
    - the above in 3 channel version, for first-order ambisonics 
      decoding later on
    - the noises start out mono, and get wide controlled by an envelope
    - the filters have a start and end pitch, controlled by an envelope
    - the above times 4, with 4 sets of controlls, for 4 different 
      tunings
- mixed with an impulse (making a click, since it bypasses the filter)
- ambisonics-decoded into N channels.
