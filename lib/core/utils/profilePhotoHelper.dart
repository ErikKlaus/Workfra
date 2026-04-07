import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../constants/apiKonstanta.dart';

class ProfilePhotoHelper {
  const ProfilePhotoHelper._();

  static String? extractPhotoSource(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['photo_url'],
      json['profile_photo_url'],
      json['profile_photo'],
      json['photo_profile'],
      json['avatar_url'],
      json['avatar'],
      json['photo'],
      json['image'],
    ];

    for (final candidate in candidates) {
      if (candidate is String) {
        final normalized = normalizePhotoSource(candidate);
        if (normalized != null) return normalized;
      }

      if (candidate is Map<String, dynamic>) {
        final nested = candidate['url'] ?? candidate['path'];
        if (nested is String) {
          final normalized = normalizePhotoSource(nested);
          if (normalized != null) return normalized;
        }
      }
    }

    return null;
  }

  static String? normalizePhotoSource(String? value) {
    if (value == null) return null;

    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('data:image')) {
      return cleaned;
    }

    if (cleaned.startsWith('//')) {
      return 'https:$cleaned';
    }

    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && parsed.hasScheme) {
      return cleaned;
    }

    if (cleaned.startsWith('/')) {
      return '${ApiConstants.baseUrl}$cleaned';
    }

    final relative = cleaned.replaceFirst(RegExp(r'^/+'), '');
    return '${ApiConstants.baseUrl}/$relative';
  }

  static ImageProvider<Object>? toImageProvider(String? source) {
    final normalized = normalizePhotoSource(source);
    if (normalized == null) return null;

    if (normalized.startsWith('data:image')) {
      final bytes = _decodeDataUrl(normalized);
      if (bytes == null) return null;
      return MemoryImage(bytes);
    }

    return NetworkImage(normalized);
  }

  static Uint8List? _decodeDataUrl(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1 || commaIndex == dataUrl.length - 1) {
      return null;
    }

    final base64Payload = dataUrl.substring(commaIndex + 1).trim();
    if (base64Payload.isEmpty) return null;

    try {
      return base64Decode(base64Payload);
    } catch (_) {
      return null;
    }
  }
}
