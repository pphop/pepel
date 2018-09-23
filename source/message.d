module pepel.message;

import pepel.internal;

immutable(TwitchMessage) parseMessage(const string rawLine) {
    import std.algorithm : filter;
    import std.conv : to;
    import std.regex : matchFirst, regex;
    import std.traits : EnumMembers;
    import std.uni : toLower;

    TwitchMessage ret;
    static msgTypeRegex = regex(r"(?P<type>[A-Z]{4,})");
    auto matched = rawLine.matchFirst(msgTypeRegex);
    if (!matched) {
        //log
        ret = UnknownMessage(rawLine);
        return ret;
    }

    immutable msgType = matched["type"];

sw:
    switch (msgType.toLower) {
        static foreach (type; [EnumMembers!MessageType].filter!(a => a != MessageType.unknown)) {
    case type.to!string:
            ret = mixin(type ~ "(rawLine)");
            break sw;
        }
    default:
        ret = UnknownMessage(rawLine);
    }

    return ret;
}

private struct tag {
    string name;
}

//todo: @msgtype the messages instead of this
enum MessageType : string {
    unknown = "UnknownMessage",
    privmsg = "PrivMessage",
    ping = "PingMessage"
}

alias TwitchMessage = from!"std.variant".Algebraic!(UnknownMessage, PingMessage, PrivMessage);

struct UnknownMessage {
    string rawLine;
}

struct PingMessage {
    string rawLine;
}

//TODO: move somewhere
enum UserLevel {
    regularUser,
    moderator,
    broadcaster
}

struct PrivMessage {
    import std.regex : regex;

    string channel;
    string username;
    string text;
    string rawLine;

    //TODO: make it so parseTags fills lvl too
    UserLevel userLvl;
    @tag("display-name") string displayName;

    private static regex_ = regex(r"^(?:@(?P<tags>[^ ]+) +)?(?::(?P<username>\w+)[^ ]+ +)?(?P<msgtype>[A-Z]+) +(?:#(?P<channel>[^ ]+) )?(?::(?P<content>.+))$");

    private this(string line) {
        import std.regex : matchFirst;

        rawLine = line;
        auto matched = rawLine.matchFirst(regex_);
        if (matched) {
            parseTags(this, matched["tags"]);
            username = matched["username"];
            channel = matched["channel"];
            text = matched["content"];
        }
    }

    string toString() const {
        import std.string : format, strip;

        return format("PRIVMSG #%s @%s: %s", this.channel, this.displayName, this.text);
    }
}

private alias Tuple(T...) = T;

private void parseTags(T)(ref T toFill, string str) {
    import std.array : front, split;
    import std.algorithm : each, map, max;
    import std.conv : to;
    import std.traits : getSymbolsByUDA, getUDAs;

    // maybe there is a better way of doing this
    string[string] tagValues;
    str.split(";").map!(a => a.split("="))
        .each!(a => tagValues[a[0]] = a[1]);

    static foreach (member; Tuple!(getSymbolsByUDA!(T, tag))) {
        if (auto value = getUDAs!(member, tag)[0].name in tagValues) {
            alias memberType = typeof(member);
            static if (is(memberType == bool)) {
                mixin("toFill." ~ member.stringof) = cast(bool)(*value).to!ubyte; // PepeLaugh
            }
            else {
                mixin("toFill." ~ member.stringof) = (*value).to!memberType;
            }
        }
    }

    //TODO: redo
    auto badges = "badges" in tagValues;
    if (badges) {
        foreach (badge; (*badges).split(",").map!(a => a.split("/").front)) {
            if (badge == "broadcaster") {
                toFill.userLvl = max(toFill.userLvl, UserLevel.broadcaster);
            }
            else if (badge == "moderator") {
                toFill.userLvl = max(toFill.userLvl, UserLevel.moderator);
            }
        }
    }
}
