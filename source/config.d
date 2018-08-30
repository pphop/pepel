module pepel.config;

struct Config {
    import vibe.data.json : ignore, name;

    TwitchCfg twitch;
    @name("command_prefix") string cmdPrefix;
    @ignore string configPath;

    struct TwitchCfg {
        string username;
        string token;
        string owner;
        string[] channels;
    }

    this(string path) {
        import std.file : read;
        import std.conv : to;

        import vibe.data.json : deserializeJson;

        this = read(path).to!string
            .deserializeJson!Config;
        configPath = path;
    }

    void addChannel(string channel) {
        import std.algorithm : canFind;

        if (twitch.channels.canFind(channel)) {
            return;
        }
        twitch.channels ~= channel;
        save();
    }

    private void save() {
        import std.file : exists, remove, rename, write;

        import vibe.data.json : serializeToPrettyJson;

        auto tmpfile = "config.tmp";
        scope (failure) {
            assert(tmpfile.exists);
            tmpfile.remove();
        }

        tmpfile.write(this.serializeToPrettyJson());
        tmpfile.rename(configPath);
    }
}
