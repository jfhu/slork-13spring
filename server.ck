// server.ck
//
// usage:
// chuck server.ck[:port]
// default port: 6449

/* prepare OSC */
OscRecv recv;
6449 => recv.port;
if ( me.args() ) me.arg(0) => Std.atoi => recv.port;
recv.listen();

/* storing all incoming sentences */
200 => int MAX_CLIENT_ID;
string sentence[200];
for (0 => int i; i < MAX_CLIENT_ID; i++) "" => sentence[i];

/* OSC event loop */
fun void osc_loop() {
    recv.event("char, i s") @=> OscEvent oe;
    string buf;
    int cid;
    while ( true ) {
        oe => now;
        while ( oe.nextMsg() != 0 ) {
            oe.getInt() => cid;
            oe.getString() => buf;
            if (buf == "\n") { // Enter key pressed
                // TODO: print the sentence[cid] here with a system() call
                <<< "From client ", cid, ": ", sentence[cid] >>>;
                "" => sentence[cid];
            } else {
                sentence[cid] + buf => sentence[cid];
            }
        }
    }
}
spork ~ osc_loop();

<<< "Server started.", "" >>>;
while ( true ) 5::minute => now;

