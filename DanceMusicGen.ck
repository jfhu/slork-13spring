SinOsc si => ADSR e => NRev r => dac;
e.set(10::ms, 5::ms, 0.5, 50::ms);
 
//PercFlut s => dac;
PercFlut background1 => e => dac;//.chan(1);
PercFlut background2 => e => dac;//.chan(2);
PercFlut background3 => e => dac;//.chan(3);
Shakers sha => dac;

//BellSound bellSound;
//bellSound.SetGain(0);

1 => int progression;
0 => si.gain;
.5 => background1.gain;
.5 => background2.gain;
.5 => background3.gain;
//0 => s.gain;
        
3 => sha.gain;

3 => int beats_per_measure;
36 => int base;
1 => int chord;
0 => int offset;

spork ~ handleKB();
spork ~ handleTilt();
//spork ~ handleTP();

fun void handleKB() {
    //adc.chan(0) => s.chan(0);
    
    Hid hi;
    HidMsg msg;
    hi.openKeyboard(0);
    
    while (true) {
        hi => now;
        while (hi.recv(msg))
        {
            <<< msg.ascii >>>;
            if (msg.ascii == 65) {
                0 => offset;
            } else if (msg.ascii == 87) {
                1 => offset;
            } else if (msg.ascii == 83) {
                2 => offset;
            } else if (msg.ascii == 69) {
                3 => offset;
            } else if (msg.ascii == 68) {
                4 => offset;
            } else if (msg.ascii == 70) {
                5 => offset;
            } else if (msg.ascii == 84) {
                6 => offset;
            } else if (msg.ascii == 71) {
                7 => offset;
            } else if (msg.ascii == 89) {
                8 => offset;
            } else if (msg.ascii == 72) {
                9 => offset;
            } else if (msg.ascii == 85) {
                10 => offset;
            } else if (msg.ascii == 74) {
                11 => offset;
            //} else if (msg.ascii == 48) {
            //    if (s.gain() > 0)
            //        0 => s.gain;
            //    else if (s.gain() == 0)
            //        .5 => s.gain;
            } else if (msg.ascii == 49) {
                1 => progression;
            } else if (msg.ascii == 50) {
                2 => progression;
            } else if (msg.ascii == 51) {
                3 => progression;
            } else if (msg.ascii == 52) {
                4 => progression;
            }
            //hfStd.mtof(base + offset + 12) => s.freq;
        }
    }    
} 

fun void handleTP() {
    Hid hi;
    HidMsg msg;
    hi.openMouse(0);
    
    while(true) {
        hi => now;
        while(hi.recv(msg)){
            <<< msg.deltaX, msg.deltaY >>>;
            //msg.deltaX/10 => s.gain;
            msg.deltaX => float change;
            change/100 => change;
            
            background1.gain() + change => background1.gain;
            background2.gain() + change => background2.gain;
            background3.gain() + change => background3.gain;
            //background1.gain()*2 => s.gain;
        }
    }
}

fun void handleTilt()
{
    Hid hi;
    HidMsg msg;
    if (hi.openTiltSensor())
    {
        // Yay we got tilt sensor
        <<< "Tilt!" >>>;
        70.0 => float ythresh;
        -50.0 => float xthresh;
        0.0 => float lastx;
        0.0 => float lasty;
        7.0 => float lastthresh;
        while (true)
        {
            100::ms => now;
            hi.read(9,0,msg);
            
            <<< "x: ", msg.x, " y: ", msg.y, " z: ", msg.z >>>;
            msg.y => float change;
            (change/2000) + .1 => change;
            
            change => background1.gain;
            change => background2.gain;
            change => background3.gain;
            //if (s.gain() != 0)
            //    change + .5 => s.gain;
            <<<change>>>;


            //if (msg.x < xthresh) {
                //spork ~ bellSound.RingBell(Std.mtof(base+chord+23), 10.0);
                //spork ~playPercussion();
            //    1::second => now;
            //}
        }
    }
}

fun int new_chord(int chord) {
    if (progression == 1) {
        if (chord == 1)
            return 5;
        else if (chord == 3)
            return 8;
        else if (chord == 5)
            return 6;
        else if (chord == 6)
            return 12;
        else if (chord == 8)
            return 13;
        else if (chord == 10)
            return 3;
        else if (chord == 12)
            return 10;
        else if (chord == 13)
            return 1;
    } else if (progression == 2) {
        if (chord == 1)
            return 6;
        else if (chord == 6)
            return 8;
        else if (chord == 8)
            return 1;
        else 
            return 1;
    } else if (progression == 3) {
        if (chord == 1)
            return 10;
        else if (chord == 3)
            return 8;
        else if (chord == 8)
            return 13;
        else if (chord == 10)
            return 3;
        else if (chord == 12)
            return 8;
        else if (chord == 13)
            return 1;
    } else if (progression == 4) {
       if (chord == 1)
           return 3;
       else if (chord == 3)
           return 12;
       else if (chord == 5)
           return 1;
       else if (chord == 8)
           return 13;
       else if (chord == 10)
           return 8;
       else if (chord == 12)
           return 10;
       else if (chord == 13)
           return 5;
   }
}

fun void play_chord(int chord) {
       0 => int quality;
    if (chord == 3 || chord == 5 || chord == 10)
        1 => quality;
    else if (chord == 12)
        2 => quality;
    
    Std.mtof(base + chord + offset - 1) => background1.freq;
    
    if (quality == 0)
        Std.mtof(base + chord + offset + 3) => background2.freq;
    else 
        Std.mtof(base + chord + offset + 2) => background2.freq;  
    if (quality == 2)
        Std.mtof(base + chord + offset + 5) => background3.freq;
    else
        Std.mtof(base + chord + offset + 6) => background3.freq;

}

fun void playPercussion()
{
    //1 => sha.preset;

    5.0 => sha.noteOn;
    .1::second => now;

}

while (true) {
    play_chord(chord);
    //spork ~playPercussion();
    //Std.mtof(base + chord + offset + 8 - 1) => s.freq;
    for (0 => int i; i < beats_per_measure; i++) {
        e.keyOn;
        background1.gain() => float old_gain;
        Math.random2(1,4) => int count;
        count / 16.0 => float duration;
        duration::second => now;
    }
    new_chord(chord) => chord;
}