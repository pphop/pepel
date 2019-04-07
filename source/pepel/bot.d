module pepel.bot;

import pepel.config, pepel.common, pepel.module_;

final class Bot {
private:
    Gateway _gateway;
    Config _cfg;
    Module[] _modules;

public:
    this(Gateway gateway, ref Config cfg) {
        _gateway = gateway;
        _cfg = cfg;
        _gateway.onMessage = &onMessage;
        _gateway.connect();
    }

    void registerModules(Module[] modules) {
        foreach (m; modules)
            m.defaultPrefix = _cfg.cmdPrefix;
        _modules ~= modules;
    }

    void onMessage(Message msg) {
        foreach (m; _modules) {
            auto responses = m.onMessage(msg);
            foreach (resp; responses)
                _gateway.reply(msg, resp);

            if (msg.handled)
                break;
        }
    }
}
