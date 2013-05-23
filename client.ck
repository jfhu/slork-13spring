// client.ck
//
// usage:
// chuck client.ck[:client_id[:server host[:port]]]
// default server: localhost:51000
// client id will be randomized if not given

"localhost" => string defaultServer;

/* prepare client id */
200 => int MAX_CLIENT_ID;
int cid;
if ( !me.args() ) {
    Math.random2(0, MAX_CLIENT_ID-1) => cid;
} else {
    me.arg(0) => Std.atoi => cid;
}
<<< "Client ID: ", cid >>>;

/* prepare keyboard */
0 => int keyboard_device_num;
Hid hid;
HidMsg hid_msg;
if ( hid.openKeyboard( keyboard_device_num ) == 0) me.exit();
<<< "Keyboard: ", hid.name() >>>;


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


/* prepare OSC send */
defaultServer => string hostname;
51000 => int port;
if ( me.args() > 1 ) me.arg(1) => hostname;
if ( me.args() > 2 ) me.arg(2) => Std.atoi => port;
OscSend osc_send;
osc_send.setHost( hostname, port );
<<< "Connecting to server ", hostname, ":", port >>>;

/* Set the client name */
<<< "Please", "enter a name:" >>>;
"" => string client_name;
0 => int should_break;
while (true) {
    if (should_break) break;
    hid => now;
    while (hid.recv(hid_msg)) {
        if (hid_msg.isButtonDown()) {
            if (hid_msg.ascii == 10) {
                <<< "Sending", client_name >>>;
                osc_send.startMsg("name", "i s");
                cid => osc_send.addInt;
                client_name => osc_send.addString;
                1 => should_break;
                break;
            }
            client_name + ascii_to_str(hid_msg.ascii) => client_name;
        }
    }
}
<<< "...","..." >>>;

/* prepare OSC recv */
OscRecv osc_recv;
50000 + cid => osc_recv.port;
osc_recv.listen();
<<< "Listening on port: ", 50000+cid >>>;

/* Play typewriter keystroke */
200.0 => float base_freq;
[
    "sample/typewriter/unknown_1/key.wav"
] @=> string key_sounds[];
Math.random2(0, key_sounds.cap() - 1) => int key_sound_indx;
<<< "Using key sound", key_sound_indx >>>;
fun void play_keystroke(int ascii) {
    ascii => Std.mtof => float freq;
    freq / base_freq => float rate;
    SndBuf buf => dac;
    key_sounds[key_sound_indx] => buf.read;
    rate => buf.rate;
    0 => buf.pos;
    buf.length() => now;
}

[
    "camera-shutter-click-07.wav",
    "car-beeping-2.wav",
    "clong-2.wav",
    "glass-clink-3.wav",
    "hammering-2.wav",
    "phone-hang-up-2b.wav",
    "pot-lid-1.wav",
    "rotary-phone-1-nr8.wav"
] @=> string enter_sound[];
cid % enter_sound.cap() => int enter_sound_indx;
fun void play_enter() {
    SndBuf buf => dac;
    "sample/enter_key/" + enter_sound[enter_sound_indx] => buf.read;
    0 => buf.pos;
    5 => buf.gain;
    buf.length() => now;
}

fun void play_space() {
    SndBuf buf => dac;
    "sample/typewriter/unknown_1/space-bar.wav" => buf.read;
    45000 => buf.pos;
    5 => buf.gain;
    buf.length() => now;
}

/* keyboard event loop */
/* sends keystrokes to server for printing */
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

                /* number keys control which enter key sound to play */
                if (hid_msg.ascii <= 57 && hid_msg.ascii >= 48) {
                    hid_msg.ascii => int k;
                    if (k == 48) 58 => k;
                    /* 0 == 48, 9 == 57 */
                    ((k - 49) + enter_sound.cap()) % enter_sound.cap() => enter_sound_indx;
                    <<< "Switched to enter key sound: ", enter_sound_indx >>>;
                }

                /* Play sound with different keys */
                if (hid_msg.ascii == 10) {
                    // Enter Key
                    spork ~ play_enter();
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

/* osc event loop */
/* receives characters from server and play the sound */
fun void osc_recv_loop() {
    osc_recv.event("play, i") @=> OscEvent oe;
    int buf;
    while ( true ) {
        oe => now;
        while ( oe.nextMsg() != 0 ) {
            oe.getInt() => buf;
            <<< "Received: ", buf >>>;
            spork ~ play_keystroke(buf);
        }
    }
}
spork ~ osc_recv_loop();


<<< "Client started.", "" >>>;
while (true) 5::minute => now;

