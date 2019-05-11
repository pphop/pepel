module pepel.main;

import vibe.core.core;

import pepel.bot, pepel.config;
import pepel.module_.system;
import pepel.platform.discord.gateway;
import pepel.platform.twitch.gateway;

version (unittest) {
    void main() {
    }
}
else {

    void main() {
        auto cfg = Config("monkas.json");

        auto twitchBot = Bot(new TwitchGateway(cfg.twitch), cfg);
        twitchBot.registerModules([new SystemModule()]);
        scope (exit)
            twitchBot.closeConnection();

        auto discordBot = Bot(new DiscordGateway(cfg.discord), cfg);
        discordBot.registerModules([new SystemModule()]);
        scope (exit)
            discordBot.closeConnection();

        runApplication();
    }
}
