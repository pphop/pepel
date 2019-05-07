module pepel.platform.discord.gateway;

static import discord.w;
import vibe.core.core;

import pepel.common, pepel.config;
import pepel.platform.discord.message, pepel.platform.discord.user;

class DiscordGateway : Gateway {
private:

    class G : discord.w.DiscordGateway {

        discord.w.Channel[discord.w.Snowflake] channelCache;
        discord.w.Guild[discord.w.Snowflake] guildCache;

        this(string token) {
            super(token);
        }

        @trusted override void onMessageCreate(discord.w.Message msg) {
            super.onMessageCreate(msg);

            //TODO: proper logging
            import std.stdio : writefln;

            auto channel = channelCache.require(msg.channel_id,
                    discord.w.ChannelAPI(msg.channel_id, discord.w.authBot(_cfg.token)).get());
            auto guild = guildCache.require(channel.guild_id,
                    discord.w.GuildAPI(channel.guild_id, discord.w.authBot(_cfg.token)).get());

            writefln("Discord #%s:%s @%s: %s", guild.name,
                    channel.name.get("???"), msg.author.username, msg.content);

            if (msg.author.id == info.user.id)
                return;

            if (msg.author.bot)
                return;

            _onMessage(msg.toMsg(_cfg));
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

    override void reply(Message m, Response resp) {
        auto msg = cast(DiscordMessage) m;

        final switch (resp.type) {
        case Response.Type.chatroom:
            _gateway.channel(msg.channelID).sendMessage(resp.text);
            break;
        case Response.Type.dm:
            // TODO
            break;
        }
    }
}

@safe private DiscordMessage toMsg(discord.w.Message dMsg, Config.Discord cfg) {
    import std.algorithm : canFind;

    auto msg = new DiscordMessage();
    msg.text = dMsg.content;
    msg.channelID = dMsg.channel_id;

    // TODO: user roles
    auto sender = new DiscordUser();
    sender.username = dMsg.author.username;
    sender.id = dMsg.author.id;
    msg.sender = sender;

    if (dMsg.author.id == discord.w.Snowflake(cfg.ownerID))
        msg.sender.role = User.Role.botowner;

    if (dMsg.mentions.canFind!((a, b) => a.id == b)(discord.w.Snowflake(cfg.ownerID)))
        msg.mentionedBot = true;

    return msg;
}
