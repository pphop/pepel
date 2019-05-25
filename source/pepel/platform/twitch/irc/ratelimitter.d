module pepel.platform.twitch.irc.ratelimitter;

import std.datetime;

import vibe.core.core;

// TODO: different rate limits depending on a bot status 
struct RateLimitter {
private:
    long lastAccess;
    static Duration repeat = (cast(long)(30.0f / 20.0f * 1000.0f)).msecs;

public:
    void wait() {
        while (true) {
            auto now = Clock.currStdTime;
            auto t = now - lastAccess;
            if (t > repeat.total!"hnsecs") {
                lastAccess = now;
                return;
            }

            auto waitDuration = repeat - t.hnsecs;
            if (waitDuration.total!"hnsecs" > 0)
                sleep(waitDuration);
        }
    }
}
