import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantDetailsResponse {
  final String benefits;
  final String usage;
  final String description;

  PlantDetailsResponse({
    required this.benefits,
    required this.usage,
    required this.description,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  late final String _apiKey;
  late final bool _isConfigured;

  GeminiService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _isConfigured = _apiKey.isNotEmpty;

    if (!_isConfigured) {
      print(
        'Warning: GEMINI_API_KEY not found in .env file. Plant details feature will be disabled.',
      );
    }
  }

  bool get isConfigured => _isConfigured;

  Future<String> getMedicalBenefits(String plantName) async {
    if (!_isConfigured) {
      return 'Gemini AI service is not configured. Please add your API key to the .env file to enable plant details.';
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'What are the medical benefits of $plantName? Please provide a concise summary.',
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 200},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String responseText =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return _formatContent(responseText);
      } else {
        throw Exception('Failed to get medical benefits');
      }
    } catch (e) {
      throw Exception('Error getting medical benefits: $e');
    }
  }

  Future<PlantDetailsResponse> getPlantDetails(String plantName) async {
    if (!_isConfigured) {
      return PlantDetailsResponse(
        benefits: 'Gemini AI service is not configured.',
        usage:
            'Please add your API key to the .env file to enable detailed plant information.',
        description: 'The plant details feature requires a Gemini API key.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''
                  provide detailed information about $plantName in the following format:
                  
                  BENEFITS:
                  [List the medical and health benefits]
                  
                  USAGE:
                  [Explain how it can be used - preparation methods, dosage, application methods]
                  
                  DESCRIPTION:
                  [Brief botanical description and interesting facts]
                  
                  Keep the response concise but informative, suitable for display on a mobile AR interface.
                  ''',
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 800},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fullText =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the response into sections
        final sections = _parseGeminiResponse(fullText);

        return PlantDetailsResponse(
          benefits:
              sections['benefits'] ?? 'Benefits information not available.',
          usage: sections['usage'] ?? 'Usage information not available.',
          description: sections['description'] ?? 'Description not available.',
        );
      } else {
        throw Exception('Failed to get plant details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting plant details: $e');
    }
  }

  Map<String, String> _parseGeminiResponse(String response) {
    final result = <String, String>{};

    try {
      final lines = response.split('\n');
      String currentSection = '';
      StringBuffer currentContent = StringBuffer();

      for (final line in lines) {
        final trimmedLine = line.trim();

        if (trimmedLine.toUpperCase().startsWith('BENEFITS:')) {
          if (currentSection.isNotEmpty) {
            result[currentSection] = currentContent.toString().trim();
          }
          currentSection = 'benefits';
          currentContent.clear();
          // Add any content after the colon
          final afterColon = trimmedLine.substring(9).trim();
          if (afterColon.isNotEmpty) {
            currentContent.writeln(afterColon);
          }
        } else if (trimmedLine.toUpperCase().startsWith('USAGE:')) {
          if (currentSection.isNotEmpty) {
            result[currentSection] = _formatContent(
              currentContent.toString().trim(),
            );
          }
          currentSection = 'usage';
          currentContent.clear();
          // Add any content after the colon
          final afterColon = trimmedLine.substring(6).trim();
          if (afterColon.isNotEmpty) {
            currentContent.writeln(afterColon);
          }
        } else if (trimmedLine.toUpperCase().startsWith('DESCRIPTION:')) {
          if (currentSection.isNotEmpty) {
            result[currentSection] = _formatContent(
              currentContent.toString().trim(),
            );
          }
          currentSection = 'description';
          currentContent.clear();
          // Add any content after the colon
          final afterColon = trimmedLine.substring(12).trim();
          if (afterColon.isNotEmpty) {
            currentContent.writeln(afterColon);
          }
        } else if (currentSection.isNotEmpty && trimmedLine.isNotEmpty) {
          currentContent.writeln(trimmedLine);
        }
      }

      // Don't forget the last section
      if (currentSection.isNotEmpty) {
        result[currentSection] = _formatContent(
          currentContent.toString().trim(),
        );
      }
    } catch (e) {
      print('Error parsing Gemini response: $e');
      // Fallback: use the entire response as description
      result['description'] = _formatContent(response);
    }

    return result;
  }

  /// Formats content to approximately 70 words and removes asterisks
  String _formatContent(String content) {
    // Remove asterisks
    var formatted = content.replaceAll('*', '');

    // Limit to approximately 70 words
    var words = formatted.split(' ');
    if (words.length > 70) {
      formatted = words.take(70).join(' ') + '...';
    }

    return formatted;
  }

  // Chatbot functionality for AR Virtual Garden
  Future<String> getChatResponse(
    String userMessage,
    List<ChatMessage> conversationHistory, {
    List<String>? placedPlants,
  }) async {
    if (!_isConfigured) {
      return 'I apologize, but the chat feature is not available because the Gemini API key is not configured. Please add your API key to the .env file to enable this feature.';
    }

    try {
      String prompt =
          'You are a helpful AR garden assistant. The user is exploring medicinal plants (Neem, Tulsi, Rosemary, Eucalyptus, Aloe Vera) in an AR app. '
          'Answer concisely and use markdown formatting (bold, bullet points) where helpful. '
          'Question: $userMessage';

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 450},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          // Return raw text — markdown is rendered by the chat bubble widget
          String responseText =
              data['candidates'][0]['content']['parts'][0]['text']?.trim() ??
              'I apologize, but I couldn\'t generate a proper response. Please try asking again!';
          return responseText;
        }
        return 'I received an empty response. Please try rephrasing your question!';
      } else {
        return 'I\'m having trouble connecting to the AI service right now. Please try again!';
      }
    } catch (e) {
      print('Error getting chat response: $e');
      return 'Sorry, I encountered an error. Please try again!';
    }
  }
}
