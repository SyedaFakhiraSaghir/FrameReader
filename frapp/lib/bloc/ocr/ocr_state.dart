import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../models/ocr_result.dart';

abstract class OCRState extends Equatable {
  const OCRState();

  @override
  List<Object?> get props => [];
}

class OCRInitial extends OCRState {}

class OCRLoading extends OCRState {}

class OCRCompleted extends OCRState {
  final OCRResult result;
  final Uint8List? imageBytes;

  const OCRCompleted({
    required this.result,
    this.imageBytes,
  });

  @override
  List<Object?> get props => [result, imageBytes];
}

class OCRError extends OCRState {
  final String message;

  const OCRError(this.message);

  @override
  List<Object?> get props => [message];
}
