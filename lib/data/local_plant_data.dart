// Local plant information database
import 'package:plant_arvr/providers/ar_providers.dart';

class LocalPlantData {
  static Map<String, PlantDetails> getPlantInfo() {
    return {
      "neem": PlantDetails(
        name: "Neem",
        benefits:
            "• Natural antiseptic and antibacterial properties\n• Helps treat skin conditions like acne, eczema, and psoriasis\n• Boosts immune system\n• Effective against fungal infections\n• Anti-inflammatory properties\n• Helps control diabetes\n• Natural insect repellent",
        usage:
            "• Leaves can be chewed for oral health\n• Neem oil for skin applications\n• Neem powder for face masks\n• Tea made from leaves for internal consumption\n• Paste from leaves for wounds and cuts\n• Use as natural pesticide in gardens",
        description:
            "Neem (Azadirachta indica) is a fast-growing tree native to India and Myanmar. Known as the 'village pharmacy,' every part of this tree has medicinal value. The bitter leaves, bark, and oil have been used in traditional Ayurvedic medicine for thousands of years. It's particularly valued for its antimicrobial and anti-inflammatory properties.",
      ),
      "tulsi": PlantDetails(
        name: "Tulsi (Holy Basil)",
        benefits:
            "• Powerful adaptogen that reduces stress\n• Strengthens respiratory system\n• Natural immunity booster\n• Anti-inflammatory and antioxidant properties\n• Helps regulate blood sugar levels\n• Supports cardiovascular health\n• Natural detoxifier",
        usage:
            "• Fresh leaves can be eaten daily (2-3 leaves)\n• Tulsi tea for respiratory issues\n• Essential oil for aromatherapy\n• Paste from leaves for skin conditions\n• Dried leaves as herbal supplement\n• Use in cooking for flavor and health benefits",
        description:
            "Tulsi (Ocimum tenuiflorum), also known as Holy Basil, is revered in Hindu tradition and Ayurvedic medicine. Unlike sweet basil, tulsi has a spicy, clove-like aroma. It's considered a sacred plant in India and is known for its remarkable healing properties and ability to purify the air around it.",
      ),
      "rosemary": PlantDetails(
        name: "Rosemary",
        benefits:
            "• Improves memory and cognitive function\n• Rich in antioxidants and anti-inflammatory compounds\n• Supports circulation and brain health\n• Natural antimicrobial properties\n• Helps reduce stress and anxiety\n• May help prevent cancer\n• Supports digestive health",
        usage:
            "• Use fresh or dried leaves in cooking\n• Rosemary tea for mental clarity\n• Essential oil for aromatherapy and hair care\n• Infused oil for massage and skin care\n• Dried herb for seasoning meats and vegetables\n• Fresh sprigs in potpourri for natural fragrance",
        description:
            "Rosemary (Rosmarinus officinalis) is a woody, perennial herb with fragrant, evergreen needle-like leaves. Native to the Mediterranean region, it has been used since ancient times for its medicinal properties and culinary applications. The name 'rosemary' derives from Latin 'ros marinus,' meaning 'dew of the sea.'",
      ),
      "eucalyptus": PlantDetails(
        name: "Eucalyptus",
        benefits:
            "• Powerful decongestant for respiratory issues\n• Natural antiseptic and antimicrobial properties\n• Pain relief for muscles and joints\n• Helps with wound healing\n• Natural insect repellent\n• Anti-inflammatory effects\n• Supports mental clarity and focus",
        usage:
            "• Steam inhalation with leaves for congestion\n• Essential oil for aromatherapy and topical use\n• Tea from young leaves (in moderation)\n• Oil for massage and pain relief\n• Dried leaves in potpourri\n• Use in natural cleaning products",
        description:
            "Eucalyptus is a diverse genus of flowering trees and shrubs native to Australia. Known for their distinctive aroma and medicinal properties, eucalyptus leaves contain essential oils rich in eucalyptol. Aboriginal Australians have used eucalyptus for centuries to treat various ailments, particularly respiratory conditions.",
      ),
      "aloe_vera": PlantDetails(
        name: "Aloe Vera",
        benefits:
            "• Excellent for treating burns and skin irritations\n• Natural moisturizer and anti-aging properties\n• Helps heal wounds and cuts\n• Soothes digestive issues\n• Anti-inflammatory and cooling effects\n• Rich in vitamins and minerals\n• Helps with hair and scalp health",
        usage:
            "• Apply gel directly to burns and cuts\n• Use as natural moisturizer for skin\n• Aloe juice for digestive health (small amounts)\n• Hair mask for dry and damaged hair\n• After-sun care for sunburned skin\n• Mix with honey for face masks",
        description:
            "Aloe Vera (Aloe barbadensis miller) is a succulent plant species known for its thick, fleshy leaves containing a clear gel. Native to the Arabian Peninsula, it has been cultivated worldwide for its medicinal properties. Often called the 'plant of immortality' by ancient Egyptians, aloe vera has been used for over 4,000 years for healing purposes.",
      ),
    };
  }
}
