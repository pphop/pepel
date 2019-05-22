module pepel.platform.twitch.gateway;

import pepel.config, pepel.common;
import pepel.platform.twitch.irc;
import pepel.platform.twitch.types;

final class TwitchGateway : Gateway {
private:
    IRCClient _irc;
    Config.Twitch _cfg;

public:
    this(ref Config.Twitch cfg) {
        _cfg = cfg;
        _irc.onPrivMsg = &onPrivMsg;
    }

    override void connect() {
        _irc.connect(_cfg);
    }

    override void close() {
        _irc.close();
    }

    private void onPrivMsg(IRCMessage msg) {
        // TODO: proper logging
        import std.stdio : writefln;

        writefln("Twitch #%s @%s: %s", msg.channel, msg.user.displayName, msg.text);

        auto m = msg.toMsg(_cfg.owner, _cfg.username);
        auto responses = onMessage(m);

        foreach (resp; responses) {
            final switch (resp.type) {
            case Response.Type.chatroom:
                _irc.privMsg(msg.channel, resp.text);
                break;
            case Response.Type.dm:
                _irc.whisper(msg.user.username, resp.text);
                break;
            }
        }
    }
}

private Message toMsg(IRCMessage ircMsg, string botowner, string username) {
    import std.algorithm : canFind;

    auto msg = Message();

    msg.sender = new TwitchUser();

    if (ircMsg.user.username == botowner) {
        msg.sender.role = User.Role.botowner;
    }
    else {
        final switch (ircMsg.user.type) {
        case IRCMessage.User.Type.pleb:
            break;
        case IRCMessage.User.Type.subscriber:
            msg.sender.role = User.Role.privileged;
            break;
        case IRCMessage.User.Type.moderator:
        case IRCMessage.User.Type.broadcaster:
            msg.sender.role = User.Role.moderator;
            break;
        }
    }

    msg.sender.username = ircMsg.user.username;
    msg.channel = new TwitchChannel(ircMsg.channel);
    msg.text = ircMsg.text;
    msg.mentionedBot = ircMsg.text.canFind(username);

    return msg;
}
