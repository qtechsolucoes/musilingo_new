import 'dart:convert';
import 'package:http/http.dart' as http;

class AIScoreService {
  late final String _baseUrl;
  late final String _fallbackUrl;
  final String _model = 'gemma:2b';

  AIScoreService() {
    _baseUrl = const String.fromEnvironment('AI_SCORE_URL',
        defaultValue: 'https://f91beac9eba2.ngrok-free.app/generate_score');
    _fallbackUrl = const String.fromEnvironment('AI_SCORE_FALLBACK_URL',
        defaultValue: 'http://localhost:11434/api/generate');
  }

  Future<String> generateMusicXML(String prompt) async {
    const systemPrompt = """
Você é um especialista em teoria musical e um assistente de composição. Sua tarefa é gerar partituras no formato MusicXML.

REGRAS:
1.  Responda APENAS com o código MusicXML.
2.  Não inclua nenhuma explicação, apenas o XML.
3.  O XML deve ser bem formado e completo.
4.  Inclua um título (<work-title>) e um compositor (<creator type="composer">Musilingo IA</creator>).
5.  Use a clave de Sol (G) e um compasso de 4/4 como padrão, a menos que o usuário peça algo diferente.
6.  Traduza os prompts do usuário para notação musical. Por exemplo, "escala de Dó maior" deve se tornar uma sequência de notas C, D, E, F, G, A, B.
""";

    final requestBody = {
      'model': _model,
      'prompt': prompt,
      'system': systemPrompt,
      'stream': false,
    };

    List<String> urls = [_baseUrl];
    if (_fallbackUrl.isNotEmpty && _fallbackUrl != _baseUrl) {
      urls.add(_fallbackUrl);
    }

    for (String url in urls) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          final musicXML = url.contains('ngrok')
              ? decodedResponse['musicxml'] ?? decodedResponse['response']
              : decodedResponse['response'];

          final xmlContent = musicXML.toString().trim();
          // Validação simples para garantir que a resposta é um XML
          if (xmlContent.startsWith('<?xml') && xmlContent.endsWith('>')) {
            return xmlContent;
          }
        }
      } catch (e) {
        if (url == urls.last) {
          throw Exception('Erro ao gerar a partitura: $e');
        }
        continue; // Tenta próximo URL
      }
    }

    throw Exception('Todos os servidores estão indisponíveis');
  }
}
