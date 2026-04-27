// Main App Widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:plant_arvr/providers/ar_providers.dart';
import 'package:plant_arvr/services/asset_cache_service.dart';
import 'package:plant_arvr/data/local_plant_data.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'dart:async';
import 'package:plant_arvr/widgets/ar_chatbot.dart';
class ImprovedARTest extends ConsumerStatefulWidget {
  const ImprovedARTest({Key? key}) : super(key: key);

  @override
  ConsumerState<ImprovedARTest> createState() => _ImprovedARTestState();
}

class _ImprovedARTestState extends ConsumerState<ImprovedARTest>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start AR status cycling
      final arStateNotifier = ref.read(arStateProvider.notifier);
      final statusNotifier = ref.read(statusProvider.notifier);
      arStateNotifier.startStatusTimer(statusNotifier);

      // Kick off background asset downloads so local files are ready
      // before the user first taps to place a plant.
      _preloadAssets();
    });
  }

  Future<void> _preloadAssets() async {
    final remoteUrls = ref.read(plantRemoteUrlsProvider);
    final cacheNotifier = ref.read(assetCacheProvider.notifier);
    // Check disk, then download anything missing in background.
    await cacheNotifier.initialise(remoteUrls);
    cacheNotifier.downloadAll(remoteUrls);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(arStateProvider.notifier).dispose();
    _cleanupAR();
    super.dispose();
  }

  Future<void> _cleanupAR() async {
    final arState = ref.read(arStateProvider);
    final placedAnchors = ref.read(placedAnchorsProvider);
    final placedPlantsNotifier = ref.read(placedPlantsProvider.notifier);
    final plantDetailsNotifier = ref.read(plantDetailsProvider.notifier);
    final showPlantDetailsNotifier = ref.read(showPlantDetailsProvider.notifier);

    if (arState.arObjectManager != null && arState.arAnchorManager != null) {
      for (final anchor in placedAnchors) {
        await arState.arAnchorManager!.removeAnchor(anchor);
      }
    }
    placedPlantsNotifier.clearAll();
    plantDetailsNotifier.clearDetails();
    showPlantDetailsNotifier.hide();
    arState.arSessionManager?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("App paused - AR session may be affected");
    } else if (state == AppLifecycleState.resumed) {
      print("App resumed");
    }
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) async {
    final arStateNotifier = ref.read(arStateProvider.notifier);
    final statusNotifier = ref.read(statusProvider.notifier);

    arStateNotifier.setManagers(
      arSessionManager: arSessionManager,
      arObjectManager: arObjectManager,
      arAnchorManager: arAnchorManager,
      arLocationManager: arLocationManager,
    );

    print("AR View Created - Starting initialization...");

    try {
      // Improved AR initialization with better settings
      await arSessionManager.onInitialize(
        showFeaturePoints: false, // Reduce rendering load
        showPlanes: true,
        showWorldOrigin: false,
        handlePans: false,
        handleRotation: false,
        handleTaps: true,
        // Add these parameters if available
        // maxImages: 2, // Limit buffer size
        // enableAutoFocus: true,
      );

      await arObjectManager.onInitialize();

      // Single short delay for sensor warmup — 1 s is sufficient
      await Future.delayed(const Duration(milliseconds: 800));

      arSessionManager.onPlaneOrPointTap = onPlaneTap;
      arObjectManager.onNodeTap = onNodeTap;

      arStateNotifier.setARReady(true);
      arStateNotifier.setInitializing(false);

      final selectedPlant = ref.read(selectedPlantProvider);
      final plants = ref.read(plantsProvider);
      final plantInfo = plants.firstWhere((p) => p.id == selectedPlant);
      statusNotifier.updateStatus(
        "AR Ready! Move device slowly to scan surfaces, then tap to place ${plantInfo.displayName}",
      );

      print("AR initialization completed successfully");
    } catch (e) {
      print("AR initialization error: $e");
      arStateNotifier.setInitializing(false);
      statusNotifier.updateStatus("AR failed to initialize: $e");
    }
  }

  Future<void> onPlaneTap(List<dynamic> hitTestResults) async {
    final arState = ref.read(arStateProvider);
    final statusNotifier = ref.read(statusProvider.notifier);
    final selectedPlant = ref.read(selectedPlantProvider);
    final plants = ref.read(plantsProvider);
    final placedPlantsNotifier = ref.read(placedPlantsProvider.notifier);

    if (!arState.isARReady) {
      statusNotifier.updateStatus("AR is still initializing, please wait...");
      return;
    }

    if (hitTestResults.isEmpty) {
      statusNotifier.updateStatus(
        "No surface found - try pointing at a flat, textured surface",
      );
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          statusNotifier.updateStatus(
            "Point at flat surfaces and tap to place plants",
          );
        }
      });
      return;
    }

    statusNotifier.updateStatus("Surface detected! Placing object...");

    try {
      var hitResult = hitTestResults.first;
      var anchor = ARPlaneAnchor(transformation: hitResult.worldTransform);
      bool? didAddAnchor = await arState.arAnchorManager!.addAnchor(anchor);

      if (didAddAnchor == true) {
        final plantInfo = plants.firstWhere((p) => p.id == selectedPlant);
        final nodeName = '${selectedPlant}_${ref.read(objectCountProvider)}';

        var node = await _loadModel(
          plantInfo,
          nodeName,
        );

        bool? didAddNode = await arState.arObjectManager!.addNode(
          node!,
          planeAnchor: anchor,
        );

        if (didAddNode == true) {
          // Track the placed plant
          final placedPlant = PlacedPlant(
            id: '${selectedPlant}_${ref.read(objectCountProvider)}',
            plantType: selectedPlant,
            nodeName: nodeName,
            anchor: anchor,
            position: vector_math.Vector3(
              hitResult.worldTransform[12],
              hitResult.worldTransform[13],
              hitResult.worldTransform[14],
            ),
            plantInfo: plantInfo,
          );

          placedPlantsNotifier.addPlacedPlant(placedPlant);
          final newCount = ref.read(objectCountProvider);
          statusNotifier.updateStatus(
            "Success! ${plantInfo.displayName} #$newCount placed. Tap on plants to see details.",
          );

          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              statusNotifier.updateStatus(
                "Tap surfaces to place plants, tap info buttons for details, or tap plants for live info",
              );
            }
          });
        } else {
          statusNotifier.updateStatus("Failed to place object - try again");
        }
      } else {
        statusNotifier.updateStatus(
          "Could not anchor to surface - try a different spot",
        );
      }
    } catch (e) {
      print("Error in onPlaneTap: $e");
      statusNotifier.updateStatus("Error placing object: ${e.toString()}");
    }
  }

  Future<void> onNodeTap(List<dynamic> nodes) async {
    if (nodes.isEmpty) return;

    final tappedNode = nodes.first;
    final nodeName = tappedNode.name;

    print("Node tapped: $nodeName");

    final placedPlantsNotifier = ref.read(placedPlantsProvider.notifier);
    final plantDetailsNotifier = ref.read(plantDetailsProvider.notifier);
    final showPlantDetailsNotifier = ref.read(
      showPlantDetailsProvider.notifier,
    );
    final statusNotifier = ref.read(statusProvider.notifier);

    // Find the tapped plant
    final tappedPlant = placedPlantsNotifier.findByNodeName(nodeName);

    if (tappedPlant != null) {
      statusNotifier.updateStatus(
        "Showing ${tappedPlant.plantInfo.displayName} details...",
      );
      showPlantDetailsNotifier.show();

      try {
        // Get plant details from local data
        final localPlantData = LocalPlantData.getPlantInfo();
        final plantDetails = localPlantData[tappedPlant.plantInfo.id];

        if (plantDetails != null) {
          plantDetailsNotifier.setPlantDetails(plantDetails);
          statusNotifier.updateStatus(
            "${tappedPlant.plantInfo.displayName} details loaded!",
          );

          Timer(const Duration(seconds: 2), () {
            if (mounted) {
              statusNotifier.updateStatus(
                "Tap plants for details or surfaces to place more",
              );
            }
          });
        } else {
          // Fallback if plant data not found
          plantDetailsNotifier.setPlantDetails(
            PlantDetails(
              name: tappedPlant.plantInfo.displayName,
              benefits: "This medicinal plant has various health benefits.",
              usage: "Can be used in traditional medicine and cooking.",
              description: "A beneficial plant with medicinal properties.",
              isLoading: false,
            ),
          );
        }
      } catch (e) {
        print("Error loading plant details: $e");
        plantDetailsNotifier.setPlantDetails(
          PlantDetails(
            name: tappedPlant.plantInfo.displayName,
            benefits: "Unable to load benefits information",
            usage: "Unable to load usage information",
            description: "Unable to load description",
            isLoading: false,
            error: e.toString(),
          ),
        );
        statusNotifier.updateStatus("Error loading plant details");
      }
    }
  }

  // Method to show plant info when info button is tapped
  Future<void> _showPlantInfo(PlantInfo plant) async {
    final plantDetailsNotifier = ref.read(plantDetailsProvider.notifier);
    final showPlantDetailsNotifier = ref.read(
      showPlantDetailsProvider.notifier,
    );
    final statusNotifier = ref.read(statusProvider.notifier);

    statusNotifier.updateStatus("Loading ${plant.displayName} information...");
    showPlantDetailsNotifier.show();

    try {
      // Get plant details from local data
      final localPlantData = LocalPlantData.getPlantInfo();
      final plantDetails = localPlantData[plant.id];

      if (plantDetails != null) {
        plantDetailsNotifier.setPlantDetails(plantDetails);
        statusNotifier.updateStatus("${plant.displayName} information loaded!");

        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            statusNotifier.updateStatus(
              "Tap info buttons for plant details or surfaces to place plants",
            );
          }
        });
      } else {
        // Fallback if plant data not found
        plantDetailsNotifier.setPlantDetails(
          PlantDetails(
            name: plant.displayName,
            benefits: "This medicinal plant has various health benefits.",
            usage: "Can be used in traditional medicine and cooking.",
            description: "A beneficial plant with medicinal properties.",
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      print("Error loading plant information: $e");
      plantDetailsNotifier.setPlantDetails(
        PlantDetails(
          name: plant.displayName,
          benefits: "Unable to load benefits information",
          usage: "Unable to load usage information",
          description: "Unable to load description",
          isLoading: false,
          error: e.toString(),
        ),
      );
      statusNotifier.updateStatus("Error loading plant information");
    }
  }

  /// Resolves the best URI for a plant model:
  /// 1. Local cached file on disk  → NodeType.localGLTF2  (instant)
  /// 2. Remote GitHub URL          → NodeType.webGLB      (fallback)
  /// An in-memory ARNode template cache avoids redundant object creation.
  Future<ARNode?> _loadModel(PlantInfo plantInfo, String nodeName) async {
    final modelCacheNotifier = ref.read(modelCacheProvider.notifier);
    final statusNotifier = ref.read(statusProvider.notifier);

    try {
      // Prefer local cached file for near-instant placement.
      // IMPORTANT: ar_flutter_plugin_2's NodeType.localGLTF2 routes through
      // Android AssetManager (flutter_assets/...) which only works for bundled
      // assets. For absolute file-system paths we use NodeType.webGLB with a
      // file:// URI — Filament resolves these directly from the file system.
      final localPath =
          ref.read(assetCacheProvider.notifier).localPathFor(plantInfo.id);
      final useLocal = localPath != null;
      final resolvedUri =
          useLocal ? 'file://$localPath' : plantInfo.remoteModelUrl;
      const nodeType = NodeType.webGLB;

      // Re-use in-memory template if available
      if (modelCacheNotifier.isCached(resolvedUri)) {
        final cached = modelCacheNotifier.getCachedModel(resolvedUri)!;
        return ARNode(
          type: cached.type,
          uri: cached.uri,
          scale: plantInfo.scale,
          position: vector_math.Vector3(0.0, 0.0, 0.0),
          rotation: vector_math.Vector4(0.0, 1.0, 0.0, 0.0),
          name: nodeName,
        );
      }

      if (useLocal) {
        print('Placing ${plantInfo.id} from local cache: $resolvedUri');
      } else {
        print('Local file not ready – loading ${plantInfo.id} from remote URL');
        statusNotifier.updateStatus(
            'Downloading ${plantInfo.displayName} model (first use)…');
      }

      final node = ARNode(
        type: nodeType,
        uri: resolvedUri,
        scale: plantInfo.scale,
        position: vector_math.Vector3(0.0, 0.0, 0.0),
        rotation: vector_math.Vector4(0.0, 1.0, 0.0, 0.0),
        name: nodeName,
      );

      modelCacheNotifier.cacheModel(resolvedUri, node);
      return node;
    } catch (e) {
      print('Error loading model: $e');
      statusNotifier.updateStatus('Error loading model: $e');
      return null;
    }
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Consumer(
        builder: (context, ref, child) {
          final statusText = ref.watch(statusProvider);
          final isARReady = ref.watch(
            arStateProvider.select((state) => state.isARReady),
          );

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isARReady ? Icons.check_circle : Icons.hourglass_empty,
                      color: isARReady ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isARReady) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text(
                      "Tips for better detection",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          "• Ensure good lighting\n• Use textured surfaces\n• Move device slowly to scan\n• Try tables, floors, or books",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildObjectCounter() {
    return Positioned(
      bottom: 140, // Fixed position to avoid overlap with plant selector
      left: 16,
      right: 16,
      child: Consumer(
        builder: (context, ref, child) {
          final objectCount = ref.watch(objectCountProvider);
          final currentPlantInfo = ref.watch(currentPlantInfoProvider);

          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.green,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(currentPlantInfo.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Plants placed: $objectCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantSelector() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0,
      right: 0,
      child: Consumer(
        builder: (context, ref, child) {
          final plants = ref.watch(plantsProvider);
          return Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPlantButton(plant),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantButton(PlantInfo plant) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedPlant = ref.watch(selectedPlantProvider);
        final selectedPlantNotifier = ref.read(selectedPlantProvider.notifier);
        final statusNotifier = ref.read(statusProvider.notifier);

        return Container(
          width: 110, // Increased width to accommodate info button
          child: Row(
            children: [
              // Main plant selection button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    selectedPlantNotifier.selectPlant(plant.id);
                    statusNotifier.updateStatus(
                      "${plant.displayName} selected - tap surfaces to place or info button for details",
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedPlant == plant.id
                          ? Colors.green
                          : Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          plant.icon,
                          color: selectedPlant == plant.id
                              ? Colors.white
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            plant.displayName,
                            style: TextStyle(
                              color: selectedPlant == plant.id
                                  ? Colors.white
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Info button
              GestureDetector(
                onTap: () => _showPlantInfo(plant),
                child: Container(
                  width: 32,
                  height: 64, // Match the height of the plant button
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.info, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlantDetailsOverlay() {
    return Consumer(
      builder: (context, ref, child) {
        final showPlantDetails = ref.watch(showPlantDetailsProvider);
        final plantDetails = ref.watch(plantDetailsProvider);

        if (!showPlantDetails || plantDetails == null) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: Stack(
            children: [
              // Translucent black background
              GestureDetector(
                onTap: () {
                  ref.read(showPlantDetailsProvider.notifier).hide();
                  ref.read(plantDetailsProvider.notifier).clearDetails();
                },
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
              // Modal content
              Positioned(
                right: 16,
                top:
                    MediaQuery.of(context).padding.top +
                    80, // Below status overlay
                bottom: 220, // Above plant selector
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with plant name and close button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_florist,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plantDetails.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                ref
                                    .read(showPlantDetailsProvider.notifier)
                                    .hide();
                                ref
                                    .read(plantDetailsProvider.notifier)
                                    .clearDetails();
                              },
                              icon: const Icon(Icons.close),
                              color: Colors.white,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),

                      // Content area with chat-like messages
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Benefits message
                            _buildChatMessage(
                              "Medical Benefits",
                              plantDetails.benefits,
                              Icons.healing,
                              Colors.blue,
                            ),

                            const SizedBox(height: 12),

                            // Usage message
                            _buildChatMessage(
                              "Usage & Application",
                              plantDetails.usage,
                              Icons.info_outline,
                              Colors.orange,
                            ),

                            const SizedBox(height: 12),

                            // Description message
                            _buildChatMessage(
                              "Description",
                              plantDetails.description,
                              Icons.description,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatMessage(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Message content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AR Garden', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final objectCount = ref.watch(objectCountProvider);
              final placedAnchors = ref.watch(placedAnchorsProvider);

              if (objectCount == 0) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  final arState = ref.read(arStateProvider);
                  final placedPlantsNotifier =
                      ref.read(placedPlantsProvider.notifier);
                  final plantDetailsNotifier =
                      ref.read(plantDetailsProvider.notifier);
                  final showPlantDetailsNotifier =
                      ref.read(showPlantDetailsProvider.notifier);
                  final statusNotifier = ref.read(statusProvider.notifier);

                  try {
                    for (final anchor in placedAnchors) {
                      await arState.arAnchorManager?.removeAnchor(anchor);
                    }
                    placedPlantsNotifier.clearAll();
                    plantDetailsNotifier.clearDetails();
                    showPlantDetailsNotifier.hide();
                    statusNotifier.updateStatus(
                      'All plants cleared – tap surfaces to place new ones',
                    );
                  } catch (e) {
                    print('Error clearing objects: $e');
                    statusNotifier.updateStatus(
                        'Error clearing objects – try restarting');
                  }
                },
                tooltip: 'Clear all plants',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // AR View
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),

            // Status overlay
            _buildStatusOverlay(),

            // Object counter
            _buildObjectCounter(),

            const ARChatbot(),

            // Plant selector
            _buildPlantSelector(),

            // Plant details overlay
            _buildPlantDetailsOverlay(),

            // Loading indicator during initialization
            Consumer(
              builder: (context, ref, child) {
                final isInitializing = ref.watch(
                  arStateProvider.select((state) => state.isInitializing),
                );

                if (!isInitializing) return const SizedBox.shrink();

                return Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Initializing AR...",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
