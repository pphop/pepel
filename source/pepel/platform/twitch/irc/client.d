module pepel.platform.twitch.irc.client;

import vibe.core.core;
import vibe.core.net;
import vibe.stream.operations;

import pepel.platform.twitch.irc.message;

struct IRCClient {
private:
    TCPConnection _conn;
    string _username, _token;
    void delegate(IRCMessage) _onPrivMsg;

public:
    @property void onPrivMsg(void delegate(IRCMessage) handler) {
        _onPrivMsg = handler;
    }

    void connect(string username, string token) {
        import std.algorithm : findSplitAfter;
        import std.format : format;

        _username = username;
        _token = token;
        _conn = connectTCP("irc.chat.twitch.tv", 6667u);
        write("PASS oauth:%s".format(_token));
        write("NICK %s".format(_username));
        write("CAP REQ :twitch.tv/tags");
        flush();

        runTask({
            // TODO: handle disconnect
            while (_conn.connected && _conn.waitForData) {
                auto line = cast(string) _conn.readLine();
                auto msg = line.parseMessage;

                switch (msg.type) {
                case IRCMessage.Type.privmsg:
                    _onPrivMsg(msg);
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

    void join(string[] channels) {
        foreach (channel; channels)
            write("JOIN #%s".format(channel));
        flush();
    }

    void privMsg(string channel, string text) {
        write("PRIVMSG #%s :%s".format(channel, text));
        flush();
    }

    void whisper(string username, string text) {
        privMsg(_username, "/w %s %s".format(username, text));
    }

private:
    void write(string s) {
        _conn.write("%s\r\n".format(s));
    }

    void flush() {
        _conn.flush();
    }
}
