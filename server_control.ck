// server_control.ck
// Responsible for sending charactors to the clients
//
// usage:
// chuck server_control.ck
// default port: 51000

[
    "localhost",
    "localhost",
    "localhost"
] @=> string hostlist[];

[
    50001,
    50002,
    50003
] @=> int port[];

/* prepare OSC send */
OscSend osc_send[hostlist.cap()];
for (0 => int i; i < hostlist.cap(); i++) {
    osc_send[i].setHost(hostlist[i], port[i]);
}

/* prepare keyboard */
0 => int keyboard_device_num;
Hid hid;
HidMsg hid_msg;
if ( hid.openKeyboard( keyboard_device_num ) == 0) me.exit();
<<< "Keyboard: ", hid.name() >>>;

/* keyboard event loop */
fun void keyboard_loop() {
    while (true) {
        hid => now;
        while (hid.recv(hid_msg)) {
            if (hid_msg.isButtonDown()) {
                for (0 => int i; i < hostlist.cap(); i++) {
                    osc_send[i].startMsg("play", "i");
                    hid_msg.ascii => osc_send[i].addInt;
                }
            }
        }
    }
}
spork ~ keyboard_loop();

<<< "Server controller started.", "" >>>;
while ( true ) 5::minute => now;

