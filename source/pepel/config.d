module pepel.config;

struct Config {
    import vibe.data.json : ignore, name;

    struct Twitch {
        string username;
        string token;
        string owner;
        string[] channels;
    }

    Twitch twitch;
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
        tmpfile.rename(_configPath);
    }
}
