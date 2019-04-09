module pepel.platform.twitch.gateway;

import pepel.config, pepel.common;
import pepel.platform.twitch.irc, pepel.platform.twitch.message, pepel.platform.twitch.user;

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
        _irc.connect(_cfg.username, _cfg.token);
        _irc.join(_cfg.channels);
    }

    override void reply(Message m, Response res) {
        // there has to be a better way
        auto msg = cast(TwitchMessage) m;

        final switch (res.type) {
        case Response.Type.chatroom:
            _irc.privMsg(msg.channel, res.text);
            break;
        case Response.Type.dm:
            _irc.whisper(msg.sender.username, res.text);
            break;
        }
    }

    private void onPrivMsg(IRCMessage msg) {
        _onMessage(msg.toMsg(_cfg.owner, _cfg.username));
    }
}

private TwitchMessage toMsg(IRCMessage ircMsg, string botowner, string username) {
    import std.algorithm : canFind;

    auto msg = new TwitchMessage();
    msg.text = ircMsg.text;
    msg.channel = ircMsg.channel;

    msg.sender = new TwitchUser();
    msg.sender.username = ircMsg.user.displayName;
    final switch (ircMsg.user.type) {
    case IRCMessage.User.Type.pleb:
        break;
    case IRCMessage.User.Type.subscriber:
        msg.sender.role = User.Role.privileged;
        break;
    case IRCMessage.User.Type.moderator:
        msg.sender.role = User.Role.moderator;
        break;
    case IRCMessage.User.Type.broadcaster:
        msg.sender.role = User.Role.moderator;
        break;
    }

    if (ircMsg.user.username == botowner)
        msg.sender.role = User.Role.botowner;

    if (msg.text.canFind(username))
        msg.mentionedBot = true;

    return msg;
}
