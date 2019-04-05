module pepel.main;

import std.stdio;

import pepel.config;

void main() {
    auto cfg = Config("monkas.json");
    writeln("hello world!");
}
