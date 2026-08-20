import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_store.dart';

final Provider<SecureKeyValueStore> secureStorageProvider =
    Provider<SecureKeyValueStore>(
      (Ref ref) => const FlutterSecureKeyValueStore(FlutterSecureStorage()),
    );
