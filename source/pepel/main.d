module pepel.main;

import d2sqlite3;
import vibe.core.core;

import pepel.bot, pepel.config;
import pepel.module_.system;
import pepel.module_.customcmd;
import pepel.platform.discord.gateway;
import pepel.platform.twitch.gateway;

version (unittest) {
    void main() {
    }
}
else {
    void main() {
        auto cfg = Config("monkas.json");
        auto db = Database("pepel.db");

        auto twitchBot = Bot(new TwitchGateway(cfg.twitch, &db), cfg);
        twitchBot.registerModules([new SystemModule(), new CustomCmdModule("Twitch", &db)]);
        scope (exit)
            twitchBot.closeConnection();

        auto discordBot = Bot(new DiscordGateway(cfg.discord), cfg);
        discordBot.registerModules([new SystemModule(), new CustomCmdModule("Discord", &db)]);
        scope (exit)
            discordBot.closeConnection();

        runApplication();
    }
}
