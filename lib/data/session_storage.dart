import 'session_storage_contract.dart';
import 'session_storage_io.dart'
    if (dart.library.html) 'session_storage_web.dart' as platform;

export 'session_storage_contract.dart';

SessionStorage createSessionStorage(String key) =>
    platform.createSessionStorage(key);
