


import ("effect.lib");
import ("oscillator.lib");

noiseGroup(x)  = (hgroup("[1]noise", x));
filterGroup(x) = (hgroup("[2]filter", x));
ampGroup(x)    = (hgroup("[3]amplitude", x));

decay   = ampGroup(vslider("[1]decay [style:knob][tooltip: decay time]",0.1,0,1,0.001) );
sustain = ampGroup(vslider("[2]sustain [style:knob][tooltip: sustain level]",0.4,0,1,0.001):pow(3):smooth(0.999) );
release = ampGroup(vslider("[4]release [style:knob][tooltip: release time]",0.7,0,1,0.001) );
fc      = filterGroup(vslider("[5]OscFreq  [frequency of the synced oscilator as a Piano Key (PK) number (A440    = key 49)][style:knob]",  49,1,88,1) : pianokey2hz):smooth(0.999);
Q       = filterGroup(vslider("[6]Q [style:knob][tooltip: decay time]",1.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );


process =
drumSynth(2);

drumSynth(nrChan) = multinoise(nrChan):filter(nrChan):env(nrChan, lf_pulsetrainpos(0.5,0.1));

env(nrChan,velocity) = par(i,nrChan,DSRenv(velocity,decay,release)*_);

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

DSRenv(velocity,decay,release) =
    trigger-trigger':max(0)
    :((+:max(sustain*velocity):min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = (release:pow(0.03)/SR*44100)*0.01+0.99*(trigger==0);
    };

filter(nrChan) = par(i, nrChan, resonbp(fc,Q,1));

