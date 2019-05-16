module pepel.common;

abstract class Gateway {
    protected Response[]delegate(ref Message) _onMessage;

    final void onMessage(Response[]delegate(ref Message) hand) {
        _onMessage = hand;
    }

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
