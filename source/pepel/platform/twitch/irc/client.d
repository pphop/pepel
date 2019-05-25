module pepel.platform.twitch.irc.client;

import std.format : format;

import vibe.core.core;
import vibe.core.net;
import vibe.stream.operations;

import pepel.config;
import pepel.platform.twitch.irc.message;
import pepel.platform.twitch.irc.ratelimitter;

private RateLimitter rateLimitter;

struct IRCClient {
private:
    TCPConnection _conn;
    string _username, _token;
    void delegate(IRCMessage) _onPrivMsg;

public:
    void onPrivMsg(void delegate(IRCMessage) handler) {
        _onPrivMsg = handler;
    }

    void connect(Config.Twitch cfg, string[] channels) {
        import std.algorithm : findSplitAfter;

        _username = cfg.username;
        _token = cfg.token;
        _conn = connectTCP("irc.chat.twitch.tv", 6667u);

        runTask({
            write("PASS oauth:%s".format(_token));
            write("NICK %s".format(_username));
            write("CAP REQ :twitch.tv/tags");
            join(_username);
            foreach (ch; channels)
                join(ch);

            // TODO: handle disconnect
            while (_conn.connected && _conn.waitForData) {
                auto line = cast(string) _conn.readLine();
                auto msg = line.parseMessage;

                switch (msg.type) {
                case IRCMessage.Type.privmsg:
                    runTask({ _onPrivMsg(msg); });
                    break;
                case IRCMessage.Type.ping:
                    write("PONG :%s".format(msg.raw.findSplitAfter(" ")[1]));
                    break;
                default:
                    // TODO: propper logging / w/e
                    import std.stdio : writeln;

                    writeln("ircclient ", msg.raw);
                }
            }
        });
    }

    void close() {
        _conn.close();
    }

    void join(string channel) {
        write("JOIN #%s".format(channel));
    }

    void part(string channel) {
        write("PART #%s".format(channel));
    }

    void privMsg(string channel, string text) {
        write("PRIVMSG #%s :%s".format(channel, text));
    }

    void whisper(string username, string text) {
        privMsg(_username, "/w %s %s".format(username, text));
    }

private:
    void write(string s) {
        rateLimitter.wait();
        _conn.write("%s\r\n".format(s));
        flush();
    }

    void flush() {
        _conn.flush();
    }
}
