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
    private string _defaultPrefix;
    protected bool _disabled;

    protected this() {
        _registerGeneratedCommands();
    }

protected:
    // for convenience in derrived modules
    alias nr = Nullable!Response;

    // the meme to register commands with generateCommands mixin
    void _registerGeneratedCommands();

    final void registerCommands(Command[] cmds) {
        _commands ~= cmds;
    }

public:

    final Response[] onMessage(Message msg) {
        Response[] res;

        if (_disabled)
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

    // TODO: make it less scuffed
    @property void defaultPrefix(string prefix) {
        _defaultPrefix = prefix;
        foreach (ref cmd; _commands)
            cmd.prefix = prefix;
    }
}

// UDAS
// dfmt off
struct trigger { string trigger; }
struct reqRole { User.Role role; }
// dfmt on

template generateCommands(T) {

    enum generateCommands = g();

    string g() {
        import std.algorithm : joiner, map;
        import std.format : format;
        import std.meta : AliasSeq, Filter, staticMap;
        import std.traits : hasUDA;

        enum hasTriggerUDA(string member) = hasUDA!(__traits(getMember, T, member), trigger);

        return q{
            protected override void _registerGeneratedCommands() {
                registerCommands([%s]);
            }}.format([staticMap!(commandString,
                Filter!(hasTriggerUDA, AliasSeq!(__traits(allMembers, T))))].joiner(", "));

    }

    string commandString(string member)() {
        import std.conv : text;
        import std.format : format;
        import std.traits : getUDAs, hasUDA;

        auto trigger = getUDAs!(__traits(getMember, T, member), trigger)[0].trigger;
        string role;

        static if (hasUDA!(__traits(getMember, T, member), reqRole))
            role = getUDAs!(__traits(getMember, T, member), reqRole)[0].role.text;
        else
            role = "pleb";

        return `Command("", "%s", User.Role.%s, &%s)`.format(trigger, role, member);
    }
}
