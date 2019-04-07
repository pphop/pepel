module pepel.common;

interface Gateway {
    void connect();
    @property void onMessage(void delegate(Message));
    void reply(Message, Response);

    /*
    void join(string meme);
    void leave(string meme);
    */
}

mixin template onMessageProperty() {
    private void delegate(Message) _onMessage;

    public @property void onMessage(void delegate(Message) handler) {
        _onMessage = handler;
    }
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
