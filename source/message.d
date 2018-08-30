module pepel.message;

immutable(TwitchMessage) parseMessage(string rawLine) {
    import std.conv : to;
    import std.regex : matchFirst, regex;
    import std.traits : EnumMembers;
    import std.uni : toLower;

    TwitchMessage ret;
    static msgTypeRegex = regex(r"(?P<type>[A-Z]{4,})");
    auto matched = rawLine.matchFirst(msgTypeRegex);
    if (!matched) {
        //log
        ret.type = MessageType.unknown;
        ret.msg = UnknownMessage(rawLine);
        return ret;
    }

    immutable msgType = matched["type"];
    foreach (type; EnumMembers!MessageType) {
        if (msgType.toLower == type.to!string) {
            ret.type = type;
            break;
        }
    }

    //todo: make it less scuffed
    static foreach (type; EnumMembers!MessageType) {
        if (ret.type == type) {
            mixin("auto payload = " ~ type ~ "(rawLine);");
            ret.msg = payload;
        }
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

struct TwitchMessage {
    import std.variant : Algebraic;

    Algebraic!(UnknownMessage, PingMessage, PrivMessage) msg;
    MessageType type;
}

struct UnknownMessage {
    string rawLine;
}

struct PingMessage {
    string rawLine;
}

struct PrivMessage {
    import std.regex : regex;

    string channel;
    string source;
    string text;
    string rawLine;

    // maybe move to some kind of user eShrug
    @tag("display-name") string displayName;
    @tag("mod") bool isMod;
    @tag("sub") bool isSub;

    private static regex_ = regex(r"^(?:@(?P<tags>[^ ]+) +)?(?::(?P<username>\w+)[^ ]+ +)?(?P<msgtype>[A-Z]+) +(?:#(?P<channel>[^ ]+) )?(?::(?P<content>.+))$");

    private this(string line) {
        import std.regex : matchFirst;

        rawLine = line;
        auto matched = rawLine.matchFirst(regex_);
        if (matched) {
            parseTags(this, matched["tags"]);
            source = matched["username"];
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
    import std.array : split;
    import std.algorithm : each, map;
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
}
