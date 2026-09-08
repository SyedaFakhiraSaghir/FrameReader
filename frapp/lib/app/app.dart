import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/media/media_bloc.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/dictionary/dictionary_bloc.dart';
import '../repositories/dictionary_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/ocr_repository.dart';
import '../services/service_locator.dart';
import 'routes.dart';
import 'theme.dart';

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MediaBloc>(
          create: (context) => MediaBloc(getIt<MediaRepository>()),
        ),
        BlocProvider<OCRBloc>(
          create: (context) => OCRBloc(getIt<OCRRepository>()),
        ),
        BlocProvider<DictionaryBloc>(
          create: (context) => DictionaryBloc(getIt<DictionaryRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'OCR Translator',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}