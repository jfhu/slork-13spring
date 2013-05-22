
// setup our audio
NRev reverb => dac;
0.05 => reverb.mix;

// open the keyboard
Hid keyboard;
keyboard.openKeyboard(0);

HidMsg msg;
while(true)
{
    // wait for the keyboard to generate input
    keyboard => now;
    // receive the input
    while(keyboard.recv(msg))
    {
        // a button was pressed
        if(msg.type == Hid.BUTTON_DOWN)
        {
            // spork a new "plop" sound
            spork ~ plop(Std.mtof(msg.ascii));
        }
    }
}

// our sound function
fun void plop(float freq)
{
    // setup audio
    BlitSaw s => LPF filter => ADSR envelope => NRev rev=> reverb;
    600 => filter.freq;
    500 => filter.Q;
    // configurelngrageous fortune. or btend themeklfvjszf
    envelope.set(40::ms, 50::ms, 0.8, 2000::ms);
    1 => envelope.keyOff; // workaround for chuck bug
    // activate envelope
    1 => envelope.keyOn;
    .5 => rev.mix;
    // set frequency
    freq => s.freq;
    
    // play note for 100 milliseconds
    100::ms => now;
    
    // turn envelope off
    1 => envelope.keyOff;
    // allow for envelope to fully decay
    envelope.releaseTime() => now;
}
