module pepel.module_.customcmd.handler;

import pepel.common;
import pepel.module_.module_;

Module.Command.Handler handler(string reply) {
    return (ref Message m) { return Response(reply).Action; };
}
