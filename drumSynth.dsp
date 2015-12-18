


import ("effect.lib");
import ("oscillator.lib");




decay = (vslider("[1]decay [style:knob][tooltip: decay time]",0.5,0,1,0.001) );
release = (vslider("[1]release [style:knob][tooltip: release time]",0.5,0,1,0.001) );
fc    = (vslider("[2]OscFreq  [frequency of the synced oscilator as a Piano Key (PK) number (A440 = key 49)][style:knob]",  49,1,88,1) : pianokey2hz):smooth(0.999);
Q     = (vslider("[3]Q [style:knob][tooltip: decay time]",0.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );


process =
drumSynth(2);

drumSynth(nrChan) = multinoise(nrChan):filter(nrChan):env(nrChan, lf_pulsetrainpos(0.5,0.01));

env(nrChan,velocity) = par(i,nrChan,DRenv(velocity,decay,release)*_);

Denv(velocity,decay) = (trigger-trigger':max(0):(+:min(_,velocity))~(_*decay_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    };

DRenv(velocity,decay,release) =
    trigger-trigger':max(0)
    :((+:min(_,velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    trigger = velocity>0;
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = (release:pow(0.03)/SR*44100)*0.01+0.99*(trigger==0);
    };

filter(nrChan) = par(i, nrChan, resonbp(fc,Q,1));

