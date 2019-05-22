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

    @command("ping") Action ping(ref Message msg) {
        return Response("pong").Action;
    }

    @command("uptime") Action uptime(ref Message msg) {
        import std.format : format;

        return Response("running for %s".format(Clock.currTime - startTime)).Action;
    }

    @command("shutdown", User.Role.botowner) Action shutdown(ref Message msg) {
        import std.format : format;
        import vibe.core.core : exitEventLoop;

        exitEventLoop();
        return Response("shutting down after running for %s".format(Clock.currTime - startTime))
            .Action;
    }

    @command("commands") Action cmds(ref Message msg) {
        import std.algorithm : filter, joiner, map, sort;
        import std.array : array, join;

        return Response(bot.modules
                .map!(m => m.commands.byKeyValue)
                .joiner
                .filter!(p => p.value.channel == "" || p.value.channel == msg.channel.id)
                .map!(p => p.key)
                .array
                .sort
                .join(", ")).Action;
    }

    @command("join", User.Role.botowner) Action join(ref Message msg) {
        if (msg.args.length > 1)
            return Join(msg.args[1]).Action;
        return Action.init;
    }

    @command("leave", User.Role.botowner) Action leave(ref Message msg) {
        if (msg.args.length > 1)
            return Leave(msg.args[1]).Action;
        return Action.init;
    }
}
