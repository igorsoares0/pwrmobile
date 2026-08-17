import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `XFile` comes from share_plus's own export, so cross_file need not be a
// direct dependency.
import 'package:share_plus/share_plus.dart';

/// Hands an image to the operating system's share sheet.
///
/// An interface, not a direct `SharePlus` call, so the share card can be tested
/// end to end: a widget test can capture the real PNG and assert what would
/// have been shared without a platform channel in sight.
abstract interface class ShareService {
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  });

  /// Hands a generated text file — the CSV export — to the share sheet.
  ///
  /// Sharing rather than saving to a path: on both platforms the share sheet
  /// is where "put this in Drive", "mail it to myself" and "save to Files"
  /// already live, and none of them need a storage permission this way.
  Future<void> shareText(
    String contents, {
    required String fileName,
    required String mimeType,
    String? subject,
  });
}

/// The real thing: the platform share sheet (spec §16).
class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  }) async {
    // `XFile.fromData` keeps the PNG in memory rather than writing it to disk.
    // A share card is a one-shot artefact; a temp file would outlive the share
    // and need cleaning up.
    final file = XFile.fromData(bytes, name: fileName, mimeType: 'image/png');

    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        subject: subject,
      ),
    );
  }

  @override
  Future<void> shareText(
    String contents, {
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    // UTF-8 with a BOM. Excel on Windows reads a BOM-less UTF-8 CSV as the
    // system codepage, which turns every "Rosca direta com halteres" into
    // mojibake — and a Brazilian user's exercise names are full of accents.
    final bytes = Uint8List.fromList([
      ...utf8.encode('\uFEFF'),
      ...utf8.encode(contents),
    ]);

    final file = XFile.fromData(bytes, name: fileName, mimeType: mimeType);

    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        subject: subject,
      ),
    );
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const SystemShareService(),
);

/// Rasterises the widget under [key] to PNG bytes.
///
/// Returns null when the boundary is not laid out yet — which happens if this
/// is called before the first frame that paints the card.
Future<Uint8List?> captureBoundary(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  // Rendered at 3x so the exported image survives being viewed full-screen on
  // a high-density phone; the card's own layout stays in logical pixels.
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
