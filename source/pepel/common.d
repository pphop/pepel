module pepel.common;

import std.variant;

abstract class Gateway {
    Action[]delegate(ref Message) onMessage;

    void connect();
    void close();
}

alias Action = Algebraic!(Response, Whisper, Join, Leave);

struct Response {
    string text;
}

struct Whisper {
    User user;
    string text;
}

struct Join {
    string channel;
}

struct Leave {
    string channel;
}

struct Message {
    User sender;
    Channel channel;
    string text;
    bool handled;
    bool mentionedBot;

    string[] args() {
        import std.string : split;

        return text.split;
    }
}

abstract class Channel {
    string id();
}

abstract class User {
    enum Role {
        none,
        pleb,
        trusted,
        privileged,
        moderator,
        botowner
    }

    Role role;
    string username;

    string id();
    string mention();
}
