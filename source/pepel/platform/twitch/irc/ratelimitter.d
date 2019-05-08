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

unittest {
    import std.datetime.stopwatch;
    import vibe.core.core;

    StopWatch sw;
    RateLimitter rl;

    auto d = rl.repeat;

    runTask({
        sw.start();
        rl.wait();
        assert(sw.peek >= 0.msecs && sw.peek < d);
        rl.wait();
        assert(sw.peek >= d && sw.peek < d * 2);
        rl.wait();
        assert(sw.peek >= d * 2 && sw.peek < d * 3);
        sw.stop();
    }).join();
}
