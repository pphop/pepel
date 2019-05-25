module pepel.module_.customcmd.handler;

import std.algorithm;
import std.array;
import std.format;
import std.traits;
import std.typecons;

import vibe.data.json;
import vibe.http.client;
import vibe.stream.operations;

import pepel.common;
import pepel.module_.module_;

Module.Command.Handler handler(string formatString) {
    return (ref Message m) {
        import std.exception : ifThrown;

        return Response(formatString.formatReply(m)
                .ifThrown(e => "could not interpret command string: %s".format(e.message))).Action;
    };
}

string formatReply(F : Formatter!Args = DefaultFormatter, Args...)(
        string formatString, ref Message msg) {
    import std.exception : enforce;

    enforce(formatString.balancedParens('{', '}'), "unbalanced parens");

    return F.format(formatString, msg);
}

// dfmt off
alias DefaultFormatter = Formatter!(
    "{args.%d}", (ref Message msg, int i) {
        import std.exception : enforce;

        enforce(msg.args.length > i, "not enough arguments");
        return msg.args[i]; 
    },
    "{rand(%d)}", (int max) {
        import std.random : uniform;

        return uniform!"[]"(0, max);
    },
    "{rand(%d, %d)}", (int min, int max) {
        import std.random : uniform;

        return uniform!"[]"(min, max);
    },
    "{get(%s).%s}", (string url, string scheme) {
        string result;
        requestHTTP(url, (scope req) { req.method = HTTPMethod.GET; }, (scope res) {
            auto raw = res.bodyReader.readAllUTF8();

            if (scheme == "RAW") {
                result = raw;
                return;
            }

            auto j = raw.parseJsonString();

            auto keys = scheme.split(".");
            foreach (key; keys)
                j = j[key];

            result = j.get!string;
        });
        return result;
    });
// dfmt on

struct Formatter(T...) {
    static string format(string formatString, ref Message msg) {
        import std.conv : to;

        auto res = formatString;
        static foreach (i, fmt; T) {
            static if (is(typeof(fmt) == string)) {
                foreach (match; res.matches(fmt)) {
                    res = res.replace(match, call!(T[i + 1], fmt)(msg, match).to!string);
                }
            }
        }
        return res;
    }
}

template call(alias c, string fmt)
        if (isCallable!c) {

    alias Params = Parameters!c;

    auto call(ref Message msg, string match) {
        static if (Params.length == 0) {
            return c();
        }
        else static if (fmt.canFind('%')) {
            static if (is(Params[0] == Message))
                alias ToReadTypes = Params[1 .. $];
            else
                alias ToReadTypes = Params;

            Tuple!ToReadTypes t;
            match.formattedRead!fmt(t.expand);

            static if (is(Params[0] == Message))
                return c(msg, t.expand);
            else
                return c(t.expand);
        }
        else {
            return c(msg);
        }
    }
}

string[] matches(string haystack, string fmt) {
    import std.conv : to;
    import std.regex : escaper, matchAll, regex;

    if (!fmt.canFind('%'))
        return [fmt];

    string regexStr;
    auto f = FormatSpec!char(fmt);
    auto a = appender!string();

    while (f.writeUpToNextSpec(a)) {
        regexStr ~= a.data.escaper.array.to!string;
        switch (f.spec) {
        case 'd':
            regexStr ~= `\d+`;
            break;
        case 's':
            regexStr ~= `[\w.:\/]+`;
            break;
        default:
            assert(0);
        }
        a = appender!string();
    }
    regexStr ~= a.data.escaper.array.to!string;

    return haystack.matchAll(regex(regexStr)).map!(c => c.hit).array;
}

unittest {
    auto fmtStr = "test {args.1} test";

    alias F = Formatter!("{args.%d}", (ref Message msg, int i) {
        return msg.args[i];
    });

    auto mockMsg = Message();
    mockMsg.text = "!qwerty asd qwerty";

    auto actual = F.format(fmtStr, mockMsg);
    auto expected = "test asd test";
    assert(actual == expected, "`%s` != `%s`".format(actual, expected));
}
