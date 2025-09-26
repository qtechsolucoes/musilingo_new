import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:musilingo/features/practice_solfege/models/solfege_exercise.dart';

class OSMDService {
  late WebViewController controller;

  Future<void> initialize() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    final htmlContent = _getOSMDHtml();
    await controller.loadHtmlString(htmlContent);

    await Future.delayed(const Duration(seconds: 2));
  }

  String _getOSMDHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background: transparent;
        }
        #osmdCanvas {
            width: 100%;
            background: white;
            border-radius: 10px;
            padding: 20px;
        }
        .note-active { fill: #FFD700 !important; }
        .note-correct { fill: #00FF00 !important; }
        .note-incorrect { fill: #FF0000 !important; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.8.1/build/opensheetmusicdisplay.min.js"></script>
</head>
<body>
    <div id="osmdCanvas"></div>
    <script>
        let osmd = null;
        let noteElements = [];
        
        async function initializeOSMD() {
            osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmdCanvas", {
                autoResize: true,
                backend: "svg",
                drawingParameters: "compact"
            });
        }
        
        function generateMusicXML(exercise) {
            // Implementação simplificada de geração de MusicXML
            const notes = exercise.noteSequence || [];
            let notesXML = '';
            
            notes.forEach(note => {
                notesXML += '<note><pitch><step>' + note.note.charAt(0) + '</step>';
                if (note.note.includes('#')) notesXML += '<alter>1</alter>';
                notesXML += '<octave>' + note.note.charAt(note.note.length - 1) + '</octave></pitch>';
                notesXML += '<duration>1</duration><type>' + note.duration + '</type></note>';
            });
            
            return '<?xml version="1.0" encoding="UTF-8"?><score-partwise><part-list><score-part id="P1"><part-name>Solfejo</part-name></score-part></part-list><part id="P1"><measure number="1">' + notesXML + '</measure></part></score-partwise>';
        }
        
        async function loadExercise(exerciseData) {
            try {
                const exercise = JSON.parse(exerciseData);
                const musicXML = generateMusicXML(exercise);
                await osmd.load(musicXML);
                await osmd.render();
                noteElements = document.querySelectorAll('.vf-stavenote');
                return true;
            } catch (error) {
                console.error('Erro:', error);
                return false;
            }
        }
        
        function highlightNote(index, status) {
            if (index >= 0 && index < noteElements.length) {
                noteElements[index].classList.remove('note-active', 'note-correct', 'note-incorrect');
                if (status !== 'neutral') {
                    noteElements[index].classList.add('note-' + status);
                }
            }
        }
        
        function resetHighlights() {
            noteElements.forEach(el => {
                el.classList.remove('note-active', 'note-correct', 'note-incorrect');
            });
        }
        
        window.addEventListener('load', initializeOSMD);
    </script>
</body>
</html>
''';
  }

  Future<void> loadExercise(SolfegeExercise exercise) async {
    final exerciseJson = jsonEncode({
      'timeSignature': exercise.timeSignature,
      'tempo': exercise.tempo,
      'keySignature': exercise.keySignature,
      'noteSequence': exercise.noteSequence.map((n) => n.toJson()).toList(),
    });

    await controller.runJavaScript('loadExercise(`$exerciseJson`)');
  }

  Future<void> highlightNote(int index, String status) async {
    await controller.runJavaScript('highlightNote($index, "$status")');
  }

  Future<void> resetHighlights() async {
    await controller.runJavaScript('resetHighlights()');
  }
}
