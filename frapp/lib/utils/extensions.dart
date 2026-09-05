import 'dart:io';
import 'package:flutter/material.dart';

extension FileExtension on File {
  String get fileExtension {
    return path.split('.').last.toLowerCase();
  }
  
  bool isImage() {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp'];
    return imageExtensions.contains(fileExtension);
  }
  
  bool isVideo() {
    const videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'webm'];
    return videoExtensions.contains(fileExtension);
  }
  
  bool isDocument() {
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    return documentExtensions.contains(fileExtension);
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}