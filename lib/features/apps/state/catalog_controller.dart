import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_package.dart';
import '../services/app_catalog_service.dart';

final Provider<AppCatalogService> appCatalogServiceProvider =
    Provider<AppCatalogService>((Ref ref) => AppCatalogService());

class CatalogController extends AsyncNotifier<List<CatalogPackage>> {
  @override
  Future<List<CatalogPackage>> build() {
    return ref.watch(appCatalogServiceProvider).fetchCatalog();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final AsyncNotifierProvider<CatalogController, List<CatalogPackage>>
catalogProvider =
    AsyncNotifierProvider<CatalogController, List<CatalogPackage>>(
      CatalogController.new,
    );
