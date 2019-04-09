module pepel.main;

import vibe.core.core;

import pepel.bot, pepel.config;
import pepel.module_.system;
import pepel.platform.discord.gateway;
import pepel.platform.twitch.gateway;

void main() {
    auto cfg = Config("monkas.json");

    auto twitchBot = new Bot(new TwitchGateway(cfg.twitch), cfg);
    twitchBot.registerModules([new SystemModule()]);

    auto discordBot = new Bot(new DiscordGateway(cfg.discord), cfg);
    discordBot.registerModules([new SystemModule()]);

    runApplication();
}
