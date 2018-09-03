module pepel.internal;

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}
