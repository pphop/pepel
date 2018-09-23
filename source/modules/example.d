module pepel.modules.example;

import pepel.modules.udas;
import pepel.bot, pepel.message;

@moduleName("example")
class ExampleModule {
    Bot bot;
    this(Bot b) {
        bot = b;
    }

    @helpMsg("replies with NaM")
    @command("test") void exampleHandler(PrivMessage msg) {
        bot.reply(msg.channel, msg.username, "NaM");
    }

    @contains("NaM") void exampleHandler2(PrivMessage msg) {
        bot.privMsg(msg.channel, "NaM");
    }

    @always void exampleHandler3(PrivMessage msg, ref bool stop) {
        import std.stdio : writeln;

        writeln(msg);
    }
}
