module pepel.platform.twitch.gateway;

import std.variant;

import d2sqlite3;

import pepel.config, pepel.common;
import pepel.platform.twitch.irc;
import pepel.platform.twitch.types;

final class TwitchGateway : Gateway {
private:
    IRCClient _irc;
    Config.Twitch _cfg;
    Database* _db;

public:
    this(ref Config.Twitch cfg, Database* db) {
        _cfg = cfg;
        _db = db;
        _irc.onPrivMsg = &onPrivMsg;

        _db.run("CREATE TABLE IF NOT EXISTS twitch_channels (
            id INTEGER PRIMARY KEY,
            channel TEXT NOT NULL
        )");
    }

    override void connect() {
        _irc.connect(_cfg, _db.retreiveChannels);
    }

    override void close() {
        _irc.close();
    }

    private void onPrivMsg(IRCMessage msg) {
        // TODO: proper logging
        import std.stdio : writefln;

        writefln("Twitch #%s @%s: %s", msg.channel, msg.user.displayName, msg.text);

        auto m = msg.toMsg(_cfg.owner, _cfg.username);
        auto actions = onMessage(m);

        // dfmt off
        foreach (a; actions)
            a.visit!((Response resp) => _irc.privMsg(msg.channel, resp.text),
                    (Whisper w) => _irc.whisper(w.user.username, w.text),
                    (Join j) { _db.addChannel(j.channel); _irc.join(j.channel); },
                    (Leave l) { _db.removeChannel(l.channel); _irc.part(l.channel); });
        // dfmt on
    }
}

private:

string[] retreiveChannels(Database* db) {
    string[] channels;

    auto rows = db.execute("SELECT channel FROM twitch_channels");
    foreach (row; rows)
        channels ~= row.peek!string(0);

    return channels;
}

void addChannel(Database* db, string channel) {
    db.execute("INSERT INTO twitch_channels (channel)
                SELECT :channel
                WHERE NOT EXISTS (SELECT 1 FROM twitch_channels WHERE channel = :channel)",
            channel);
}

void removeChannel(Database* db, string channel) {
    db.execute("DELETE FROM twitch_channels WHERE channel = :channel", channel);
}

Message toMsg(IRCMessage ircMsg, string botowner, string username) {
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
