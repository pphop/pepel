module pepel.config;

struct Config {
    import vibe.data.json : name, optional;

    struct Twitch {
        string username;
        string token;
        string owner;
    }

    struct Discord {
        string token;
        ulong ownerID;
    }

    @optional Twitch twitch;
    @optional Discord discord;
    @name("command_prefix") string cmdPrefix;

    this(string path) {
        import std.file : read;
        import std.conv : to;
        import vibe.data.json : deserializeJson;

        this = read(path).to!string
            .deserializeJson!Config;
    }
}
