// providers/ar_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' as vector_math;

// ──────────────────────────────────────────────
// Data Models
// ──────────────────────────────────────────────

class PlantInfo {
  final String id;
  final String name;
  final String displayName;

  /// GitHub raw URL — used as download source and as a fallback if local file
  /// has not been cached yet.
  final String remoteModelUrl;
  final IconData icon;
  final vector_math.Vector3 scale;

  const PlantInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.remoteModelUrl,
    required this.icon,
    required this.scale,
  });
}

class PlacedPlant {
  final String id;
  final String plantType;
  final String nodeName;
  final ARPlaneAnchor anchor;
  final vector_math.Vector3 position;
  final PlantInfo plantInfo;

  const PlacedPlant({
    required this.id,
    required this.plantType,
    required this.nodeName,
    required this.anchor,
    required this.position,
    required this.plantInfo,
  });
}

class PlantDetails {
  final String name;
  final String benefits;
  final String usage;
  final String description;
  final bool isLoading;
  final String? error;

  const PlantDetails({
    required this.name,
    required this.benefits,
    required this.usage,
    required this.description,
    this.isLoading = false,
    this.error,
  });

  PlantDetails copyWith({
    String? name,
    String? benefits,
    String? usage,
    String? description,
    bool? isLoading,
    String? error,
  }) {
    return PlantDetails(
      name: name ?? this.name,
      benefits: benefits ?? this.benefits,
      usage: usage ?? this.usage,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ARState {
  final ARSessionManager? arSessionManager;
  final ARObjectManager? arObjectManager;
  final ARAnchorManager? arAnchorManager;
  final ARLocationManager? arLocationManager;
  final bool isARReady;
  final bool isInitializing;

  const ARState({
    this.arSessionManager,
    this.arObjectManager,
    this.arAnchorManager,
    this.arLocationManager,
    this.isARReady = false,
    this.isInitializing = true,
  });

  ARState copyWith({
    ARSessionManager? arSessionManager,
    ARObjectManager? arObjectManager,
    ARAnchorManager? arAnchorManager,
    ARLocationManager? arLocationManager,
    bool? isARReady,
    bool? isInitializing,
  }) {
    return ARState(
      arSessionManager: arSessionManager ?? this.arSessionManager,
      arObjectManager: arObjectManager ?? this.arObjectManager,
      arAnchorManager: arAnchorManager ?? this.arAnchorManager,
      arLocationManager: arLocationManager ?? this.arLocationManager,
      isARReady: isARReady ?? this.isARReady,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

// ──────────────────────────────────────────────
// Plant catalogue (static data)
// ──────────────────────────────────────────────

const _kGitHubBase =
    'https://raw.githubusercontent.com/torichoudhury/plant_arvr/master/assets';

final plantsProvider = Provider<List<PlantInfo>>((ref) {
  return [
    PlantInfo(
      id: 'neem',
      name: 'neem',
      displayName: 'Neem',
      remoteModelUrl: '$_kGitHubBase/neem.glb',
      icon: Icons.park,
      scale: vector_math.Vector3(0.8, 0.15, 0.15),
    ),
    PlantInfo(
      id: 'tulsi',
      name: 'tulsi',
      displayName: 'Tulsi',
      remoteModelUrl: '$_kGitHubBase/basil.glb',
      icon: Icons.local_florist,
      scale: vector_math.Vector3(0.4, 0.1, 0.1),
    ),
    PlantInfo(
      id: 'rosemary',
      name: 'rosemary',
      displayName: 'Rosemary',
      remoteModelUrl: '$_kGitHubBase/rosemary.glb',
      icon: Icons.spa,
      scale: vector_math.Vector3(0.3, 0.1, 0.1),
    ),
    PlantInfo(
      id: 'eucalyptus',
      name: 'eucalyptus',
      displayName: 'Eucalyptus',
      remoteModelUrl: '$_kGitHubBase/eucalyptus.glb',
      icon: Icons.nature,
      scale: vector_math.Vector3(0.4, 0.15, 0.15),
    ),
    PlantInfo(
      id: 'aloe_vera',
      name: 'aloe_vera',
      displayName: 'Aloe Vera',
      remoteModelUrl: '$_kGitHubBase/aloe_vera.glb',
      icon: Icons.eco,
      scale: vector_math.Vector3(0.3, 0.08, 0.08),
    ),
  ];
});

/// Convenience map: plantId → remote URL, used by the asset-cache service.
final plantRemoteUrlsProvider = Provider<Map<String, String>>((ref) {
  return {
    for (final p in ref.watch(plantsProvider)) p.id: p.remoteModelUrl,
  };
});

final currentPlantInfoProvider = Provider<PlantInfo>((ref) {
  final selectedPlant = ref.watch(selectedPlantProvider);
  final plants = ref.watch(plantsProvider);
  return plants.firstWhere(
    (plant) => plant.id == selectedPlant,
    orElse: () => plants.first,
  );
});

// ──────────────────────────────────────────────
// State Providers
// ──────────────────────────────────────────────

final arStateProvider =
    StateNotifierProvider<ARStateNotifier, ARState>((ref) {
  return ARStateNotifier();
});

final statusProvider =
    StateNotifierProvider<StatusNotifier, String>((ref) {
  return StatusNotifier();
});

final selectedPlantProvider =
    StateNotifierProvider<SelectedPlantNotifier, String>((ref) {
  return SelectedPlantNotifier();
});

/// Single source of truth for placed plants.
/// Replaces the old separate objectCountProvider + placedAnchorsProvider.
final placedPlantsProvider =
    StateNotifierProvider<PlacedPlantsNotifier, List<PlacedPlant>>((ref) {
  return PlacedPlantsNotifier();
});

/// Derived count — no separate counter state needed.
final objectCountProvider = Provider<int>((ref) {
  return ref.watch(placedPlantsProvider).length;
});

/// Derived anchors list — kept for AR cleanup loops.
final placedAnchorsProvider = Provider<List<ARPlaneAnchor>>((ref) {
  return ref.watch(placedPlantsProvider).map((p) => p.anchor).toList();
});

final plantDetailsProvider =
    StateNotifierProvider<PlantDetailsNotifier, PlantDetails?>((ref) {
  return PlantDetailsNotifier();
});

final showPlantDetailsProvider =
    StateNotifierProvider<ShowPlantDetailsNotifier, bool>((ref) {
  return ShowPlantDetailsNotifier();
});

/// In-memory cache: resolvedUri (local path or remote URL) → ARNode template.
/// Avoids re-constructing node objects on every placement.
final modelCacheProvider =
    StateNotifierProvider<ModelCacheNotifier, Map<String, ARNode>>((ref) {
  return ModelCacheNotifier();
});

// ──────────────────────────────────────────────
// State Notifiers
// ──────────────────────────────────────────────

class ARStateNotifier extends StateNotifier<ARState> {
  Timer? _statusTimer;

  ARStateNotifier() : super(const ARState());

  void setManagers({
    required ARSessionManager arSessionManager,
    required ARObjectManager arObjectManager,
    required ARAnchorManager arAnchorManager,
    required ARLocationManager arLocationManager,
  }) {
    state = state.copyWith(
      arSessionManager: arSessionManager,
      arObjectManager: arObjectManager,
      arAnchorManager: arAnchorManager,
      arLocationManager: arLocationManager,
    );
  }

  void setARReady(bool isReady) => state = state.copyWith(isARReady: isReady);

  void setInitializing(bool isInitializing) =>
      state = state.copyWith(isInitializing: isInitializing);

  void startStatusTimer(StatusNotifier statusNotifier) {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state.isInitializing) {
        final current = statusNotifier.state;
        if (current.contains('Starting')) {
          statusNotifier.updateStatus('Initializing camera and sensors...');
        } else if (current.contains('Initializing')) {
          statusNotifier.updateStatus('Detecting environment...');
        } else {
          statusNotifier.updateStatus(
              'Point camera at textured flat surfaces');
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}

class StatusNotifier extends StateNotifier<String> {
  StatusNotifier() : super('Starting AR session...');

  void updateStatus(String status) => state = status;
}

class SelectedPlantNotifier extends StateNotifier<String> {
  SelectedPlantNotifier() : super('neem');

  void selectPlant(String plantId) => state = plantId;
}

/// Manages placed plants as the single authoritative list.
/// objectCount and placedAnchors are derived from this.
class PlacedPlantsNotifier extends StateNotifier<List<PlacedPlant>> {
  PlacedPlantsNotifier() : super([]);

  void addPlacedPlant(PlacedPlant plant) {
    state = [...state, plant];
  }

  void removePlant(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void clearAll() => state = [];

  int get count => state.length;

  PlacedPlant? findByNodeName(String nodeName) {
    try {
      return state.firstWhere((p) => p.nodeName == nodeName);
    } catch (_) {
      return null;
    }
  }
}

class ModelCacheNotifier extends StateNotifier<Map<String, ARNode>> {
  ModelCacheNotifier() : super({});

  void cacheModel(String uri, ARNode node) {
    state = {...state, uri: node};
  }

  ARNode? getCachedModel(String uri) => state[uri];

  bool isCached(String uri) => state.containsKey(uri);
}

class PlantDetailsNotifier extends StateNotifier<PlantDetails?> {
  PlantDetailsNotifier() : super(null);

  void setPlantDetails(PlantDetails details) => state = details;

  void setLoading(bool isLoading) {
    if (state != null) state = state!.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    if (state != null) {
      state = state!.copyWith(error: error, isLoading: false);
    }
  }

  void clearDetails() => state = null;
}

class ShowPlantDetailsNotifier extends StateNotifier<bool> {
  ShowPlantDetailsNotifier() : super(false);

  void show() => state = true;
  void hide() => state = false;
  void toggle() => state = !state;
}
