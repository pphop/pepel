module pepel.module_.system;

import pepel.common;
import pepel.module_.module_;

class SystemModule : Module {

    this() {
        mixin(generateCommands!SystemModule);
    }

    @command("ping") NR ping(Message) {
        return NR(Response("pong"));
    }

    @command("test", User.Role.moderator) NR test(Message) {
        return NR(Response("you are a mod pog"));
    }
}
