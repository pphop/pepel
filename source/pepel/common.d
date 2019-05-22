module pepel.common;

abstract class Gateway {
    Response[]delegate(ref Message) onMessage;

    void connect();
    void close();

    /*
    void join(string meme);
    void leave(string meme);
    */
}

struct Response {
    enum Type {
        chatroom,
        dm
    }

    string text;
    Type type;
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
