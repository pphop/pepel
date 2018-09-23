module pepel.modules;

public import pepel.modules.example;
public import pepel.modules.system;

import pepel.modules.udas;
import pepel.bot, pepel.message;

//TODO: redo most of this module

void registerModules(MS...)(Bot bot) {
    ModuleInformation[string] modulesInfo;

    static foreach (M; MS) {
        {
            auto m = new M(bot);

            extractModuleInfo!M(modulesInfo);
            bot.registerMessageHandlers(m);
        }
    }

    extractModuleInfo!SystemModule(modulesInfo);
    auto sm = new SystemModule(bot, modulesInfo);
    bot.registerMessageHandlers(sm);
}

private:

void extractModuleInfo(M)(ModuleInformation[string] modulesInfo) {
    import std.format : format;
    import std.traits : getUDAs, hasUDA;

    static assert(getUDAs!(M, moduleName).length == 1,
            format!"module %s must have moduleName attribute"(M.stringof));
    enum mName = getUDAs!(M, moduleName)[0].name;
    static assert(mName != "",
            format!"module %s should have valid moduleName attribute"(M.stringof));

    ModuleInformation info;
    info.name = mName;
    static if (hasUDA!(M, helpMsg)) {
        info.helpMsg = getUDAs!(M, helpMsg)[0].text;
    }

    info.extractCommandsInfo!M;
    modulesInfo[mName] = info;
}

void extractCommandsInfo(M)(ref ModuleInformation info) {
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
            bot.addCommandHandler(attr.command, handler.wrap!(member, M)(bot));
            lidlCheck++;
        }
    }

    assert(lidlCheck == 1);
}

//this is terrible
template wrap(string member, M) {
    alias cmdHandler = void delegate(PrivMessage);

    cmdHandler wrap(cmdHandler hand, Bot bot) {
        return hand.lvlWrapper(bot).helpWrapper(bot);
    }

    cmdHandler helpWrapper(cmdHandler hand, Bot bot) {
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

    cmdHandler lvlWrapper(cmdHandler hand, Bot bot) {
        import std.traits : getUDAs, hasUDA;

        static if (!hasUDA!(mixin("M." ~ member), lvlReq)) {
            return hand;
        }
        else {
            enum requiredLvl = getUDAs!(mixin("M." ~ member), lvlReq)[0].lvl;
            return (PrivMessage msg) {
                if (msg.userLvl < requiredLvl || msg.username != bot.config.twitch.owner) {
                    bot.privMsg(msg.channel, "you dont have permissions to use this command");
                    return;
                }
                hand(msg);
            };
        }
    }
}
