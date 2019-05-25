module pepel.bot;

import pepel.config, pepel.common, pepel.module_.module_;

struct Bot {
private:
    Gateway _gateway;
    Config _cfg;

public:
    Module[] modules;

    this(Gateway gateway, ref Config cfg) {
        _gateway = gateway;
        _cfg = cfg;
        _gateway.onMessage = &onMessage;
    }

    ~this() {
        _gateway.close();
    }

    void connect() {
        _gateway.connect();
    }

    void registerModules(Module[] modules) {
        foreach (m; modules) {
            m.bot = &this;
            m.prefix = _cfg.cmdPrefix;
        }

        this.modules ~= modules;
    }

    Action[] onMessage(ref Message msg) {
        Action[] res;

        foreach (m; modules) {
            res ~= m.onMessage(msg);

            if (msg.handled)
                break;
        }

        return res;
    }
}
