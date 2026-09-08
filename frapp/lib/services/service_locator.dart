import 'package:get_it/get_it.dart';

import '../repositories/dictionary_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/ocr_repository.dart';
import 'dictionary_service.dart';
import 'language_service.dart';
import 'media_service.dart';
import 'ocr_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  if (getIt.isRegistered<LanguageService>()) return;

  getIt.registerLazySingleton<LanguageService>(() => LanguageService());
  getIt.registerLazySingleton<MediaService>(() => MediaService());
  getIt.registerLazySingleton<OCRService>(() => OCRService());
  getIt.registerLazySingleton<DictionaryService>(() => DictionaryService());
  getIt.registerLazySingleton<MediaRepository>(() => MediaRepository());
  getIt.registerLazySingleton<OCRRepository>(
    () => OCRRepository(getIt<OCRService>()),
  );
  getIt.registerLazySingleton<DictionaryRepository>(
    () => DictionaryRepository(),
  );
}
