module pepel.modules.udas;

import pepel.message;

struct moduleName {
    string name;
}

struct helpMsg {
    string text;
}

// not implemented yet
struct moduleVar {
    string name;
}

struct on {
    MessageType type;
}

struct always {
}

struct contains {
    string contains;
}

struct command {
    string command;
}

struct lvlReq {
    UserLevel lvl;
}
