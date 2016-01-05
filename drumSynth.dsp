


import ("effect.lib");
import ("oscillator.lib");
import ("hoa.lib");

noiseGroup(x)              = (hgroup("[1]noise", x));
widthGroup(x)              = (hgroup("[2]width", x));
filtersGroup(x)            = (tgroup("[3]filters", x));
    filterGroup(filterIndex,x) = filtersGroup(vgroup("[%filterIndex]filter %filterIndex", x));
    freqGroup(x)               = (hgroup("[1]frequency", x));
    noiseFreqGroup(x)          = (hgroup("[2]noise frequency", x));
    generalFilterGroup(x)      = (hgroup("[3]general", x));
    ampGroup(x)                = (hgroup("[4]amplitude", x));
OnGroup(x)            = (hgroup("[4]filter on/off", x));
    On(i)             = OnGroup(checkbox("[%i]On %i"));

decay                   = (vslider("[01]decay [style:knob][tooltip: decay time]",0.1,0,1,0.001) );
sustain                 = (vslider("[02]sustain [style:knob][tooltip: sustain level]",0.4,0,1,0.001):pow(3):smooth(0.999) );
release                 = (vslider("[03]release [style:knob][tooltip: release time]",0.7,0,1,0.001) );
startfreq               = (vslider("[04]start freq  [start frequency of the filter as a Piano Key (PK) number (A440 = key 49)][style:knob]",  42,1,88,1) ):smooth(0.999);
endfreq                 = (vslider("[05]end freq  [end frequency of the filter as a Piano Key (PK) number (A440 = key 49)][style:knob]",  35,1,88,1) ):smooth(0.999);
Q                       = generalFilterGroup(vslider("[06]Q [style:knob][tooltip: decay time]",1.5,0,8,0.001):pow(2)+0.2:smooth(0.999) );
FB                      = generalFilterGroup(vslider("[07]FB level [style:knob][tooltip: impulse volume]",0.25,0,1,0.001));
punchLevel(filterIndex) = filterGroup(filterIndex,(generalFilterGroup(vslider("[08]punch level   [style:knob][tooltip: punch level]",1,0,1,0.001)*-200)));
clickLevel              = (vslider("[09]click level  [style:knob][tooltip: click level  []",1,0,1,0.001)*4);
preGain                 = generalFilterGroup(vslider("[10]pre sat gain [style:knob][tooltip: gain before saturation]",3,1,11,0.001)+3)/4:pow(3):smooth(0.999) ;
postGain                = generalFilterGroup(vslider("[11]post sat gain [style:knob][tooltip: gain after saturation]",11,0,11,0.001)/11:pow(2):smooth(0.999));


ambN = 1;
ambChan = ambN*2+1;
nrFilters=4;

process =
/*zita_rev1;*/
/*sawNoise(startfreq,sustain*50)*/
/*<:bus(2)*/
/*;*/
drumSynth(2);

drumSynth(nrChan) =
par(filterI,nrFilters,((myNoises(filterI),(impulses(punchLevel(filterI)))):>filterGroup(filterI,filter):(filterGroup(filterI,ampGroup(env)))):Ons(filterI))
    :>(par(i,ambChan,_'),impulses(clickLevel)) :>wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))):pow(3)):universalDecoder(nrChan)
    with {
    Ons(filterI) = par(i,ambChan,_*On(filterI));
    };

drumSynthAmb(nrChan) =
par(filterI,nrFilters,
    ((myNoises(filterI),(impulses(punchLevel(filterI)))):>filterGroup(filterI,filter):(filterGroup(filterI,ampGroup(env)))):Ons(filterI)
    )
:>(par(i,ambChan,_'),impulses(clickLevel)) :>wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))):pow(3)):universalDecoder(nrChan)
    with {
    Ons(filterI) = par(i,ambChan,_*On(filterI));
    };

velBlock = lf_pulsetrainpos(0.5,0.1);

myNoises(noiseIndex) =
    par(i,ambChan,sawNoise(freqEnv(noiseIndex) ,noises(ambChan,i)))
    :(_*.6,bus(ambChan-1))
    with {
    freqEnv(i) = filterGroup(i,noiseFreqGroup(((startfreq-endfreq)*DSRenv(velBlock,decay,sustain,release))+endfreq: pianokey2hz));
    };
/*myNoises = (sawNoise(endfreq,33),multinoise(ambChan-1)):wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))));*/
/*myNoises = multinoise(ambChan):(_*.6,bus(ambChan-1)):wider(ambN,(1-widthGroup(DSRenv(velBlock,decay,sustain,release))));*/


sawNoise(freq,noise) = (((((_,periodsamps : fmod :abs) ~ +(1.0+(33*noise)))/periodsamps)*2-1):cos:dcblockerat(freq))*3
/*sawNoise(freq,noisyness) = ((((_,periodsamps : fmod :abs) ~ +(1.0+(noisyness*noise)))/periodsamps)*2-1):abs*2-1*/
with {
  periodsamps = float(ml.SR)/(freq*2); // period in samples (not nec. integer)
};

impulses(level) = (velBlock-velBlock':max(0)*level),par(i,ambChan-1,0);

// with filter in the signal path , the first few ms. the synth is stereo, even when the width envelope should make it mono.
// todo: find out why.
filter = par(i, ambChan,((_+_:resonbp(freq,Q,1))~((_*FB):autoSat))*preGain:autoSat*postGain)
    with {
    freq = freqGroup(((startfreq-endfreq)*DSRenv(velBlock,decay,sustain,release))+endfreq: pianokey2hz);
    };

autoSat(x) = x:min(1):max(-1)<:2.0*_ * (1.0-abs(_)*0.5);

env = par(i,ambChan,DSRenv(velBlock,decay,sustain,release)*_);

trigger(velocity) = (velocity>0)-(velocity>0)':max(0);

Denv(velocity,decay) = (trigger(velocity):(+:min(_,velocity))~(_*decay_step))
    with {
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    };

DRenv(velocity,decay,release) =
    trigger(velocity)
    :((+:min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = ((release:pow(0.03)/SR*44100)*0.01+0.99)*(velocity==0);
    };

DSRenv(velocity,decay,sustain,release) =
    trigger(velocity)
    :((+:max(sustain*velocity):min(velocity))
    ~(_*decay_step))
    :(+~(_*release_step))
    with {
    decay_step = (decay:pow(0.03)/SR*44100)*0.01+0.99;
    release_step = ((release:pow(0.03)/SR*44100)*0.01+0.99)*(velocity==0);
    };

universalDecoder(nrChan) =
/*bus(ambChan);*/
optimMaxRe(ambN):decoder(ambN,nrChan);

