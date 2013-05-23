// sound file
me.sourceDir() + "/barnowl4.wav" => string filename;
if( me.args() ) me.arg(0) => filename;

// the patch 
SndBuf buf => ADSR env => NRev rev => dac;
// load the file
filename => buf.read;
.2 => rev.mix;
env.set(100::ms, 10000::ms, 0.9, 300::ms);
//attack, duration, sustain, retain

//1 79426ms
//2 67783ms
//3 3037ms, unedited
//4 3049ms, turn down vol
//5 27435ms
//6 73372, turn up vol

// time loop
while( true )
{
    0 => buf.pos;
    .5 => buf.gain;
    1 => buf.rate;
    1000::ms => now;
}