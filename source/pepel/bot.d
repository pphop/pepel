module pepel.bot;

import pepel.config, pepel.common, pepel.module_.module_;

struct Bot {
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

    void closeConnection() {
        _gateway.close();
    }

    void registerModules(Module[] modules) {
        foreach (m; modules)
            m.prefix = _cfg.cmdPrefix;
        _modules ~= modules;
    }

    Response[] onMessage(ref Message msg) {
        Response[] res;

        foreach (m; _modules) {
            res ~= m.onMessage(msg);

            if (msg.handled)
                break;
        }

        return res;
    }
}
