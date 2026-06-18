import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider resolveImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  } else {
    return FileImage(File(path));
  }
}
