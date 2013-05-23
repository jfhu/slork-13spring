// server_print.ck
// Responsible for printing sentences sent by clients.
//
// usage:
// chuck server.ck[:port]
// default port: 51000

/* prepare OSC */
OscRecv recv;
51000 => recv.port;
if ( me.args() ) me.arg(0) => Std.atoi => recv.port;
recv.listen();

/* storing all incoming sentences */
200 => int MAX_CLIENT_ID;
string sentence[200];
for (0 => int i; i < MAX_CLIENT_ID; i++) "" => sentence[i];

/* remember client names */
string client_names[MAX_CLIENT_ID];
for (0 => int i; i < MAX_CLIENT_ID; i++) "noname" => client_names[i];

/* dealing with client names */
fun void client_name_recv_loop() {
    recv.event("name, i s") @=> OscEvent oe;
    string buf;
    int cid;
    while ( true ) {
        oe => now;
        while ( oe.nextMsg() != 0 ) {
            oe.getInt() => cid;
            oe.getString() => client_names[cid];
            <<< "Client", cid, "joins with name", client_names[cid] >>>;
        }
    }
}
spork ~ client_name_recv_loop();

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
                <<< "[", client_names[cid], "]: ", sentence[cid] >>>;
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

