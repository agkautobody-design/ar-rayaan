/// Non-web builds cannot restart themselves from inside; the caller hides
/// the button there, so this is never invoked on those platforms.
void restartApp() {}
