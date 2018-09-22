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

struct helpMsg {
    string text;
}

// not implemented yet
struct moduleVar {
    string name;
}

struct on {
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

struct ModuleInfo {
    string name;
    string[] commands;
}

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
    static if (hasUDA!(M, helpMsg)) {
        info.helpMsg = getUDAs!(M, helpMsg)[0].text;
    }

    info.extractCommandsInfo!M;
    modulesInfo[mName] = info;
}

void extractCommandsInfo(M)(ref ModuleInfo info) {
    import std.algorithm : map, sort, splitter, uniq;
    import std.array : array;
    import std.format : format;
    import std.traits : getUDAs, hasUDA;

    static foreach (member; __traits(allMembers, M)) {
        static if (hasUDA!(mixin("M." ~ member), command)) {
            {
                enum cmd = getUDAs!(mixin("M." ~ member), command)[0].command;
                static assert(cmd != "",
                        format!"%s in module %s should have valid command attribute"(member,
                            M.stringof));

                info.commands ~= cmd;
            }
        }
    }
    info.commands = info.commands.map!(a => a.splitter(" ").front).array.sort.uniq.array;
}

void registerMessageHandlers(M)(Bot bot, M m) {
    static foreach (member; __traits(allMembers, M)) {
        static foreach (attr; __traits(getAttributes, mixin("M." ~ member))) {
            static if (is(typeof(attr) == on)) {
                {
                    enum msgType = attr.type;
                    bot.registerHandler!(msgType, member)(m);
                }
            }
            //make it less scuffed
            else static if (is(attr == always) || is(typeof(attr) == command)
                    || is(typeof(attr) == contains)) {
                bot.registerPrivMsgHandler!member(m);
            }
        }
    }
}

void registerHandler(string msgType, string member, M)(Bot bot, M m) {
    mixin("bot.add" ~ msgType ~ "Handler(&m." ~ member ~ ");");
}

void registerPrivMsgHandler(string member, M)(Bot bot, M m) {
    int lidlCheck;

    mixin("auto handler = &m." ~ member ~ ";");
    static foreach (attr; __traits(getAttributes, mixin("M." ~ member))) {
        static if (is(attr == always)) {
            bot.addPriorityHandler(handler);
            lidlCheck++;
        }
        else static if (is(typeof(attr) == contains)) {
            bot.addContainsHandler(attr.contains, handler);
            lidlCheck++;
        }
        else static if (is(typeof(attr) == command)) {
            bot.addCommandHandler(attr.command, handler.helpMsgWrapper!(member, M)(bot));
            lidlCheck++;
        }
    }

    assert(lidlCheck == 1);
}

//this is terrible
void delegate(PrivMessage) helpMsgWrapper(string member, M)(void delegate(PrivMessage) hand, Bot bot) {
    return (PrivMessage msg) {
        import std.algorithm : startsWith;
        import std.traits : getUDAs, hasUDA;

        static if (hasUDA!(mixin("M." ~ member), helpMsg)) {
            static immutable help = getUDAs!(mixin("M." ~ member), helpMsg)[0].text;
        }
        else {
            static immutable help = "no help message provided";
        }
        enum helpCmd = getUDAs!(mixin("M." ~ member), command)[0].command ~ " -help";
        if (msg.text[bot.config.cmdPrefix.length .. $].startsWith(helpCmd)) {
            bot.privMsg(msg.channel, help);
            return;
        }
        hand(msg);
    };
}

@moduleName("system")
class SystemModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

    @helpMsg("help's help command NaM")
    @command("help") void helCmdHandler(PrivMessage msg) {
        import std.format : format;

        bot.privMsgf(msg.channel,
                format!`"%1$scmdlist" | "%1$smodule list" | "%1$s<cmd> -help"`(bot.config.cmdPrefix));
    }

    @helpMsg("lists all available commands")
    @command("cmdlist") void cmdListHandler(PrivMessage msg) {
        import std.algorithm : joiner, map;

        bot.privMsgf(msg.channel, "available commands: %s",
                modulesInfo.byValue.map!(a => a.commands).joiner.joiner(", "));
    }

    @helpMsg("lists all modules")
    @command("module list") void moduleListHandler(PrivMessage msg) {
        import std.algorithm : joiner, map;

        //TODO: mark modulenames with "+"/"-" after implementing the disabling/enabling
        bot.privMsgf(msg.channel, "modules: %s",
                modulesInfo.byValue.map!(a => a.name).joiner(", "));
    }

    @helpMsg("module commands <m-name> - lists commands from the given module")
    @command("module commands") void moduleCmdsHandler(PrivMessage msg) {
        import std.algorithm : joiner;
        import std.array : split;

        //TODO: make the args checking automatic
        auto args = msg.text.split(" ");
        if (args.length < 3) {
            return;
        }
        if (auto mInfo = args[2] in modulesInfo) {
            bot.privMsgf(msg.channel, "commands from module %s: %s", args[2],
                    (*mInfo).commands.joiner(", "));
        }
        else {
            bot.privMsgf(msg.channel, "there is no %s module", args[2]);
        }
    }

    @helpMsg("module enable <m-name> - enables given module")
    @command("module enable") void moduleEnableHandler(PrivMessage msg) {
        bot.privMsg(msg.channel, "not implemented yet 4Head");
    }

    @helpMsg("module disable <m-name> - disables given module")
    @command("module disable") void moduleDisableHandler(PrivMessage msg) {
        bot.privMsg(msg.channel, "not implemented yet 4Head");
    }

    @helpMsg(`basic module management command, "module <commands|enable|disable> <m-name>"`)
    @command("module") void modulesHandler(PrivMessage msg) {
        //this only exists for the help message xd
    }

    @on(MessageType.ping) void pingHandler(PingMessage) {
        bot.write("PONG :tmi.twitch.tv");
    }

    @on(MessageType.unknown) void printUnknownMessages(UnknownMessage msg) {
        import std.stdio : writeln;

        writeln(msg.rawLine);
    }
}

@moduleName("example")
public class ExampleModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

    @helpMsg("replies with NaM")
    @command("test") void exampleHandler(PrivMessage msg) {
        bot.reply(msg.channel, msg.source, "NaM");
    }

    @contains("NaM") void exampleHandler2(PrivMessage msg) {
        bot.privMsg(msg.channel, "NaM");
    }

    @always void exampleHandler3(PrivMessage msg, ref bool stop) {
        import std.stdio : writeln;

        writeln(msg);
    }
}
