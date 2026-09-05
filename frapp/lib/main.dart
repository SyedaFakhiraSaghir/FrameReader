import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'app/app.dart';
import 'repositories/dictionary_repository.dart';
import 'repositories/media_repository.dart';
import 'repositories/ocr_repository.dart';
import 'services/dictionary_service.dart';
import 'services/language_service.dart';
import 'services/media_service.dart';
import 'services/ocr_service.dart';

final getIt = GetIt.instance;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const OCRApp());
}

void setupDependencies() {
  // Services
  getIt.registerLazySingleton<LanguageService>(() => LanguageService());
  getIt.registerLazySingleton<MediaService>(() => MediaService());
  getIt.registerLazySingleton<OCRService>(() => OCRService());
  getIt.registerLazySingleton<DictionaryService>(() => DictionaryService());
  
  // Repositories
  getIt.registerLazySingleton<MediaRepository>(() => MediaRepository());
  getIt.registerLazySingleton<OCRRepository>(() => OCRRepository());
  getIt.registerLazySingleton<DictionaryRepository>(() => DictionaryRepository());
}