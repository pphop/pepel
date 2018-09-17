module pepel.modules;

import pepel.bot, pepel.message;

//TODO: redo most of this module

void registerModules(MS...)(Bot bot) {
    import std.meta : AliasSeq;

    static foreach (M; AliasSeq!(SystemModule, MS)) {
        {
            auto m = new M(bot);

            extractModuleInfo!M;
            bot.registerMessageHandlers(m);
        }
    }
}

// UDAs

struct moduleName {
    string name;
}

struct description {
    string text;
}

// not implemented yet
struct moduleVar {
    string name;
}

struct onMessage {
    MessageType type;
}

struct always {
}

struct contains {
    string contains;
}

struct command {
    string command;
}

private:

struct CommandInfo {
    string command;
    string description = "no description";
}

struct ModuleInfo {
    string name;
    string descriprion = "no description";
    CommandInfo[] commands;
}

//used only for 'help' commands
ModuleInfo[string] modulesInfo;

void extractModuleInfo(M)() {
    import std.format : format;
    import std.traits : getUDAs, hasUDA;

    static assert(getUDAs!(M, moduleName).length == 1,
            format!"module %s must have moduleName attribute"(M.stringof));
    enum mName = getUDAs!(M, moduleName)[0].name;
    static assert(mName != "",
            format!"module %s should have valid moduleName attribute"(M.stringof));

    ModuleInfo info;
    info.name = mName;
    static if (hasUDA!(M, description)) {
        info.descriprion = getUDAs!(M, description)[0].text;
    }

    info.extractCommandsInfo!M;
    modulesInfo[mName] = info;
}

void extractCommandsInfo(M)(ref ModuleInfo info) {
    import std.format : format;
    import std.traits : getUDAs, hasUDA;

    static foreach (member; __traits(allMembers, M)) {
        static if (hasUDA!(mixin("M." ~ member), command)) {
            {
                enum cmd = getUDAs!(mixin("M." ~ member), command)[0].command;
                static assert(cmd != "",
                        format!"%s in module %s should have valid command attribute"(member,
                            M.stringof));

                CommandInfo cmdInfo;
                cmdInfo.command = cmd;
                static if (hasUDA!(mixin("M." ~ member), description)) {
                    cmdInfo.description = getUDAs!(mixin("M." ~ member), description)[0].text;
                }
                info.commands ~= cmdInfo;
            }
        }
    }
}

void registerMessageHandlers(M)(Bot bot, M m) {
    static foreach (member; __traits(allMembers, M)) {
        static foreach (attr; __traits(getAttributes, mixin("M." ~ member))) {
            static if (is(typeof(attr) == onMessage)) {
                {
                    enum msgType = attr.type;
                    bot.registerHandler!(msgType, member)(m);
                }
            }
        }
    }
}

void registerHandler(string msgType, string member, M)(Bot bot, M m) {
    mixin("bot.add" ~ msgType ~ "Handler(&m." ~ member ~ ");");
}

void registerHandler(string msgType : "PrivMessage", string member, M)(Bot bot, M m) {
    int lidlCheck;

    mixin("auto handler = &m." ~ member ~ ";");
    static foreach (attr; __traits(getAttributes, mixin("M." ~ member))) {
        static if (is(typeof(attr) == always)) {
            bot.addPriorityHandler(handler);
            lidlCheck++;
        }
        else static if (is(typeof(attr) == contains)) {
            bot.addContainsHandler(attr.contains, handler);
            lidlCheck++;
        }
        else static if (is(typeof(attr) == command)) {
            bot.addCommandHandler(attr.command, handler);
            lidlCheck++;
        }
    }

    assert(lidlCheck == 1);
}

@moduleName("system")
@description("module respinsible for basic module management and help commands")
class SystemModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

    @onMessage(MessageType.privmsg) @command("help") void helCmdHandler(PrivMessage msg) {
        import std.format : format;

        bot.privMsgf(msg.channel,
                format!`"%1$scommand -help" or "%1$smodule -help"`(bot.config.cmdPrefix));
    }

    @description(`basic command help, "command -help" for usage`)
    @onMessage(MessageType.privmsg) @command("command") void cmdHelpHandler(PrivMessage msg) {
        import std.algorithm : find, joiner, map;
        import std.array : split;
        import std.format : format;

        immutable helpMsg = format!`usage: "%1$scommand -list" | "%1$scommand <cmd-name>"`(
                bot.config.cmdPrefix);
        auto args = msg.text.split(" ");
        if (args.length < 2) {
            bot.privMsg(msg.channel, helpMsg);
            return;
        }

        auto cmd = args[1];
        switch (cmd) {
        case "-help":
            bot.privMsg(msg.channel, helpMsg);
            break;
        case "-list":
            auto cmds = modulesInfo.byValue
                .map!(a => a.commands)
                .joiner
                .map!(a => a.command);
            bot.privMsgf(msg.channel, "available commands: %s", cmds.joiner(", "));
            break;
        default:
            auto found = modulesInfo.byValue
                .map!(a => a.commands)
                .joiner
                .find!(a => a.command == cmd);
            if (found.empty) {
                bot.privMsgf(msg.channel, "there is no %s command", cmd);
                return;
            }
            bot.privMsgf(msg.channel, "%s: %s", found.front.command, found.front.description);
        }
    }

    @description(`basic module management command, "module -help" for usage`)
    @onMessage(MessageType.privmsg) @command("module") void modulesHandler(PrivMessage msg) {
        import std.algorithm : joiner, map;
        import std.array : split;
        import std.format : format;

        immutable helpMsg = format!(
                `usage: "%1$smodule -list" | "%1$smodule <m-name> [commands|enable|disable]"`)(
                bot.config.cmdPrefix);
        auto args = msg.text.split(" ");
        if (args.length < 2) {
            bot.privMsg(msg.channel, helpMsg);
            return;
        }

        auto mName = args[1];
        switch (mName) {
        case "-help":
            bot.privMsg(msg.channel, helpMsg);
            break;
        case "-list":
            auto modules = modulesInfo.byKey.joiner(", ");
            bot.privMsgf(msg.channel, "modules: %s", modules);
            break;
        default:
            auto mInfo = args[1] in modulesInfo;
            if (!mInfo) {
                bot.privMsgf(msg.channel, "there is no %s module", args[1]);
                return;
            }

            if (args.length == 2) {
                bot.privMsgf(msg.channel, "%s: %s", (*mInfo).name, (*mInfo).descriprion);
                return;
            }

            switch (args[2]) {
            case "commands":
                bot.privMsgf(msg.channel, "%s commands: %s", (*mInfo).name,
                        (*mInfo).commands.map!(a => a.command));
                break;
            case "enable":
            case "disable":
                bot.privMsg(msg.channel, "not implemented yet 4Head");
                break;
            default:
                bot.privMsg(msg.channel, helpMsg);
            }
        }
    }

    @onMessage(MessageType.ping) void pingHandler(PingMessage) {
        bot.write("PONG :tmi.twitch.tv");
    }

    @onMessage(MessageType.unknown) void printUnknownMessages(UnknownMessage msg) {
        import std.stdio : writeln;

        writeln(msg.rawLine);
    }
}

@moduleName("example") @description("example NaM module")
public class ExampleModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

    @description("replies with NaM")
    @onMessage(MessageType.privmsg) @command("test") void exampleHandler(PrivMessage msg) {
        bot.reply(msg.channel, msg.source, "NaM");
    }

    @onMessage(MessageType.privmsg) @contains("NaM") void exampleHandler2(PrivMessage msg) {
        bot.privMsg(msg.channel, "NaM");
    }

    @onMessage(MessageType.privmsg) @always() void exampleHandler3(PrivMessage msg, ref bool stop) {
        import std.stdio : writeln;

        writeln(msg);
    }
}
