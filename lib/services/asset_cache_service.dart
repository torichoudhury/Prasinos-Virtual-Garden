// services/asset_cache_service.dart
//
// Downloads GLB plant assets from GitHub to the device's local storage once,
// then serves local file paths on subsequent launches for near-instant placement.

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// ──────────────────────────────────────────────
// Model: per-plant download state
// ──────────────────────────────────────────────

enum AssetStatus { idle, downloading, ready, error }

class AssetDownloadState {
  final String plantId;
  final AssetStatus status;
  final double progress; // 0.0 – 1.0
  final String? localPath;
  final String? error;

  const AssetDownloadState({
    required this.plantId,
    this.status = AssetStatus.idle,
    this.progress = 0,
    this.localPath,
    this.error,
  });

  AssetDownloadState copyWith({
    AssetStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) {
    return AssetDownloadState(
      plantId: plantId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
    );
  }

  bool get isReady => status == AssetStatus.ready;
  bool get isDownloading => status == AssetStatus.downloading;
}

// ──────────────────────────────────────────────
// Provider: map of plantId → download state
// ──────────────────────────────────────────────

final assetCacheProvider =
    StateNotifierProvider<AssetCacheNotifier, Map<String, AssetDownloadState>>(
  (ref) => AssetCacheNotifier(),
);

// Convenience provider: true when ALL assets are locally available
final allAssetsReadyProvider = Provider<bool>((ref) {
  final states = ref.watch(assetCacheProvider);
  if (states.isEmpty) return false;
  return states.values.every((s) => s.isReady);
});

// ──────────────────────────────────────────────
// Service / Notifier
// ──────────────────────────────────────────────

class AssetCacheNotifier
    extends StateNotifier<Map<String, AssetDownloadState>> {
  AssetCacheNotifier() : super({});

  /// Registers the plant IDs we care about and checks which are already cached.
  Future<void> initialise(Map<String, String> plantRemoteUrls) async {
    final cacheDir = await _cacheDirectory();

    // Build initial state – check if files are already on disk
    final initial = <String, AssetDownloadState>{};
    for (final entry in plantRemoteUrls.entries) {
      final plantId = entry.key;
      final file = File(_localPath(cacheDir, plantId));
      if (await file.exists() && await file.length() > 0) {
        initial[plantId] = AssetDownloadState(
          plantId: plantId,
          status: AssetStatus.ready,
          progress: 1.0,
          localPath: file.path,
        );
      } else {
        initial[plantId] = AssetDownloadState(
          plantId: plantId,
          status: AssetStatus.idle,
        );
      }
    }
    state = initial;
  }

  /// Downloads all plants sequentially so background downloads don't
  /// saturate the connection while the user is placing plants.
  Future<void> downloadAll(Map<String, String> plantRemoteUrls) async {
    for (final entry in plantRemoteUrls.entries) {
      final plantId = entry.key;
      final current = state[plantId];
      if (current == null || current.isReady || current.isDownloading) continue;
      await _downloadOne(plantId, entry.value);
    }
  }

  /// Downloads (or re-downloads) a single plant asset.
  Future<void> downloadOne(String plantId, String remoteUrl) async {
    await _downloadOne(plantId, remoteUrl);
  }

  Future<void> _downloadOne(String plantId, String remoteUrl) async {
    _update(
      plantId,
      (s) => s.copyWith(status: AssetStatus.downloading, progress: 0),
    );

    try {
      final cacheDir = await _cacheDirectory();
      final targetFile = File(_localPath(cacheDir, plantId));

      // IMPORTANT: http.Client.send() does NOT follow HTTP redirects.
      // GitHub raw.githubusercontent.com issues 301/302 redirects, so the
      // old streaming approach wrote 0-byte files and placement always failed.
      // http.get() follows redirects automatically.
      _update(plantId, (s) => s.copyWith(progress: 0.05));
      final response = await http.get(Uri.parse(remoteUrl));

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode} when downloading $plantId');
      }

      _update(plantId, (s) => s.copyWith(progress: 0.9));
      await targetFile.writeAsBytes(response.bodyBytes);

      _update(
        plantId,
        (s) => s.copyWith(
          status: AssetStatus.ready,
          progress: 1.0,
          localPath: targetFile.path,
        ),
      );
    } catch (e) {
      _update(
        plantId,
        (s) => s.copyWith(
          status: AssetStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Returns the local file path for a plant if already cached, otherwise null.
  String? localPathFor(String plantId) {
    return state[plantId]?.localPath;
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  void _update(
    String plantId,
    AssetDownloadState Function(AssetDownloadState) updater,
  ) {
    final current = state[plantId];
    if (current == null) return;
    state = {...state, plantId: updater(current)};
  }

  static Future<Directory> _cacheDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/plant_glb_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _localPath(Directory cacheDir, String plantId) {
    return '${cacheDir.path}/$plantId.glb';
  }
}
