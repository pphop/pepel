module pepel.platform.discord.types;

import discord.w : Snowflake;

import pepel.common;

final class DiscordChannel : Channel {

    private Snowflake _id;

    this(Snowflake id) {
        _id = id;
    }

    override @property string id() {
        return _id.toString;
    }
}

final class DiscordUser : User {
    Snowflake _id;

    this(Snowflake id) {
        _id = id;
    }

    override @property string id() {
        return _id.toString;
    }

    override string mention() {
        import std.format : format;

        return "<@%s>".format(id);
    }
}
