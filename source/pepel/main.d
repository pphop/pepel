module pepel.main;

import vibe.core.core;

import pepel.bot, pepel.config, pepel.module_, pepel.platform.twitch.gateway;
import pepel.module_.system;

void main() {
    auto cfg = Config("monkas.json");

    auto twitchGateway = new TwitchGateway(cfg.twitch);
    auto twitchBot = new Bot(twitchGateway, cfg);
    twitchBot.registerModules([new SystemModule()]);

    //auto discordGateway = new DiscordGateway(cfg.discord);
    //auto discordBot = new Bot(discorGateway, cfg);
    //discordBot.registerModules();
    runApplication();
}
