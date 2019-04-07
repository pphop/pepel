module pepel.platform.twitch.irc.message;

import std.regex;

struct IRCMessage {
    enum Type {
        unknown,
        privmsg,
        whisper,
        ping
    }

    struct User {
        enum Type {
            pleb,
            subscriber,
            //vip,
            moderator,
            broadcaster
        }

        Type type;
        string username, displayName;
    }

    Type type;
    User user;
    string channel;
    string text;
    string raw;
}

IRCMessage parseMessage(string line) {
    import std.conv : text;
    import std.string : toUpper;
    import std.traits : EnumMembers;

    IRCMessage msg;
    msg.raw = line;

    // doesnt cover every message type but good enough for now
    static immutable typeRegex = regex("[A-Z]{3,}");

    auto m = line.matchFirst(typeRegex);

    if (!m)
        return msg;

    auto t = m.hit;

    // dfmt off
    sw: switch (t) {
        static foreach (e; EnumMembers!(IRCMessage.Type)[1 .. $]) {
            case e.text.toUpper:
                msg.type = e;
                break sw;
        }
    default:
    }
    // dfmt on

    final switch (msg.type) {
    case IRCMessage.Type.unknown:
    case IRCMessage.Type.ping:
    case IRCMessage.Type.whisper:
        return msg;
    case IRCMessage.Type.privmsg:
        parsePrivMsg(msg);
    }
    return msg;
}

private:

void parsePrivMsg(ref IRCMessage msg) {
    static immutable r = regex(
            r"^(?:@(?P<tags>[^ ]+) +)?(?::(?P<username>[^!]+)[^ ]+ +)?[A-Z]+ +#(?P<channel>[^ ]+) +:(?P<text>.+)$");
    auto m = msg.raw.matchFirst(r);

    if (!m) {
        //TODO: log but this shouldnt happen
        return;
    }

    msg.user.username = m["username"];
    msg.channel = m["channel"];
    msg.text = m["text"];

    msg.parseTags(m["tags"]);
}

void parseTags(ref IRCMessage msg, string tagsRaw) {
    import std.string : split;

    foreach (tag; tagsRaw.split(";")) {
        auto kv = tag.split("=");

    sw:
        switch (kv[0]) {
        case "display-name":
            msg.user.displayName = kv[1];
            break sw;
        case "badges":
            msg.parseBadges(kv[1]);
            break sw;
        default:
        }
    }
}

void parseBadges(ref IRCMessage msg, string rawBadges) {
    import std.algorithm : findSplitBefore, map;
    import std.conv : text;
    import std.string : split;
    import std.traits : EnumMembers;

    foreach (badge; rawBadges.split(",").map!(a => a.findSplitBefore("/")[0])) {
        // dfmt off
        sw: switch (badge) {
            static foreach (e; EnumMembers!(IRCMessage.User.Type)[1 .. $]) {
                case e.text:
                    msg.user.type = e;
                    break sw;
            }
        default:
        }
        // dfmt on
    }
}
