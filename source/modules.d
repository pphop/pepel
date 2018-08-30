module pepel.modules;

import pepel.bot, pepel.message;

void registerModule(M)(Bot bot) {
    auto m = new M(bot);

    bot.registerMessageHandlers(m);
}

private void registerMessageHandlers(M)(Bot bot, M m) {
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

private void registerHandler(string msgType, string member, M)(Bot bot, M m) {
    mixin("bot.add" ~ msgType ~ "Handler(&m." ~ member ~ ");");
}

private void registerHandler(string msgType : "PrivMessage", string member, M)(Bot bot, M m) {
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

struct moduleName {
    string name;
}

// not implemented yet
struct moduleVar(T) {
    string name;
    T value;
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

@moduleName("example")
class ExampleModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

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

    @onMessage(MessageType.unknown) void exampleHandler4(UnknownMessage msg) {
        import std.stdio : writeln;

        writeln(msg.rawLine);
    }
}
