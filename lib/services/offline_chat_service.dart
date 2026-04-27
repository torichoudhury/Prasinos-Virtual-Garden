/// Offline knowledge base for the AR Garden Assistant chatbot.
/// Handles plant info, care tips, AR guidance, and gardening Q&A
/// without any network connection.
class OfflineChatService {
  // ─── Intent keywords ───────────────────────────────────────────

  static const _benefitWords = ['benefit', 'medicin', 'health', 'heal', 'cure', 'treat', 'good for', 'help'];
  static const _usageWords = ['use', 'usage', 'prepare', 'cook', 'apply', 'consume', 'make', 'how to'];
  static const _careWords = ['care', 'water', 'grow', 'sun', 'light', 'soil', 'fertiliz', 'prune', 'maintai'];
  static const _arWords = ['ar', 'augment', 'place', 'camera', 'surface', 'plane', 'detect', 'track', 'scan', 'anchor'];
  static const _gardenWords = ['garden', 'design', 'layout', 'arrange', 'combin', 'together', 'mix', 'plan'];
  static const _compareWords = ['vs', 'versus', 'compare', 'differ', 'better', 'best', 'which'];
  static const _listWords = ['list', 'all plant', 'available', 'what plant', 'show plant'];
  static const _greetWords = ['hi', 'hello', 'hey', 'start', 'help', 'what can you'];

  // ─── Plant aliases ──────────────────────────────────────────────

  static const _plantAliases = <String, String>{
    'neem': 'neem', 'azadirachta': 'neem', 'nim': 'neem',
    'tulsi': 'tulsi', 'holy basil': 'tulsi', 'basil': 'tulsi', 'ocimum': 'tulsi',
    'rosemary': 'rosemary', 'ros marinus': 'rosemary',
    'eucalyptus': 'eucalyptus', 'eucalypt': 'eucalyptus', 'gum tree': 'eucalyptus',
    'aloe': 'aloe_vera', 'aloe vera': 'aloe_vera', 'aloe_vera': 'aloe_vera',
  };

  // ─── Plant knowledge ───────────────────────────────────────────

  static const _plants = <String, _PlantEntry>{
    'neem': _PlantEntry(
      displayName: 'Neem',
      emoji: '🌿',
      shortDesc: 'The "village pharmacy" — one of the most versatile medicinal trees in Ayurveda.',
      benefits: '''🌿 **Neem Benefits:**
• Powerful natural antiseptic & antibacterial
• Treats acne, eczema & psoriasis
• Boosts immune system naturally
• Effective against fungal infections
• Strong anti-inflammatory properties
• Helps stabilise blood sugar levels
• Natural insect & mosquito repellent''',
      usage: '''💊 **Neem Usage:**
• Chew 1–2 fresh leaves daily for oral health
• Apply neem oil to skin for acne & infections
• Neem powder face mask (mix with yoghurt)
• Boil leaves into tea for internal detox
• Use leaf paste on wounds and cuts
• Diluted neem oil spray as garden pesticide''',
      care: '''🌱 **Neem Care Tips:**
• Thrives in full sun (6+ hours/day)
• Very drought-tolerant once established
• Prefers well-drained, sandy or loamy soil
• Water deeply but infrequently
• Grows fast — prune annually to shape
• Hardy in warm/tropical climates (no frost)''',
      funFact: '💡 Fun fact: Neem has over 130 biologically active compounds — it\'s used in toothpaste, pesticides, and cosmetics!',
    ),
    'tulsi': _PlantEntry(
      displayName: 'Tulsi (Holy Basil)',
      emoji: '🌸',
      shortDesc: 'Sacred in Hindu tradition, tulsi is Ayurveda\'s most revered adaptogenic herb.',
      benefits: '''🌸 **Tulsi Benefits:**
• Powerful adaptogen — reduces stress & anxiety
• Strengthens the respiratory system
• Natural immunity booster
• Rich in antioxidants & anti-inflammatory compounds
• Helps regulate blood sugar levels
• Supports cardiovascular health
• Natural air purifier & detoxifier''',
      usage: '''💊 **Tulsi Usage:**
• Eat 2–3 fresh leaves daily on an empty stomach
• Tulsi tea: steep 5–6 leaves in hot water for 5 min
• Essential oil for aromatherapy
• Paste from leaves for skin rashes
• Dry leaves and grind for herbal supplements
• Add to food as a flavourful spice''',
      care: '''🌱 **Tulsi Care Tips:**
• Loves warm, sunny spots (5+ hours of sun)
• Water moderately — keep soil moist, not soggy
• Pinch off flower buds to encourage leaf growth
• Use rich, well-drained potting soil
• Protect from frost (bring indoors in winter)
• Repot every spring for best growth''',
      funFact: '💡 Fun fact: Tulsi is sacred in Hinduism — most Indian households grow a Tulsi plant for daily worship.',
    ),
    'rosemary': _PlantEntry(
      displayName: 'Rosemary',
      emoji: '🪴',
      shortDesc: 'A hardy Mediterranean herb prized for culinary use, memory, and circulation.',
      benefits: '''🪴 **Rosemary Benefits:**
• Improves memory & cognitive function
• Rich in antioxidants (rosmarinic acid)
• Boosts blood circulation
• Natural antimicrobial & antifungal
• Reduces stress and anxiety
• May protect against cancer
• Supports healthy digestion''',
      usage: '''💊 **Rosemary Usage:**
• Add fresh/dried sprigs to roasted meats & vegetables
• Rosemary tea: steep a sprig in hot water 5–10 min
• Essential oil for scalp massage & hair growth
• Infused oil for massage and joint pain
• Burn dried sprigs as a natural fragrance
• Add to bread dough for flavour''',
      care: '''🌱 **Rosemary Care Tips:**
• Needs full sun — at least 6–8 hours/day
• Very drought-tolerant; let soil dry between watering
• Sandy, well-drained soil is ideal (no waterlogging)
• Prune after flowering to keep compact shape
• Grows well in pots on sunny windowsills
• Hardy but protect roots from severe frost''',
      funFact: '💡 Fun fact: Ancient Greek students wore rosemary garlands while studying — they believed it improved memory!',
    ),
    'eucalyptus': _PlantEntry(
      displayName: 'Eucalyptus',
      emoji: '🌲',
      shortDesc: 'Australia\'s iconic tree, famous for its powerful decongestant and antiseptic oils.',
      benefits: '''🌲 **Eucalyptus Benefits:**
• Powerful natural decongestant for colds & flu
• Strong antiseptic & antimicrobial properties
• Relieves muscle and joint pain
• Speeds up wound healing
• Repels mosquitoes & insects
• Reduces inflammation
• Improves mental clarity & focus''',
      usage: '''💊 **Eucalyptus Usage:**
• Steam inhalation: add leaves/oil to hot water, inhale
• Diluted essential oil for chest rub (cold relief)
• Oil massage for sore muscles and joints
• Add dried leaves to potpourri for fragrance
• Natural ingredient in cleaning products
• Diffuse oil for mental clarity''',
      care: '''🌱 **Eucalyptus Care Tips:**
• Full sun lover — needs 6–8+ hours of direct light
• Water regularly until established, then drought-tolerant
• Well-drained soil is a must — hates waterlogged roots
• Fast grower — prune hard to control size in pots
• Protect young plants from frost
• Use large pots if growing indoors''',
      funFact: '💡 Fun fact: Koalas eat almost exclusively eucalyptus leaves — the oils that are medicinal to us are actually toxic to most animals!',
    ),
    'aloe_vera': _PlantEntry(
      displayName: 'Aloe Vera',
      emoji: '🌵',
      shortDesc: 'The "plant of immortality" — a succulent with centuries of skin-healing use.',
      benefits: '''🌵 **Aloe Vera Benefits:**
• Excellent for treating burns, cuts & skin irritation
• Natural moisturiser with anti-aging properties
• Soothes sunburns almost instantly
• Calms digestive issues (small amounts of juice)
• Anti-inflammatory & cooling effect
• Rich in vitamins C, E, and B12
• Promotes healthy hair & scalp''',
      usage: '''💊 **Aloe Vera Usage:**
• Snap a leaf and apply gel directly to burns/cuts
• Use as a natural daily moisturiser for face & body
• Mix gel with water as an after-sun spray
• Apply to scalp 30 min before shampooing
• Blend with honey for a soothing face mask
• Aloe juice (inner leaf only) for digestion — use sparingly''',
      care: '''🌱 **Aloe Vera Care Tips:**
• Bright, indirect light is ideal (avoid harsh midday sun)
• Water only when soil is completely dry (every 2–3 weeks)
• Well-draining cactus/succulent mix soil
• Use terracotta pots for better drainage
• No fertiliser needed — very low maintenance!
• Keep above 10°C (50°F) — frost will kill it''',
      funFact: '💡 Fun fact: Ancient Egyptians called aloe vera the "plant of immortality" and used it in burial rituals for pharaohs.',
    ),
  };

  // ─── Gardening topic knowledge ──────────────────────────────────

  static const String _gardenDesignTips = '''🏡 **Garden Design Tips:**
• Group plants with similar water needs together
• Place taller plants (Neem, Eucalyptus) at the back
• Use mid-height herbs (Tulsi, Rosemary) in the middle
• Put low, spreading plants (Aloe) at the front/edges
• Mix textures — broad leaves with needle-like ones
• Consider companion planting: Neem near vegetables repels pests
• Leave 30–50 cm space between herb plants for airflow''';

  static const String _wateringGuide = '''💧 **Watering Guide for Your Plants:**
• 🌵 Aloe Vera — every 2–3 weeks; drought-tolerant
• 🪴 Rosemary — every 1–2 weeks; let soil dry between watering
• 🌲 Eucalyptus — weekly when young; drought-tolerant when mature
• 🌿 Neem — once a week; very drought tolerant once established
• 🌸 Tulsi — every 2–3 days; keep moist but not soggy
Tip: Always check soil with your finger before watering!''';

  static const String _sunlightGuide = '''☀️ **Sunlight Requirements:**
• 🌞 Full Sun (6–8 hrs): Neem, Rosemary, Eucalyptus
• 🌤 Partial Sun (4–6 hrs): Tulsi, Aloe Vera
Tip: In the AR garden, place sun-loving plants in open areas and shade-tolerant ones near walls!''';

  static const String _soilGuide = '''🪱 **Soil Guide:**
• Neem — sandy, well-drained; tolerates poor soil
• Tulsi — rich, fertile potting mix with good drainage
• Rosemary — sandy or rocky; low nutrients preferred
• Eucalyptus — any well-drained soil; avoid clay
• Aloe Vera — cactus/succulent mix; drainage is critical
General rule: All these plants hate waterlogged roots!''';

  static const String _arTips = '''📱 **AR Placement Tips:**
• Point your camera at flat, well-lit, textured surfaces
• Move the phone slowly for better plane detection
• Tap on the white dots/grid to place a plant
• Good lighting = better AR tracking accuracy
• Avoid plain white walls — AR needs texture to detect surfaces
• Tap and hold a placed plant to interact with it
• Use the plant selector at the bottom to switch species''';

  static const String _troubleshootAR = '''🔧 **AR Troubleshooting:**
• No planes detected? Move to a brighter, more textured area
• Plants floating? Re-scan the surface slowly
• App lagging? Close background apps for better performance
• Model not loading? Check your internet connection for first load
• Camera not working? Grant camera permission in phone Settings''';

  // ─── Public entry point ─────────────────────────────────────────

  /// Returns an offline response for [message].
  /// [placedPlants] is the list of currently placed plant display names.
  static String respond(String message, List<String>? placedPlants) {
    final m = message.toLowerCase().trim();

    // 1. Greetings
    if (_matches(m, _greetWords)) return _greeting(placedPlants);

    // 2. List all plants
    if (_matches(m, _listWords)) return _listAllPlants();

    // 3. Detect mentioned plant
    final plantId = _detectPlant(m);

    // 4. Plant + intent routing
    if (plantId != null) {
      final plant = _plants[plantId]!;
      if (_matches(m, _benefitWords)) return '${plant.benefits}\n\n${plant.funFact}';
      if (_matches(m, _usageWords)) return plant.usage;
      if (_matches(m, _careWords)) return plant.care;
      // Default: full overview
      return _plantOverview(plant);
    }

    // 5. Topic routing (no specific plant)
    if (_matches(m, _compareWords)) return _comparePlants();
    if (_matches(m, _careWords) && _matches(m, ['water'])) return _wateringGuide;
    if (_matches(m, _careWords) && _matches(m, ['sun', 'light'])) return _sunlightGuide;
    if (_matches(m, _careWords) && _matches(m, ['soil'])) return _soilGuide;
    if (_matches(m, _careWords)) return _generalCare();
    if (_matches(m, _arWords) && _matches(m, ['problem', 'issue', 'not work', 'cant', "can't", 'fix'])) return _troubleshootAR;
    if (_matches(m, _arWords)) return _arTips;
    if (_matches(m, _gardenWords)) return _gardenDesignTips;
    if (_matches(m, _benefitWords)) return _generalBenefits();
    if (_matches(m, _usageWords)) return _generalUsage();

    // 6. Garden status
    if (placedPlants != null && placedPlants.isNotEmpty) {
      if (_matches(m, ['my garden', 'my plant', 'placed', 'current'])) {
        return _gardenStatus(placedPlants);
      }
    }

    // 7. Fallback with suggestions
    return _fallback();
  }

  // ─── Response builders ──────────────────────────────────────────

  static String _greeting(List<String>? placedPlants) {
    final gardenPart = (placedPlants != null && placedPlants.isNotEmpty)
        ? '\n\n🌱 Your current garden has: ${placedPlants.join(', ')}.'
        : '\n\n🪴 Your AR garden is empty — try placing your first plant!';
    return '👋 Hi! I\'m your AR Garden Assistant — available offline too!\n\nI can help you with:\n• 🌿 Plant benefits & medicinal uses\n• 💊 How to prepare & use each plant\n• 🌱 Care tips (watering, sunlight, soil)\n• 📱 AR placement & troubleshooting\n• 🏡 Garden design ideas\n\nJust ask me anything about Neem, Tulsi, Rosemary, Eucalyptus, or Aloe Vera!$gardenPart';
  }

  static String _listAllPlants() {
    return '''🌿 **Plants in your AR Garden:**

🌿 **Neem** — Antiseptic, immune-boosting medicinal tree
🌸 **Tulsi** — Sacred adaptogen for stress & immunity  
🪴 **Rosemary** — Memory-boosting culinary herb
🌲 **Eucalyptus** — Decongestant powerhouse from Australia
🌵 **Aloe Vera** — Skin-soothing succulent

Ask me about any of these — e.g. "What are Tulsi benefits?" or "How do I care for Aloe Vera?"''';
  }

  static String _plantOverview(_PlantEntry plant) {
    return '''${plant.emoji} **${plant.displayName}**
${plant.shortDesc}

${plant.benefits}

${plant.care}

${plant.funFact}

Ask me specifically about "uses of ${plant.displayName}" or "${plant.displayName} care tips" for more detail!''';
  }

  static String _gardenStatus(List<String> plants) {
    final tips = plants.map((p) {
      final id = _plantAliases[p.toLowerCase()] ?? p.toLowerCase().replaceAll(' ', '_');
      return _plants[id]?.care.split('\n').skip(1).first ?? '• Care for $p regularly';
    }).join('\n');
    return '🌱 **Your Garden has ${plants.length} plant(s):** ${plants.join(', ')}\n\nQuick care reminder:\n$tips\n\nAsk me about any specific plant for detailed care instructions!';
  }

  static String _comparePlants() {
    return '''⚖️ **Plant Comparison:**

| Plant | Best For | Water Needs | Sunlight |
|-------|----------|-------------|----------|
| Neem | Antiseptic, pest control | Low | Full sun |
| Tulsi | Stress, immunity | Medium | Partial |
| Rosemary | Memory, cooking | Low | Full sun |
| Eucalyptus | Respiratory, pain | Low (mature) | Full sun |
| Aloe Vera | Skin, burns | Very low | Partial |

🏆 **Easiest to grow:** Aloe Vera  
🏆 **Most medicinal:** Neem  
🏆 **Best for cooking:** Rosemary & Tulsi  
🏆 **Best for colds:** Eucalyptus''';
  }

  static String _generalCare() {
    return '''🌱 **General Plant Care Principles:**

💧 Watering: Less is more for most herbs. Check soil first!
☀️ Light: All 5 plants love bright light — 4–8 hrs/day
🪱 Soil: Always use well-draining soil to prevent root rot
✂️ Pruning: Regular trimming encourages bushy, healthy growth
🌡️ Temperature: Keep above 10°C; protect from frost

Ask me about a specific plant — e.g. "How to care for Tulsi?" or "Rosemary sunlight needs"''';
  }

  static String _generalBenefits() {
    return '''💊 **Medicinal Benefits at a Glance:**

🌿 Neem — Skin, infections, immunity, blood sugar
🌸 Tulsi — Stress, respiratory, antioxidants, detox
🪴 Rosemary — Memory, circulation, antimicrobial
🌲 Eucalyptus — Congestion, pain relief, wounds
🌵 Aloe Vera — Burns, skin care, digestion, hair

Ask about a specific plant for detailed information!''';
  }

  static String _generalUsage() {
    return '''🍵 **How to Use Your Plants:**

🌿 Neem — Oil, tea, paste, leaf chewing
🌸 Tulsi — Fresh leaves, tea, aromatherapy
🪴 Rosemary — Cooking, tea, hair oil, diffuser
🌲 Eucalyptus — Steam inhalation, massage oil, diffuser
🌵 Aloe Vera — Direct gel application, juice, face mask

Ask about a specific plant — e.g. "How do I use Eucalyptus?" for a detailed guide!''';
  }

  static String _fallback() {
    final suggestions = [
      'What are the benefits of Neem?',
      'How do I care for Tulsi?',
      'How to use Eucalyptus for a cold?',
      'Compare all plants',
      'Show me AR placement tips',
      'Garden design advice',
      'Watering guide for all plants',
    ];
    suggestions.shuffle();
    final picks = suggestions.take(3).join('\n• ');
    return '🤔 I\'m not sure about that one in offline mode, but here\'s what I can help with:\n\n• $picks\n\nTry asking about Neem, Tulsi, Rosemary, Eucalyptus, or Aloe Vera!';
  }

  // ─── Helpers ────────────────────────────────────────────────────

  static bool _matches(String message, List<String> keywords) {
    return keywords.any((k) => message.contains(k));
  }

  static String? _detectPlant(String message) {
    for (final alias in _plantAliases.keys) {
      if (message.contains(alias)) return _plantAliases[alias];
    }
    return null;
  }
}

// ─── Internal data class ────────────────────────────────────────────

class _PlantEntry {
  final String displayName;
  final String emoji;
  final String shortDesc;
  final String benefits;
  final String usage;
  final String care;
  final String funFact;

  const _PlantEntry({
    required this.displayName,
    required this.emoji,
    required this.shortDesc,
    required this.benefits,
    required this.usage,
    required this.care,
    required this.funFact,
  });
}
