module pepel.platform.discord.user;

import discord.w : Snowflake;

import pepel.common;

class DiscordUser : User {
    Snowflake id;

    override string mention() {
        import std.format : format;

        return "<@%s>".format(id);
    }
}
