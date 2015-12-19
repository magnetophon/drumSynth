


import ("effect.lib");
import ("oscillator.lib");
import ("hoa.lib");

noiseGroup(x)         = (hgroup("[1]noise", x));
widthGroup(x)         = (hgroup("[2]width", x));
filterGroup(x)        = (vgroup("[3]filter", x));
freqGroup(x)          = (hgroup("[1]frequency", x));
generalFilterGroup(x) = (hgroup("[2]general", x));
ampGroup(x)           = (hgroup("[3]amplitude", x));

decay      = (vslider("[01]decay [style:knob][tooltip: decay time]",0.1,0,1,0.001) );
sustain    = (vslider("[02]sustain [style:knob][tooltip: sustain level]",0.4,0,1,0.001):pow(3):smooth(0.999) );
release    = (vslider("[03]release [style:knob][tooltip: release time]",0.7,0,1,0.001) );
startfreq  = (vslider("[04]start freq  [start frequency of the filter as a Piano Key (PK) number (A440 = key 49)][style:knob]",  42,1,88,1) ):smooth(0.999);
endfreq    = (vslider("[05]end freq  [end frequency of the filter as a Piano Key (PK) number (A440 = key 49)][style:knob]",  35,1,88,1) ):smooth(0.999);
Q          = generalFilterGroup(vslider("[06]Q [style:knob][tooltip: decay time]",1.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );
FB         = generalFilterGroup(vslider("[07]FB level [style:knob][tooltip: impulse volume]",0.25,0,1,0.001));
punchLevel = filterGroup(generalFilterGroup(vslider("[08]punch level   [style:knob][tooltip: punch level]",1,0,1,0.001)*-200));
clickLevel = (vslider("[09]click level  [style:knob][tooltip: click level  []",1,0,1,0.001)*4);
preGain    = generalFilterGroup(vslider("[10]pre sat gain [style:knob][tooltip: gain before saturation]",3,1,11,0.001)+3)/4:pow(3):smooth(0.999) ;
postGain   = generalFilterGroup(vslider("[11]post sat gain [style:knob][tooltip: gain after saturation]",11,0,11,0.001)/11:pow(2):smooth(0.999));


ambN = 1;
ambChan = ambN*2+1;


process =
drumSynth(2);

drumSynth(nrChan) = ((myNoises,(impulses(punchLevel))):>filterGroup(filter):(filterGroup(ampGroup(env)):par(i,ambChan,_'),impulses(clickLevel)):>universalDecoder(nrChan));

velBlock = lf_pulsetrainpos(0.5,0.1);

myNoises = multinoise(ambChan):(_*.6,bus(ambChan-1)):wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))));

impulses(level) = (velBlock-velBlock':max(0)*level),par(i,ambChan-1,0);

// with filter in the signal path , the first few ms. the synth is stereo, even when the width envelope should make it mono.
// todo: find out why.
filter = par(i, ambChan,((_+_:resonbp(freq,Q,1))~((_*FB):autoSat))*preGain:autoSat*postGain)
    with {
    freq = freqGroup(((startfreq-endfreq)*DSRenv(velBlock,decay,sustain,release))+endfreq: pianokey2hz);
    };

autoSat(x) = x:min(1):max(-1)<:2.0*_ * (1.0-abs(_)*0.5);

env = par(i,ambChan,DSRenv(velBlock,decay,sustain,release)*_);

Denv(velocity,decay) = (trigger-trigger':max(0):(+:min(_,velocity))~(_*decay_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    };

DRenv(velocity,decay,release) =
    trigger-trigger':max(0)
    :((+:min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = ((release:pow(0.03)/SR*44100)*0.01+0.99)*(trigger==0);
    };

DSRenv(velocity,decay,sustain,release) =
    trigger-trigger':max(0)
    :((+:max(sustain*velocity):min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = ((release:pow(0.03)/SR*44100)*0.01+0.99)*(trigger==0);
    };

universalDecoder(nrChan) = optimMaxRe(ambN):decoder(ambN,nrChan);

