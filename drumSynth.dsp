


import ("effect.lib");
import ("oscillator.lib");
import ("hoa.lib");

noiseGroup(x)  = (hgroup("[1]noise", x));
widthGroup(x)  = (hgroup("[2]width", x));
filterGroup(x) = (hgroup("[3]filter", x));
ampGroup(x)    = (hgroup("[4]amplitude", x));

decay   = (vslider("[1]decay [style:knob][tooltip: decay time]",0.1,0,1,0.001) );
sustain = (vslider("[2]sustain [style:knob][tooltip: sustain level]",0.4,0,1,0.001):pow(3):smooth(0.999) );
release = (vslider("[4]release [style:knob][tooltip: release time]",0.7,0,1,0.001) );
fc      = filterGroup(vslider("[5]OscFreq  [frequency of the synced oscilator as a Piano Key (PK) number (A440    = key 49)][style:knob]",  49,1,88,1) : pianokey2hz):smooth(0.999);
Q       = filterGroup(vslider("[6]Q [style:knob][tooltip: decay time]",1.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );

ambN = 1;
ambChan = ambN*2+1;


process =
drumSynth(2);

universalDecoder(nrChan) = optimMaxRe(ambN):decoder(ambN,nrChan);

drumSynth(nrChan) = myNoises:filter:ampGroup(env):universalDecoder(nrChan);

velBlock = lf_pulsetrainpos(0.5,0.1);

myNoises = multinoise(ambChan):(_*.6,bus(ambChan-1)):wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))));

filter = par(i, ambChan, resonbp(fc,Q,1));

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
    release_step = (release:pow(0.03)/SR*44100)*0.01+0.99*(trigger==0);
    };

DSRenv(velocity,decay,sustain,release) =
    trigger-trigger':max(0)
    :((+:max(sustain*velocity):min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = (release:pow(0.03)/SR*44100)*0.01+0.99*(trigger==0);
    };

