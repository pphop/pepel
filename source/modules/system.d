module pepel.modules.system;

import pepel.modules.udas;
import pepel.bot, pepel.message;

package struct ModuleInformation {
    string name;
    string[] commands;
}

@moduleName("system")
class SystemModule {
    Bot bot;
    ModuleInformation[string] modulesInfo;
    this(Bot b, ModuleInformation[string] info) {
        bot = b;
        modulesInfo = info;
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
    @lvlReq(UserLevel.broadcaster)
    @command("module enable") void moduleEnableHandler(PrivMessage msg) {
        bot.privMsg(msg.channel, "not implemented yet 4Head");
    }

    @helpMsg("module disable <m-name> - disables given module")
    @lvlReq(UserLevel.broadcaster)
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