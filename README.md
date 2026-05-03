# Prasinos 

An Augmented Reality mobile app built with Flutter that lets you place, explore, and learn about medicinal plants in your real-world environment. Powered by Google Gemini 2.5 Flash for conversational plant knowledge, with a full offline fallback.

---

## Features

**AR Plant Placement** — Detect flat surfaces and anchor 3D plant models to them. Place multiple plants, tap any to view its medicinal profile.

**Plant Catalogue** — Five medicinal plants: Neem, Tulsi (Holy Basil), Rosemary, Eucalyptus, and Aloe Vera. Each includes benefits, usage, care tips, and a botanical description.

**AI Garden Assistant** — A floating chatbot backed by Gemini 2.5 Flash when online, and a comprehensive built-in knowledge base when offline. Covers plant benefits, preparation methods, care advice, garden design, and AR troubleshooting.

**Local Asset Caching** — 3D models are downloaded from GitHub once and stored on-device. Subsequent placements are instant with no network requests.

---

## Architecture

```
lib/
├── main.dart                        # App entry, dotenv init, ProviderScope
├── data/
│   └── local_plant_data.dart        # Embedded plant knowledge (benefits, usage, description)
├── models/
│   └── plant_model.dart             # Plant data model
├── providers/
│   └── ar_providers.dart            # All Riverpod providers and state notifiers
├── screens/
│   ├── home_screen.dart             # Entry screen
│   └── virtual_garden_screen.dart   # AR view, surface detection, plant placement
├── services/
│   ├── asset_cache_service.dart     # GLB model download and local file caching
│   ├── gemini_service.dart          # Gemini API client (chat + plant details)
│   └── offline_chat_service.dart    # Offline chatbot knowledge base
└── widgets/
    └── ar_chatbot.dart              # Chatbot UI and ChatbotNotifier provider
```

### State Management

All state is managed with Riverpod (`StateNotifierProvider`):

| Provider | Manages |
|---|---|
| `arStateProvider` | AR session managers, ready/initializing flags |
| `selectedPlantProvider` | Currently selected plant |
| `placedPlantsProvider` | Authoritative list of placed plants |
| `objectCountProvider` | Derived count from `placedPlantsProvider` |
| `plantDetailsProvider` | Detail panel content |
| `assetCacheProvider` | Per-plant download status and local file paths |
| `chatbotProvider` | Chat state — open/closed, messages, loading |
| `modelCacheProvider` | In-memory ARNode template cache |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| AR | `ar_flutter_plugin_2` (ARCore / ARKit) |
| 3D Models | GLB / glTF 2.0 |
| State Management | `flutter_riverpod ^2.5` |
| AI / Chat | Google Gemini 2.5 Flash REST API |
| Markdown Rendering | `flutter_markdown_plus` |
| HTTP | `http ^1.4` |
| Environment Config | `flutter_dotenv` |
| Local Storage | `path_provider` |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.8`
- Android device or emulator with ARCore support (Android 8.0+), or iOS device with ARKit support (iOS 12+)
- A [Google Gemini API key](https://ai.google.dev/) (free tier available; app works in offline mode without it)

### Setup

```bash
# Clone the repository
git clone https://github.com/torichoudhury/plant_arvr.git
cd plant_arvr

# Install dependencies
flutter pub get
```

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

> The `.env` file is declared as a Flutter asset and loaded at startup via `flutter_dotenv`. Do not commit your API key to version control.

```bash
flutter run
```

---

## Usage

1. Launch the app — the AR session initialises and begins scanning for surfaces.
2. Move the device slowly over a flat, textured surface (floor, table, desk).
3. Tap the detected surface to place the selected plant.
4. Use the plant selector at the bottom to switch between species.
5. Tap the **info button** next to any plant name to open its detail panel.
6. Tap a placed plant in AR to view its medicinal profile.
7. Tap the chat button (bottom-right) to open the garden assistant.

**Tips for better AR detection:** use good ambient lighting, prefer textured surfaces over plain walls, and move the camera slowly when scanning.

---

## Chatbot Offline Mode

The built-in knowledge base answers the following without an internet connection:

| Query type | Example |
|---|---|
| Plant benefits | "What are the benefits of neem?" |
| Preparation | "How do I use eucalyptus for a cold?" |
| Care tips | "How do I care for tulsi?" |
| Watering | "Watering guide for all plants" |
| Sunlight | "Which plants need full sun?" |
| Garden design | "How should I arrange my garden?" |
| AR troubleshooting | "Why isn't AR detecting surfaces?" |
| Comparison | "Compare all plants" |

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | For online AI chat | Google Gemini API key. The app falls back to offline mode if absent. |

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push and open a Pull Request.

---

## License

This project is for educational and demonstration purposes.
