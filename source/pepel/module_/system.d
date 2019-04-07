module pepel.module_.system;

import pepel.common;
import pepel.module_.module_;

class SystemModule : Module {

    mixin(generateCommands!SystemModule);

    @trigger("ping") nr ping(Message) {
        return nr(Response("pong"));
    }

    @reqRole(User.Role.moderator) @trigger("test") nr test(Message) {
        return nr(Response("you are a mod pog"));
    }
}
