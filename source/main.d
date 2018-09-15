module pepel.main;

import pepel.bot, pepel.config, pepel.modules;

void main() {
    auto cfg = Config("monkas.json");
    auto bot = new Bot(cfg);
    bot.registerModules!ExampleModule;
    bot.listen();
}
