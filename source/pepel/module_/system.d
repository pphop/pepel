module pepel.module_.system;

import std.datetime.systime;

import pepel.common;
import pepel.module_.module_;

final class SystemModule : Module {

    SysTime startTime;

    this() {
        mixin(generateCommands!SystemModule);
        startTime = Clock.currTime;
    }

    @command("ping") NR ping(ref Message msg) {
        return NR(Response("pong"));
    }

    @command("uptime") NR uptime(ref Message msg) {
        import std.format : format;

        return NR(Response("running for %s".format(Clock.currTime - startTime)));
    }

    @command("shutdown", User.Role.botowner) NR shutdown(ref Message msg) {
        import std.format : format;
        import vibe.core.core : exitEventLoop;

        exitEventLoop();
        return NR(Response("shutting down after running for %s".format(Clock.currTime - startTime)));
    }

    @command("commands") NR cmds(ref Message msg) {
        import std.algorithm : filter, joiner, map, sort;
        import std.array : array, join;

        return NR(Response(bot.modules
                .map!(m => m.commands.byKeyValue)
                .joiner
                .filter!(p => p.value.channel == "" || p.value.channel == msg.channel.id)
                .map!(p => p.key)
                .array
                .sort
                .join(", ")));
    }
}
