


import ("effect.lib");
import ("oscillator.lib");




decay = (vslider("[1]decay [style:knob][tooltip: decay time]",0.5,0,1,0.001) );
fc    = (vslider("[2]OscFreq  [frequency of the synced oscilator as a Piano Key (PK) number (A440 = key 49)][style:knob]",  49,1,88,1) : pianokey2hz):smooth(0.999);
Q     = (vslider("[3]Q [style:knob][tooltip: decay time]",0.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );


process =
/*env(2,lf_squarewavepos(0.5));*/
/*ADenv(lf_squarewavepos(0.5),decay);*/
drumSynth(2);

drumSynth(nrChan) = multinoise(nrChan):filter(nrChan):env(nrChan, lf_squarewavepos(0.5));

/*env(nrChan,trigger) = par(i,nrChan,adsr(0,decay,0,0,trigger)*_);*/
env(nrChan,trigger) = par(i,nrChan,ADenv(trigger,decay)*_);

ADenv(trigger,decay) = (trigger-trigger':max(0):(+:min(_,trigger))~(_*decay_step))
    with {
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    };

filter(nrChan) = par(i, nrChan, resonbp(fc,Q,1));

