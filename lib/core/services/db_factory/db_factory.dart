/// Selects the right database-factory setup at compile time:
/// native platforms keep the sqflite plugin, web swaps in the WASM backend.
library;

export 'configure_native.dart'
    if (dart.library.js_interop) 'configure_web.dart';
