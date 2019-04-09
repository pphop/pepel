module pepel.common;

abstract class Gateway {
    protected void delegate(Message) _onMessage;

    @property final void onMessage(void delegate(Message) hand) {
        _onMessage = hand;
    }

    void connect();
    void reply(Message, Response);

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

abstract class Message {
    User sender;
    string text;
    bool handled;
    bool mentionedBot;

    final @property string[] args() {
        import std.string : split;

        return text.split;
    }

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
    string mention();
}
