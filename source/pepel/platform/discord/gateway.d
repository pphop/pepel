module pepel.platform.discord.gateway;

import std.variant;

static import discord.w;
import vibe.core.core;

import pepel.common, pepel.config;
import pepel.platform.discord.types;

final class DiscordGateway : Gateway {
private:

    class G : discord.w.DiscordGateway {

        this(string token) {
            super(token);
        }

        @trusted override void onMessageCreate(discord.w.Message msg) {
            super.onMessageCreate(msg);

            //TODO: proper logging
            import std.stdio : writefln;

            auto channel = discord.w.gChannelCache.get(msg.channel_id);
            auto guild = discord.w.gGuildCache.get(channel.guild_id);

            writefln("Discord #%s:%s @%s: %s", guild.name,
                    channel.name.get("???"), msg.author.username, msg.content);

            if (msg.author.id == info.user.id)
                return;

            if (msg.author.bot)
                return;

            auto m = msg.toMsg(_cfg);
            auto actions = onMessage(m);

            // TODO: handle whisper/join/leave
            // dfmt off
            foreach (a; actions)
                a.visit!((Response resp) { _gateway.channel(msg.channel_id).sendMessage(resp.text); },
                        anything => writefln("discord: unhandled action: %s", anything));
            // dfmt on
        }
    }

    discord.w.DiscordBot _gateway;
    Config.Discord _cfg;

public:
    this(ref Config.Discord cfg) {
        _cfg = cfg;
    }

    override void connect() {
        _gateway = discord.w.makeBot(_cfg.token, this.new G(_cfg.token));
    }

    override void close() {
        _gateway.gateway.disconnect();
    }
}

private Message toMsg(discord.w.Message dMsg, Config.Discord cfg) {
    import std.algorithm : canFind;

    auto msg = Message();

    msg.sender = new DiscordUser(dMsg.author.id);
    // TODO: user roles
    msg.sender.role = dMsg.author.id == discord.w.Snowflake(cfg.ownerID)
        ? User.Role.botowner : User.Role.pleb;
    msg.sender.username = dMsg.author.username;
    msg.channel = new DiscordChannel(dMsg.channel_id);
    msg.text = dMsg.content;
    msg.mentionedBot = dMsg.mentions.canFind!((a, b) => a.id == b)(discord.w.Snowflake(cfg.ownerID));

    return msg;
}
