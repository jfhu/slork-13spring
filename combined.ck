// client.ck
//
// usage:
// chuck client.ck[:cliend_id[:server host[:port]]]
// default server: localhost:6449
// client id will be randomized if not given

/* prepare client id */
200 => int MAX_CLIENT_ID;
int cid;
if ( !me.args() ) {
    Math.random2(0, MAX_CLIENT_ID-1) => cid;
} else {
    me.arg(0) => Std.atoi => cid;
}

/* prepare keyboard */
0 => int keyboard_device_num;
Hid hid;
HidMsg hid_msg;
if ( hid.openKeyboard( keyboard_device_num ) == 0) me.exit();
<<< "Keyboard: ", hid.name() >>>;


/* prepare OSC */
"localhost" => string hostname;
6449 => int port;
if ( me.args() > 1 ) me.arg(1) => hostname;
if ( me.args() > 2 ) me.arg(2) => Std.atoi => port;
OscSend osc_send;
osc_send.setHost( hostname, port );

/* ascii (0-127) -> string mapping of printable chars */
[
    "", "", "", "", "", "", "", "", "", "\t", "\n", "", "", "", "", "", // 0-15
    "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", // 16-31
    " ", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", // 32-47
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", // 48-63
    "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", // 64-79
    "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", // 80-95
    "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", // 96-111
    "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "" // 112-127
] @=> string ascii_map[];

fun string ascii_to_str(int ascii) {
    return ascii_map[ascii];
}


0 => int instrument_indx;

[
    "sample/crickets/cricket_high.wav",
    "sample/rain_thunder/rain_high.wav",
    "sample/water/water_droplet_2.wav"
] @=> string keystroke_high[];
[
    "sample/crickets/cricket_low.wav",
    "sample/rain_thunder/rain_low.wav",
    "sample/water/water_droplet_2.wav"
] @=> string keystroke_low[];
/* Play typewriter keystroke */
200.0 => float base_freq;
fun void play_keystroke(int ascii) {
    ascii => Std.mtof => float freq;
    freq / base_freq => float rate;
    SndBuf buf => ADSR env => dac;
    env.set(30::ms, 50::ms, .1, 50::ms);
    Math.random2(0,1) => int rand;
    if (rand == 0)
        keystroke_high[instrument_indx] => buf.read;
    else
        keystroke_low[instrument_indx] => buf.read;
    //rate => buf.rate;
    5 => buf.gain;
    0 => buf.pos;
    buf.length() => now;
}

[
    "sample/crickets/cicada.wav",
    "sample/rain_thunder/thunder_high.wav",
    "sample/water/water_droplet_2.wav"
] @=> string forward[];
fun void play_forward() {
    SndBuf buf => ADSR env => dac;
    env.set(30::ms, 50::ms, .1, 50::ms);
    forward[instrument_indx] => buf.read;
    0 => buf.pos;
    5 => buf.gain;
    buf.length() => now;
}

[
    "sample/crickets/bat_chirp.wav",
    "sample/rain_thunder/thunder_low.wav",
    "sample/water/water_droplet_1.wav"
] @=> string space[];
fun void play_space() {
    SndBuf buf => ADSR env => dac;
    env.set(30::ms, 50::ms, .1, 50::ms);
    space[instrument_indx] => buf.read;
    0 => buf.pos;
    5 => buf.gain;
    buf.length() => now;
}

/* keyboard event loop */
fun void keyboard_loop() {
    while (true) {
        hid => now;
        while (hid.recv(hid_msg)) {
            if (hid_msg.isButtonDown()) {
                // <<< "down:", hid_msg.which, "(code)", hid_msg.key, "(usb key)", hid_msg.ascii, "(ascii)" >>>;
                // FIXME: doesn't handle modifier keys, doesn't have lowercase letters
                osc_send.startMsg("char", "i s");
                // <<< ascii_to_str(hid_msg.ascii) >>>;
                cid => osc_send.addInt;
                ascii_to_str(hid_msg.ascii) => osc_send.addString;

                /* switch sounds */
                if (hid_msg.which >= 58 && hid_msg.which <= 63) {
                    (hid_msg.which - 58) % keystroke_high.cap() => instrument_indx;
                    <<< "Switching to instrument", instrument_indx >>>;
                }

                /* Play sound with different keys */
                if (hid_msg.ascii == 10) {
                    // Enter Key
                    spork ~ play_forward();
                } else if (hid_msg.ascii == 32) {
                    // Space Key
                    spork ~ play_space();
                } else {
                    spork ~ play_keystroke(hid_msg.ascii);
                }
            }
        }
    }
}
spork ~ keyboard_loop();

<<< "Client started with cid = ", cid >>>;
while (true) 5::minute => now;

