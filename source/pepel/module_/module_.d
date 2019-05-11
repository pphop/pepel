module pepel.module_.module_;

import std.typecons;

import pepel.common;

abstract class Module {

    alias NR = Nullable!Response;

    struct Command {
        alias Handler = NR delegate(ref Message);

        string channel;
        string trigger;
        User.Role reqRole;
        Handler handler;
    }

protected:
    Command[] _commands;
    Command.Handler[] _onEveryMsgHandlers;
    bool _disabled;

public:

    string prefix;

    final Response[] onMessage(Message msg) {
        Response[] res;

        if (_disabled)
            return res;

        // TODO: make this less scuffed

        foreach (h; _onEveryMsgHandlers) {
            auto resp = h(msg);
            if (!resp.isNull)
                res ~= resp.get();

            if (msg.handled)
                break;
        }

        if (msg.handled)
            return res;

        foreach (c; _commands) {
            if (isTriggered(c, msg)) {
                auto resp = c.handler(msg);
                if (!resp.isNull)
                    res ~= resp.get();

                if (msg.handled)
                    break;
            }
        }

        return res;
    }

protected:

    final void registerCommands(Command[] cmds) {
        _commands ~= cmds;
    }

    final void registerOnEveryMsgHandlers(Command.Handler[] hs) {
        _onEveryMsgHandlers ~= hs;
    }

private:

    bool isTriggered(ref Command cmd, ref Message msg) {
        import std.algorithm : startsWith;

        // NotLikeThis
        // dfmt off
        return msg.sender.role >= cmd.reqRole
            && (cmd.channel == "" || cmd.channel == msg.channel.id)
            && msg.text.startsWith(prefix)
            && msg.text[prefix.length .. $].startsWith(cmd.trigger);
        // dfmt on
    }
}

// UDAS
// dfmt off
enum onEveryMsg;
struct command { string trigger; User.Role reqRole; }
// dfmt on

template generateCommands(T) {

    enum generateCommands = g();

    string g() {
        import std.algorithm : joiner, map;
        import std.format : format;
        import std.meta : AliasSeq, Filter, staticMap;
        import std.traits : hasUDA;

        enum hasCommandUDA(string member) = hasUDA!(__traits(getMember, T, member), command);
        enum hasOnEveryMsgUDA(string member) = hasUDA!(__traits(getMember, T, member), onEveryMsg);

        string res;

        res ~= "registerOnEveryMsgHandlers([%s]);\n".format(["workaround",
                Filter!(hasOnEveryMsgUDA, AliasSeq!(__traits(allMembers, T)))][1 .. $].map!(a => "&" ~ a)
                .joiner(", "));

        res ~= "registerCommands([%s]);".format([staticMap!(commandString,
                Filter!(hasCommandUDA, AliasSeq!(__traits(allMembers, T))))].joiner(", "));

        return res;

    }

    string commandString(string member)() {
        import std.format : format;
        import std.traits : getUDAs;

        auto command = getUDAs!(__traits(getMember, T, member), command)[0];

        return `Command("", "%s", User.Role.%s, &%s)`.format(command.trigger,
                command.reqRole == User.Role.none ? User.Role.pleb : command.reqRole, member);
    }
}
