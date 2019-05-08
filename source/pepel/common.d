module pepel.common;

abstract class Gateway {
    protected void delegate(ref Message) _onMessage;

    @property final void onMessage(void delegate(ref Message) hand) {
        _onMessage = hand;
    }

    void connect();
    void reply(ref Message, Response);

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

    @property string[] args() {
        import std.string : split;

        return text.split;
    }
}

abstract class Channel {
    @property string id();
}

abstract class User {
    enum Role {
        pleb,
        trusted,
        privileged,
        moderator,
        botowner
    }

    Role role;
    string username;

    @property string id();
    string mention();
}
