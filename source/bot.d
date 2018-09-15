module pepel.bot;

import vibe.core.net, vibe.stream.operations;

import pepel.config, pepel.message;

class Bot {
    import std.traits : EnumMembers, isSomeString;

    Config config;
    private TCPConnection conn;

    this(Config cfg) {
        import std.format : format;

        config = cfg;
        conn = connectTCP("irc.chat.twitch.tv", 6667u);
        string[] toWrite;
        toWrite ~= format!"PASS oauth:%s"(config.twitch.token);
        toWrite ~= format!"NICK %s"(config.twitch.username);
        toWrite ~= "CAP REQ :twitch.tv/tags";
        foreach (ch; config.twitch.channels) {
            toWrite ~= format!"JOIN #%s"(ch);
        }
        write(toWrite);
        addPingMessageHandler(&pingHandler);
    }

    void listen() {
        import std.variant : visit;

        while (conn.waitForData()) {
            auto raw = cast(string) conn.readLine;
            auto message = parseMessage(raw);
            message.visit!(msg => handleMessage(msg));
        }
    }

    void close() {
        conn.close();
    }

    void joinChannel(string channel) {
        config.addChannel(channel);
        writef("JOIN #%s", channel); //todo: dont send JOIN if already joined and notify the caller
    }

    void write(S)(S str)
            if (isSomeString!S) {
        import std.format : format;

        conn.write(format!"%s\r\n"(str));
        conn.flush();
    }

    void write(S)(S[] strs)
            if (isSomeString!S) {
        import std.array : join;

        write(strs.join("\r\n"));
    }

    void writef(S, Args...)(S fmt, Args args)
            if (isSomeString!S) {
        import std.format : format;

        write(format(fmt, args));
    }

    void privMsg(S)(S channel, S text)
            if (isSomeString!S) {
        writef("PRIVMSG #%s :%s", channel, text);
    }

    void privMsgf(S, Args...)(S channel, S fmt, Args args)
            if (isSomeString!S) {
        import std.format : format;

        privMsg(channel, format(fmt, args));
    }

    void reply(S)(S channel, S username, S text)
            if (isSomeString!S) {
        privMsgf(channel, "%s, %s", username, text);
    }

    void replyf(S, Args...)(S channel, S username, S fmt, Args args)
            if (isSomeString!S) {
        import std.format : format;

        reply(channel, username, format(fmt, args));
    }

    static foreach (msgType; EnumMembers!MessageType) {
        mixin MessageHandler!msgType;
    }
}

//maybe redo
mixin template MessageHandler(string msgType) {
private:
    mixin(`struct ` ~ msgType ~ `Handler {
    private:
        alias Handler = void delegate(` ~ msgType ~ `);

        Handler[] handlers;

        void addHandler(Handler h) {
            handlers ~= h;
        }
    }

    ` ~ msgType ~ `Handler ` ~ msgType ~ `Handler_;

    public void add` ~ msgType
            ~ `Handler(` ~ msgType ~ `Handler_.Handler handler) {
        ` ~ msgType
            ~ `Handler_.addHandler(handler);
    }
    
    void handleMessage(` ~ msgType ~ ` message) {
        foreach (handler; `
            ~ msgType ~ `Handler_.handlers) {
            handler(message);
        }
    }`);
}

mixin template MessageHandler(string msgType : "PrivMessage") {
private:
    struct PrivMessageHandler {
        import std.format : format;

    private:
        alias HandlerWithStop = void delegate(PrivMessage, ref bool);
        alias Handler = void delegate(PrivMessage);
        // think of better names for these
        HandlerWithStop[] priorityHandlers;
        Handler[string] containsHandlers;
        Handler[string] commandHandlers;

        void handle(PrivMessage message, string cmdPrefix) {
            import std.algorithm : startsWith;
            import std.array : split;
            import std.string : strip;

            bool stop;
            foreach (handler; priorityHandlers) {
                if (stop) {
                    return;
                }
                handler(message, stop);
            }

            auto words = message.text.strip.split(" ");
            foreach (word; words) {
                if (auto handler = word in containsHandlers) {
                    (*handler)(message);
                }
            }

            auto msgText = message.text;
            if (msgText.startsWith(cmdPrefix)) {
                foreach (command, handler; commandHandlers) {
                    if (msgText[cmdPrefix.length .. $].startsWith(command)) {
                        handler(message);
                    }
                }
            }
        }
    }

    PrivMessageHandler privMessageHandler_;

    public void addPriorityHandler(PrivMessageHandler.HandlerWithStop handler) {
        privMessageHandler_.priorityHandlers ~= handler;
    }

    public void addContainsHandler(string contains, PrivMessageHandler.Handler handler) {
        import std.format : format;

        assert((contains in privMessageHandler_.containsHandlers) is null,
                format!"handler for 'contains' '%s' is already registered"(contains));

        privMessageHandler_.containsHandlers[contains] = handler;
    }

    public void addCommandHandler(string command, PrivMessageHandler.Handler handler) {
        import std.format : format;

        assert((command in privMessageHandler_.commandHandlers) is null,
                format!"handler for command '%s' is already registered"(command));

        privMessageHandler_.commandHandlers[command] = handler;
    }

    void handleMessage(PrivMessage message) {
        privMessageHandler_.handle(message, config.cmdPrefix);
    }
}
