module pepel.config;

struct Config {
    import vibe.data.json : ignore, name;

    struct Twitch {
        string username;
        string token;
        string owner;
    }

    struct Discord {
        string token;
        ulong ownerID;
    }

    Twitch twitch;
    Discord discord;
    @name("command_prefix") string cmdPrefix;
    private @ignore string _configPath;

    this(string path) {
        import std.file : read;
        import std.conv : to;

        import vibe.data.json : deserializeJson;

        this = read(path).to!string
            .deserializeJson!Config;
        _configPath = path;
    }
}
