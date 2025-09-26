import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/widgets/score_viewer_widget.dart';
import 'package:musilingo/app/services/ai_score_service.dart';

class AiPlaygroundScreen extends StatefulWidget {
  const AiPlaygroundScreen({super.key});

  @override
  State<AiPlaygroundScreen> createState() => _AiPlaygroundScreenState();
}

class _AiPlaygroundScreenState extends State<AiPlaygroundScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIScoreService _aiScoreService = AIScoreService();

  String? _musicXML;
  bool _isLoading = false;
  String? _error;

  Future<void> _generateScore() async {
    if (_promptController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _musicXML = null;
    });

    try {
      final generatedXml =
          await _aiScoreService.generateMusicXML(_promptController.text);
      setState(() {
        _musicXML = generatedXml;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao gerar partitura: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Playground'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Descreva a partitura que você quer',
                hintText: 'Ex: Uma escala de Dó maior em semínimas',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _generateScore(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateScore,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Gerar Partitura'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            Expanded(
              child: _musicXML != null
                  ? ScoreViewerWidget(
                      musicXML: _musicXML!,
                      // Adicione um key para forçar a reconstrução do widget
                      // quando o XML for alterado.
                      key: ValueKey(_musicXML),
                    )
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('A partitura aparecerá aqui.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
