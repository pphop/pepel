module pepel.module_.module_;

import std.typecons;

import pepel.common;

abstract class Module {

    struct Command {
        alias Handler = Nullable!Response delegate(Message);

        string prefix;
        string trigger;
        User.Role reqRole;
        Handler handler;

        bool isTriggered(Message msg) {
            import std.algorithm : startsWith;

            return msg.sender.role >= reqRole && msg.text.startsWith(prefix)
                && msg.text[prefix.length .. $].startsWith(trigger);
        }
    }

    private Command[] _commands;
    private Command.Handler[] _onEveryMsgHandlers;
    private string _defaultPrefix;
    protected bool _disabled;

protected:
    // for convenience in derrived modules
    alias NR = Nullable!Response;

    final void registerCommands(Command[] cmds) {
        _commands ~= cmds;
    }

    final void registerOnEveryMsgHandlers(Command.Handler[] hs) {
        _onEveryMsgHandlers ~= hs;
    }

public:

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
            if (c.isTriggered(msg)) {
                auto resp = c.handler(msg);
                if (!resp.isNull)
                    res ~= resp.get();

                if (msg.handled)
                    break;
            }
        }

        return res;
    }

    @property void defaultPrefix(string prefix) {
        foreach (ref cmd; _commands)
            if (cmd.prefix is _defaultPrefix)
                cmd.prefix = prefix;

        _defaultPrefix = prefix;
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

        return `Command(null, "%s", User.Role.%s, &%s)`.format(command.trigger,
                command.reqRole, member);
    }
}
