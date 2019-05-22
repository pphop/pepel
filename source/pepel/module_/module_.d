module pepel.module_.module_;

import pepel.bot;
import pepel.common;

abstract class Module {

    struct Command {
        alias Handler = Action delegate(ref Message);

        string channel;
        User.Role reqRole;
        Handler handler;

        bool isTriggered(ref Message msg) {
            // dfmt off
            return msg.sender.role >= reqRole
                && (channel == "" || channel == msg.channel.id);
            // dfmt on
        }
    }

protected:
    Command.Handler[] _onEveryMsgHandlers;
    bool _disabled;

public:
    Bot* bot;
    Command[string] commands;
    string prefix;

    final Action[] onMessage(Message msg) {
        import std.algorithm : startsWith;

        if (_disabled)
            return Action[].init;

        Action[] res;

        foreach (h; _onEveryMsgHandlers) {
            auto action = h(msg);
            if (action.hasValue)
                res ~= action;

            if (msg.handled)
                return res;
        }

        if (msg.text.startsWith(prefix)) {
            if (auto cmd = msg.args[0][prefix.length .. $] in commands) {
                if (cmd.isTriggered(msg)) {
                    auto action = cmd.handler(msg);
                    if (action.hasValue)
                        res ~= action;
                }
            }
        }

        return res;
    }

protected:

    final void registerOnEveryMsgHandlers(Command.Handler[] hs) {
        _onEveryMsgHandlers ~= hs;
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

        res ~= "commands = [%s];".format([staticMap!(commandString,
                Filter!(hasCommandUDA, AliasSeq!(__traits(allMembers, T))))].joiner(", "));

        return res;

    }

    string commandString(string member)() {
        import std.format : format;
        import std.traits : getUDAs;

        auto command = getUDAs!(__traits(getMember, T, member), command)[0];

        return `"%s": Command("", User.Role.%s, &%s)`.format(command.trigger,
                command.reqRole == User.Role.none ? User.Role.pleb : command.reqRole, member);
    }
}
