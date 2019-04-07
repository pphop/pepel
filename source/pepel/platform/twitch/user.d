module pepel.platform.twitch.user;

import pepel.common;

class TwitchUser : User {
    override string mention() {
        import std.format : format;

        return "@%s".format(username);
    }
}
