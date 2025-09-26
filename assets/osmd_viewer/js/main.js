// assets/osmd_viewer/js/main.js

let osmd;

function initializeOSMD() {
  // Garante que o fundo do contêiner e body sejam transparentes
  const container = document.getElementById("score-container");
  container.style.background = 'transparent';
  document.body.style.background = 'transparent';
  document.documentElement.style.background = 'transparent';

  if (!osmd) {
    try {
      osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-container", {
        backend: "svg",
        autoResize: true,
        drawCredits: false,
        drawTitle: false,
        drawSubtitle: false,
        drawComposer: false,
        drawLyricist: false,
        drawMetronomeMarks: false,
        drawPartNames: false,
        drawPartAbbreviations: false,
        drawMeasureNumbers: false,
        stretchLastSystemLine: false,
        autoBeam: true,
        pageFormat: "Endless", // Permite scroll vertical contínuo
        pageBackgroundColor: "#00000000",
        renderSingleHorizontalStaffline: false,
        // Configurações específicas para mobile
        followCursor: false,
        cursorsOptions: [
          {
            type: 0,
            color: "#33e02f",
            alpha: 0.5,
            follow: false
          }
        ]
      });

      // Configurações simplificadas para evitar erros de layout
      if (osmd.rules) {
        // Margens básicas
        osmd.rules.SystemLeftMargin = 5;
        osmd.rules.SystemRightMargin = 5;

        // Tamanhos básicos
        osmd.rules.StaffHeight = 40;
        osmd.rules.BetweenStaffDistance = 30;
        osmd.rules.MinimumDistanceBetweenSystems = 30;

        // Larguras que não causam problemas
        osmd.rules.MinMeasureWidth = 60;
        osmd.rules.MaxMeasureWidth = 200;

        // Configurações para quebra automática
        osmd.rules.MaxSystemWidth = 350; // Fixa para mobile
        osmd.rules.NewSystemFromXMLSystemBreak = true;
      }

      console.log('OSMD inicializado com sucesso e com tema correto.');
    } catch (error) {
      console.error('Erro ao inicializar OSMD:', error);
    }
  }
}

function _loadAndRender(musicXml) {
  if (!musicXml) {
    console.error('MusicXML vazio ou inválido');
    return;
  }

  try {
    initializeOSMD();
    if (!osmd) {
      console.error('Falha ao inicializar OSMD');
      return;
    }

    osmd.load(musicXml)
      .then(() => {
        // Aguardar um frame antes de renderizar para evitar warnings de width
        setTimeout(() => {
          osmd.render();
          console.log('Partitura renderizada com sucesso');

          // Aplicar cores brancas após renderização
          setTimeout(() => {
            _applyWhiteColors();
            _applyLyricColors(musicXml);
          }, 100);
        }, 50);

        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('onScoreLoaded');
        }
      })
      .catch((error) => {
        console.error("Erro ao carregar/renderizar partitura:", error);
      });
  } catch (error) {
    console.error("Erro geral na renderização:", error);
  }
}

// Função para aplicar cores brancas a todos os elementos da partitura
function _applyWhiteColors() {
  try {
    // Aplicar cor branca a todos os elementos SVG da partitura
    const svgElement = document.querySelector('#score-container svg');
    if (svgElement) {
      // Pautas (linhas do pentagrama)
      const staffLines = svgElement.querySelectorAll('.vf-stave, .vf-staffline');
      staffLines.forEach(line => {
        line.style.stroke = '#FFFFFF';
        line.style.fill = '#FFFFFF';
      });

      // Notas (cabeças, hastes, bandeirolas)
      const notes = svgElement.querySelectorAll('.vf-notehead, .vf-stem, .vf-flag, .vf-beam, .vf-stavenote');
      notes.forEach(note => {
        note.style.stroke = '#FFFFFF';
        note.style.fill = '#FFFFFF';
      });

      // Claves
      const clefs = svgElement.querySelectorAll('.vf-clef');
      clefs.forEach(clef => {
        clef.style.stroke = '#FFFFFF';
        clef.style.fill = '#FFFFFF';
      });

      // Armaduras de clave
      const keySignatures = svgElement.querySelectorAll('.vf-keysignature');
      keySignatures.forEach(key => {
        key.style.stroke = '#FFFFFF';
        key.style.fill = '#FFFFFF';
      });

      // Fórmulas de compasso
      const timeSignatures = svgElement.querySelectorAll('.vf-timesig');
      timeSignatures.forEach(time => {
        time.style.stroke = '#FFFFFF';
        time.style.fill = '#FFFFFF';
      });

      // Todos os paths e elementos genéricos
      const allPaths = svgElement.querySelectorAll('path, circle, rect, text');
      allPaths.forEach(element => {
        if (element.style.stroke !== 'none' && element.style.stroke !== 'transparent') {
          element.style.stroke = '#FFFFFF';
        }
        if (element.style.fill !== 'none' && element.style.fill !== 'transparent') {
          element.style.fill = '#FFFFFF';
        }
      });

      console.log('Cores brancas aplicadas com sucesso');
    }
  } catch (error) {
    console.error('Erro ao aplicar cores brancas:', error);
  }
}

function _applyLyricColors(musicXml) {
  try {
    const parser = new DOMParser();
    const xmlDoc = parser.parseFromString(musicXml, "text/xml");
    const notes = xmlDoc.getElementsByTagName("note");
    const lyricElements = document.querySelectorAll('.vf-lyric');

    let lyricIndex = 0;
    for (let i = 0; i < notes.length && lyricIndex < lyricElements.length; i++) {
      const note = notes[i];
      const lyricNode = note.querySelector("lyric text");

      if (lyricNode) {
        const colorAttr = lyricNode.getAttribute("color");
        if (colorAttr && lyricElements[lyricIndex]) {
          lyricElements[lyricIndex].style.fill = colorAttr;
          lyricElements[lyricIndex].style.color = colorAttr;
        }
        lyricIndex++;
      }
    }
  } catch (error) {
    console.warn("Erro ao aplicar cores aos lyrics:", error);
  }
}

window.loadScore = _loadAndRender;
window.loadXML = _loadAndRender;
window.renderScore = _loadAndRender;

window.colorLyric = function(lyricIndex, color) {
  const lyricElements = document.querySelectorAll('.vf-lyric');
  if (lyricIndex >= 0 && lyricIndex < lyricElements.length) {
    lyricElements[lyricIndex].style.fill = color;
    lyricElements[lyricIndex].style.color = color;
  }
};

window.applyNoteFeedback = function(noteIndex, noteColor, lyricColor) {
  if (noteColor) {
    window.colorNote(noteIndex, noteColor);
  }
  if (lyricColor) {
    window.colorLyric(noteIndex, lyricColor);
  }
};

window.colorNote = function(noteIndex, color) {
  if (!osmd || !osmd.cursor) {
    console.warn('OSMD ou cursor não disponível');
    return;
  }

  try {
    osmd.cursor.reset();
    let currentIndex = 0;
    let found = false;

    while(!osmd.cursor.iterator.EndReached && !found) {
        if (osmd.cursor.iterator.CurrentVoiceEntries) {
            const notes = osmd.cursor.NotesUnderCursor();
            if (notes && notes.length > 0) {
                if (currentIndex === noteIndex) {
                    notes.forEach(note => {
                        if (note && note.sourceNote && note.sourceNote.NoteHeads && note.sourceNote.NoteHeads.length > 0) {
                            note.sourceNote.NoteHeads.forEach(notehead => {
                                if (notehead) {
                                    notehead.color = color;
                                }
                            });
                        }
                        else if (note && note.sourceNote) {
                            try {
                                note.sourceNote.noteheadColor = color;
                            } catch (legacyError) {}
                        }
                    });
                    found = true;
                }
                currentIndex++;
            }
        }
        if (!found) {
          osmd.cursor.next();
        }
    }
    osmd.render();
  } catch (error) {
    console.error('Erro ao colorir nota:', error);
  }
};

window.clearAllNoteColors = function() {
  if (!osmd || !osmd.cursor) return;

  osmd.cursor.reset();
  while(!osmd.cursor.iterator.EndReached) {
      if (osmd.cursor.iterator.CurrentVoiceEntries) {
          const notes = osmd.cursor.NotesUnderCursor();
          notes.forEach(note => {
              note.sourceNote.noteheadColor = null;
          });
      }
      osmd.cursor.next();
  }
  osmd.render();
};

window.highlightCurrentNote = function(noteIndex) {
  if (!osmd) {
    console.warn('OSMD não disponível para destacar nota');
    return;
  }
  try {
    // Usar a cor amarela padrão da aplicação (accent color)
    window.colorNote(noteIndex, '#FFD700');
    console.log(`Nota ${noteIndex} destacada em amarelo`);
  } catch (error) {
    console.error('Erro ao destacar nota:', error);
  }
};

window.applyResultsFeedback = function(results) {
  if (!osmd || !results) {
    console.warn('OSMD ou resultados não disponíveis');
    return;
  }
  try {
    window.clearAllNoteColors();
    results.forEach((result, index) => {
      const color = result.correct ? '#00CC00' : '#CC0000';
      window.colorNote(index, color);
    });
    console.log('Feedback visual aplicado para', results.length, 'notas');
  } catch (error) {
    console.error('Erro ao aplicar feedback visual:', error);
  }
};

document.addEventListener("DOMContentLoaded", function() {
  initializeOSMD();
});

window.scrollToNote = function(noteIndex) {
  if (!osmd) return;
  window.highlightCurrentNote(noteIndex);

  // Scroll automático para a nota atual
  try {
    const container = document.getElementById("score-container");
    if (container) {
      // Calcula a posição vertical da nota baseada no sistema
      const systemHeight = 120; // Altura aproximada de um sistema
      const systemIndex = Math.floor(noteIndex / 8); // Aproximadamente 8 notas por sistema
      const targetY = systemIndex * systemHeight;

      // Scroll suave para a posição
      container.scrollTo({
        top: targetY,
        behavior: 'smooth'
      });

      // Notifica o Flutter sobre o scroll
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onAutoScroll', {
          noteIndex: noteIndex,
          targetY: targetY
        });
      }
    }
  } catch (error) {
    console.error('Erro no scroll automático:', error);
  }
};

// Nova função para scroll automático mais preciso
window.autoScrollToCurrentNote = function(noteIndex) {
  if (!osmd || !osmd.cursor) return;

  try {
    // Reset cursor and find the target note
    osmd.cursor.reset();
    let currentIndex = 0;
    let targetElement = null;

    while (!osmd.cursor.iterator.EndReached && currentIndex <= noteIndex) {
      if (osmd.cursor.iterator.CurrentVoiceEntries) {
        const notes = osmd.cursor.NotesUnderCursor();
        if (notes && notes.length > 0 && currentIndex === noteIndex) {
          // Encontrar o elemento SVG da nota
          const svgElements = document.querySelectorAll('.vf-stavenote');
          if (svgElements[currentIndex]) {
            targetElement = svgElements[currentIndex];
          }
          break;
        }
        if (notes && notes.length > 0) {
          currentIndex++;
        }
      }
      osmd.cursor.next();
    }

    // Scroll para o elemento se encontrado
    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
        inline: 'center'
      });
    } else {
      // Fallback para scroll baseado em índice
      window.scrollToNote(noteIndex);
    }

  } catch (error) {
    console.error('Erro no auto-scroll preciso:', error);
    // Fallback
    window.scrollToNote(noteIndex);
  }
};

// Controles avançados de zoom e layout
window.setZoomLevel = function(zoomLevel) {
  if (!osmd) {
    console.warn('OSMD não disponível para zoom');
    return;
  }

  try {
    const container = document.getElementById("score-container");
    if (container) {
      // Aplicar zoom via CSS transform
      const svgElement = container.querySelector('svg');
      if (svgElement) {
        svgElement.style.transform = `scale(${zoomLevel})`;
        svgElement.style.transformOrigin = 'top left';

        // Ajustar dimensões do container para o novo zoom
        const originalWidth = svgElement.viewBox ? svgElement.viewBox.baseVal.width : svgElement.clientWidth;
        const originalHeight = svgElement.viewBox ? svgElement.viewBox.baseVal.height : svgElement.clientHeight;

        container.style.width = `${originalWidth * zoomLevel}px`;
        container.style.height = `${originalHeight * zoomLevel}px`;
      }
    }

    console.log(`Zoom aplicado: ${(zoomLevel * 100).toFixed(0)}%`);

    // Notificar o Flutter sobre a mudança
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('onZoomChanged', { zoomLevel: zoomLevel });
    }

  } catch (error) {
    console.error('Erro ao aplicar zoom:', error);
  }
};

window.setDisplayMode = function(mode) {
  if (!osmd) {
    console.warn('OSMD não disponível para mudança de layout');
    return;
  }

  try {
    console.log(`Alterando modo de exibição para: ${mode}`);

    // Reconfigurar OSMD baseado no modo
    if (mode === 'horizontal') {
      // Modo horizontal - uma linha contínua
      if (osmd.rules) {
        osmd.rules.MaxSystemWidth = 9999; // Largura muito grande para evitar quebras
        osmd.rules.NewSystemFromXMLSystemBreak = false;
        osmd.rules.NewPageFromXMLNewPageAttribute = false;
        osmd.PageFormat = "Endless";
      }

      // Ajustar container para scroll horizontal
      const container = document.getElementById("score-container");
      if (container) {
        container.style.overflowX = 'auto';
        container.style.overflowY = 'hidden';
        container.style.whiteSpace = 'nowrap';
      }

    } else if (mode === 'lineBreak') {
      // Modo com quebras de linha
      if (osmd.rules) {
        osmd.rules.MaxSystemWidth = 350; // Largura padrão mobile
        osmd.rules.NewSystemFromXMLSystemBreak = true;
        osmd.rules.NewPageFromXMLNewPageAttribute = true;
        osmd.PageFormat = "A4_P"; // Formato com quebras
      }

      // Ajustar container para scroll vertical
      const container = document.getElementById("score-container");
      if (container) {
        container.style.overflowX = 'hidden';
        container.style.overflowY = 'auto';
        container.style.whiteSpace = 'normal';
      }
    }

    // Re-renderizar com novas configurações
    osmd.render();
    console.log(`Modo de exibição alterado para: ${mode}`);

    // Reaplicar cores brancas após re-renderização
    setTimeout(() => {
      _applyWhiteColors();
    }, 100);

    // Notificar o Flutter
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('onDisplayModeChanged', { mode: mode });
    }

  } catch (error) {
    console.error('Erro ao alterar modo de exibição:', error);
  }
};