module pepel.platform.twitch.types;

import pepel.common;

final class TwitchChannel : Channel {

    string _name;

    this(string name) {
        _name = name;
    }

    override @property string id() {
        return _name;
    }
}

final class TwitchUser : User {

    // maybe use actual twitch user id
    override @property string id() {
        return username;
    }

    override string mention() {
        import std.format : format;

        return "@%s".format(username);
    }
}
