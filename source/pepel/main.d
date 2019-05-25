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
    void main(string[] args) {
        auto cfg = Config(args.length > 1 ? args[1] : "config.json");
        auto db = Database("pepel.db");

        auto twitchBot = Bot(new TwitchGateway(cfg.twitch, &db), cfg);
        twitchBot.registerModules([new SystemModule(), new CustomCmdModule("Twitch", &db)]);
        // TODO: make this less scuffed
        if (cfg.twitch.token != "")
            twitchBot.connect();

        auto discordBot = Bot(new DiscordGateway(cfg.discord), cfg);
        discordBot.registerModules([new SystemModule(), new CustomCmdModule("Discord", &db)]);
        if (cfg.discord.token != "")
            discordBot.connect();

        runApplication();
    }
}
