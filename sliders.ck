MAUI_Slider slider;
"param" => slider.name;
slider.display();
slider.range(0, 50);

//Blit s => dac;
//4 => s.harmonics;

//SinOsc si => ADSR e => NRev r => dac;
PercFlut background1 => ADSR e => dac;
e.set(10::ms, 5::ms, 0.5, 50::ms);
PercFlut background2 => e => dac;
PercFlut background3 => e => dac;

[2, 4, 5, 7, 9, 11] @=> int majProg0[];
[7, 11] @=> int majProg2[];
[2, 5, 9] @=> int majProg4[];
[0, 2, 7, 11] @=> int majProg5[];
[0, 9] @=> int majProg7[];
[2, 5] @=> int majProg9[];
[0, 7, 9] @=> int majProg11[];

36 => int base;
0 => int offset;
0 => int chord;
3 => int beats_per_measure;
0 => int final_cadence;

spork ~ handleKB();

fun void handleKB() {
    //adc.chan(0) => s.chan(0);
    
    Hid hi;
    HidMsg msg;
    hi.openKeyboard(0);
    
    while (true) {
        hi => now;
        while (hi.recv(msg))
        {
            if (msg.ascii == 48)
                1 => final_cadence;
            else if (msg.ascii == 32)
                start_music();
        }
    }
}

fun int new_chord(int chord) {
    Math.random2(1, 100) => int rand;
    if (chord == 0) 
        return majProg0[rand % majProg0.cap()];
    else if (chord == 2)
        return majProg2[rand % majProg2.cap()];
    else if (chord == 4)
        return majProg4[rand % majProg4.cap()];
    else if (chord == 5)
        return majProg5[rand % majProg5.cap()];
    else if (chord == 7)
        return majProg7[rand % majProg7.cap()];
    else if (chord == 9)
        return majProg9[rand % majProg9.cap()];
    else if (chord == 11)
        return majProg11[rand % majProg11.cap()];
    <<<chord>>>;
}

fun void play_chord(int chord) {
    0 => int root;
    4 => int third;
    7 => int fifth;
    if (chord == 2 || chord == 4 || chord == 9)  {
        3 => third;
    } else if (chord == 11) {
        3 => third;
        6 => fifth;
    }
    
    Math.random2(1, 3) => int inversion;
    
    if (inversion == 2) {
        root + 12 => root;
    }
    //if (inversion == 3) {
      //  root + 12 => root;
        //third + 12 => third;
    //}
           
    Std.mtof(base + chord + offset + root) => background1.freq;
    Std.mtof(base + chord + offset + third) => background2.freq;
    Std.mtof(base + chord + offset + fifth) => background3.freq;
}

fun void play_final_cadence()
{
    Std.mtof(base + 7 + offset) => background1.freq;
    Std.mtof(base + 7 + offset + 4) => background2.freq;
    Std.mtof(base + 7 + offset + 7) => background3.freq;
    1.2::second => now;
    
    Std.mtof(base + offset) => background1.freq;
    Std.mtof(base + offset + 4) => background2.freq;
    Std.mtof(base + offset + 12) => background3.freq;
    2.4::second => now;
}

fun void stop_music()
{
    set_gain(0);
    while (final_cadence == 1) {
        100::ms => now;
    }
}

fun void start_music()
{
    0 => chord;
    0 => final_cadence;
}

fun void set_gain(float gain)
{
    gain => background1.gain;
    gain => background2.gain;
    gain => background3.gain;
}

while (true) {
    play_chord(chord);
    //spork ~playPercussion();
    //Std.mtof(base + chord + offset + 8 - 1) => s.freq;
    for (0 => int i; i < beats_per_measure; i++) {
        e.keyOn;
        set_gain(slider.value()/10);
        //background1.gain() => float old_gain;
        //Math.random2(1,4) => int count;
        //count / 16.0 => float duration;
        //duration::second => now;
        .2::second => now;
    }
    new_chord(chord) => chord;
    if (chord == 2 && final_cadence == 1) {
        play_final_cadence();
        stop_music();
    }
}

