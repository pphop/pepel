module pepel.module_.customcmd;

import std.typecons;

import d2sqlite3;

import pepel.common;
import pepel.module_.module_;

final class CustomCmdModule : Module {

    struct DBItem {
        int id;
        string platform;
        Nullable!string channel;
        string trigger;
        User.Role reqRole;
        string reply;

        Command toCommand() {
            Command cmd;

            cmd.channel = channel.isNull ? "" : channel.get;
            cmd.reqRole = reqRole;
            cmd.handler = handler(reply);

            return cmd;
        }
    }

    string id;
    Database* db;

    this(string id, Database* db) {
        mixin(generateCommands!CustomCmdModule);

        this.id = id;
        this.db = db;
        db.run("CREATE TABLE IF NOT EXISTS customcmds (
            id INTEGER PRIMARY KEY,
            platform TEXT NOT NULL,
            channel TEXT,
            trigger TEXT NOT NULL,
            role INTEGER NOT NULL,
            reply TEXT NOT NULL
        )");

        retrieveCommands();
    }

    void retrieveCommands() {
        foreach (row; db.execute("SELECT * FROM customcmds WHERE platform = :platform", id))
            commands[row.peek!string(3)] = row.as!DBItem.toCommand;
    }

    @command("addcmd", User.Role.botowner) NR addCmd(ref Message msg) {
        import std.algorithm : canFind, filter, joiner, map;
        import std.exception : collectException;
        import std.getopt : getopt, GetoptResult, config;
        import std.string : format, join;

        auto args = msg.args;
        bool global;
        User.Role role;

        GetoptResult res;
        if (args.getopt("global|g", &global, "role|r",
                "either of [pleb, trusted, privileged, moderator, botowner]", &role).collectException(
                res) !is null)
            return NR(Response("something went wrong"));

        if (res.helpWanted) {
            auto buf = "available options: ";
            buf ~= res.options.map!(opt => "%s %s %s".format(opt.optLong,
                    opt.optShort, opt.help)).join(", ");
            return NR(Response(buf));
        }

        if (args.length < 3)
            return NR(Response("😦"));

        auto trigger = args[1];

        {
            if (bot.modules
                    .map!(m => m.commands.byKeyValue)
                    .joiner
                    .filter!(p => p.value.channel == "" || p.value.channel == msg.channel.id)
                    .map!(p => p.key)
                    .canFind(trigger)) {
                return NR(Response("command %s already exists".format(trigger)));
            }

            // is this necessary?
            bool exists;
            if (global)
                exists = db.execute(
                        "SELECT count(*) FROM customcmds WHERE platform = :platform AND trigger = :trigger",
                        id, trigger).oneValue!int != 0;
            else
                exists = db.execute("SELECT count(*) FROM customcmds WHERE channel = :channel AND platform = :platform AND trigger = :trigger",
                        msg.channel.id, id, trigger).oneValue!int != 0;

            if (exists)
                return NR(Response("command %s already exists".format(trigger)));
        }

        auto actualRole = role == User.Role.none ? User.Role.pleb : role;
        auto reply = args[2 .. $].join(" ");

        db.execute("INSERT INTO customcmds (platform, channel, trigger, role, reply)
                    VALUES (:platform, :channel, :trigger, :role, :reply)", id,
                global ? Nullable!string.init : msg.channel.id, trigger, actualRole, reply);

        auto cmd = Command(global ? "" : msg.channel.id, actualRole, handler(reply));
        commands[trigger] = cmd;

        return NR(Response("👌"));
    }

    @command("updatecmd", User.Role.botowner) NR updateCmd(ref Message msg) {
        import std.algorithm : map;
        import std.exception : collectException;
        import std.getopt : getopt, GetoptResult, config;
        import std.string : format, join;

        auto args = msg.args;
        User.Role role;

        GetoptResult res;
        if (args.getopt("role|r", "either of [pleb, trusted, privileged, moderator, botowner]",
                &role).collectException(res) !is null)
            return NR(Response("something went wrong"));

        if (res.helpWanted) {
            auto buf = "available options: ";
            buf ~= res.options.map!(opt => "%s %s %s".format(opt.optLong,
                    opt.optShort, opt.help)).join(", ");
            return NR(Response(buf));
        }

        if (args.length < 3)
            return NR(Response("😦"));

        auto trigger = args[1];

        auto queryRes = db.execute("SELECT * FROM customcmds WHERE platform = :platform AND trigger = :trigger",
                id, trigger);

        if (queryRes.empty)
            return NR(Response("command %s does not exist".format(trigger)));

        auto channel = queryRes.front.peek!(Nullable!string)(2);
        if (!channel.isNull && channel.get != msg.channel.id)
            return NR(Response("command %s does not exist".format(trigger)));

        auto reply = args[2 .. $].join(" ");

        auto item = queryRes.front.as!DBItem;

        if (role != User.Role.none && item.reqRole != role)
            db.execute("UPDATE customcmds SET role = :role WHERE id = :id", role, item.id);

        db.execute("UPDATE customcmds SET reply = :reply WHERE id = :id", reply, id);

        if (auto cmd = trigger in commands) {
            if (role != User.Role.none)
                cmd.reqRole = role;

            cmd.handler = handler(reply);
        }

        return NR(Response("👌"));
    }

    @command("removecmd", User.Role.botowner) NR removeCmd(ref Message msg) {
        import std.algorithm : map;
        import std.exception : collectException;
        import std.getopt : getopt, GetoptResult, config;
        import std.string : format, join;

        auto args = msg.args;
        bool global;

        GetoptResult res;
        if (args.getopt("global|g", &global).collectException(res) !is null)
            return NR(Response("something went wrong"));

        if (res.helpWanted) {
            auto buf = "available options: ";
            buf ~= res.options.map!(opt => "%s %s %s".format(opt.optLong,
                    opt.optShort, opt.help)).join(", ");
            return NR(Response(buf));
        }

        if (args.length < 2)
            return NR(Response("😦"));

        auto trigger = args[1];

        ResultRange queryRes;
        if (global)
            queryRes = db.execute("SELECT id FROM customcmds WHERE platform = :platform AND trigger = :trigger",
                    id, trigger);
        else
            queryRes = db.execute(
                    "SELECT id FROM customcmds WHERE channel = :channel AND platform = :platform AND trigger = :trigger",
                    msg.channel.id, id, trigger);

        auto cmdId = queryRes.empty ? 0 : queryRes.oneValue!int;

        if (cmdId == 0)
            return NR(Response("command %s does not exists".format(trigger)));

        db.execute("DELETE FROM customcmds WHERE id = :id", cmdId);

        commands.remove(trigger);

        return NR(Response("👌"));
    }
}

private Module.Command.Handler handler(string reply) {
    return (ref Message m) { return Nullable!Response(Response(reply)); };
}
