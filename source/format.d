module pepel.format;

struct Formatter(T, string[] fmtmappings)
        if (mappingIsValid!(T, fmtmappings)) {
    import std.algorithm : map;
    import std.array : split;
    import std.string : strip;
    import std.regex : regex;

    // doesnt work for some reason, seems to be a problem with a compiler
    // private alias parsePairs = map!(a => a.split(">").map!strip);
    // static foreach (mapping; parsePairs(fmtmappings)) {
    // mixin(`private auto _regex` ~ mapping[1] ~ ` = ctRegex!("{` ~ mapping[0] ~ `}");`);
    // }
    mixin(generateRegexFields!fmtmappings);

    string format(string fmt, T value) {
        import std.conv : to;
        import std.regex : replaceAll;

        static foreach (mapping; fmtmappings.map!(a => a.split(">").map!strip)) {
            fmt = fmt.replaceAll!(m => mixin("value." ~ mapping[1] ~ ".to!string"))(
                    mixin("_regex" ~ mapping[1]));
        }
        return fmt;
    }
}

private template generateRegexFields(string[] mappings) {
    enum generateRegexFields = gen();

    private string gen() {
        import std.algorithm : joiner, map;
        import std.array : split;
        import std.conv : to;
        import std.string : format, strip;

        string res = mappings.map!(a => a.split(">").map!strip)
            .map!(a => format!`private static _regex%s = regex("\\{%s\\}");`(a[1], a[0]))
            .joiner("\n").to!string;
        return res;
    }
}

// maybe check if able to .to!string a field
private bool mappingIsValid(T, string[] mappings)() {
    import std.algorithm : map, sort, uniq;
    import std.array : array, split;
    import std.string : format, strip;

    static foreach (mapping; mappings) {
        {
            enum mSplit = mapping.split(">").map!strip.array;
            static assert(mSplit.length == 2, "mapping syntax is invalid");
            static assert(__traits(compiles, mixin("T." ~ mSplit[1])),
                    format!"there is no '%s' field for type %s"(mSplit[1], T.stringof));
        }
    }
    static assert(mappings.map!(a => a.split(">").map!strip[0])
            .array.sort.uniq.array.length == mappings.length, "mapping contains repeating patterns");
    return true;
}

unittest {
    struct S {
        string a;
        string b;
    }

    assert(!__traits(compiles, Formatter!(S, ["qwe > fieldThatDoesntExist"])()));
    assert(!__traits(compiles, Formatter!(S, ["repeating mapping > a",
            "repeating mapping > b"])()));

    auto f = Formatter!(S, ["fielda > a", "s.fieldb > b"])();

    auto s1 = S("qwe", "rty");
    auto fmtstr = "{fielda} {s.fieldb}";
    auto expected = "qwe rty";
    auto got = f.format(fmtstr, s1);
    assert(got == expected);
}
