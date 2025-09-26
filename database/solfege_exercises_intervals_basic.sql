-- ==========================================
-- Exercícios de Solfejo - Progressão Correta de Intervalos
-- Começando com intervalos simples e evoluindo gradualmente
-- ==========================================

-- Limpar exercícios existentes
DELETE FROM public.practice_solfege;

-- ==========================================
-- NÍVEL 1: INTERVALOS DE 2ª (1-10)
-- ==========================================

INSERT INTO public.practice_solfege (title, difficulty_level, difficulty_value, key_signature, time_signature, tempo, note_sequence, clef) VALUES

-- 2ª Maior Ascendente
('2ª Maior Ascendente', 'basico', 1, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"half"}]', 'treble'),

('2ª Maior Descendente', 'basico', 2, 'C', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('2ª Maior Ré-Mi', 'basico', 3, 'C', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"half"}]', 'treble'),

('2ª Maior Mi-Fá', 'basico', 4, 'C', '4/4', 80, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"half"}]', 'treble'),

('2ª Maior Fá-Sol', 'basico', 5, 'C', '4/4', 80, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

('2ª Maior Sol-Lá', 'basico', 6, 'C', '4/4', 80, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"half"}]', 'treble'),

('2ª Maior Lá-Si', 'basico', 7, 'C', '4/4', 80, '[{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"half"}]', 'treble'),

('2ª Maior Si-Dó', 'basico', 8, 'C', '4/4', 80, '[{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"half"}]', 'treble'),

('2ª Maior Variada Ascendente', 'basico', 9, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

('2ª Maior Variada Descendente', 'basico', 10, 'C', '4/4', 85, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

-- ==========================================
-- NÍVEL 2: INTERVALOS DE 3ª (11-20)
-- ==========================================

('3ª Maior Dó-Mi', 'basico', 11, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"half"}]', 'treble'),

('3ª Maior Descendente Mi-Dó', 'basico', 12, 'C', '4/4', 80, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('3ª Maior Ré-Fá#', 'basico', 13, 'G', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F#4","lyric":"Fá#","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F#4","lyric":"Fá#","duration":"half"}]', 'treble'),

('3ª Menor Ré-Fá', 'basico', 14, 'C', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"half"}]', 'treble'),

('3ª Menor Mi-Sol', 'basico', 15, 'C', '4/4', 80, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

('3ª Maior Fá-Lá', 'basico', 16, 'C', '4/4', 80, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"half"}]', 'treble'),

('3ª Menor Sol-Sib', 'basico', 17, 'F', '4/4', 80, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"Bb4","lyric":"Sib","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"Bb4","lyric":"Sib","duration":"half"}]', 'treble'),

('3ª Maior Sol-Si', 'basico', 18, 'C', '4/4', 80, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"half"}]', 'treble'),

('3ª Combinada Asc-Desc', 'basico', 19, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('3ª Sequência Variada', 'basico', 20, 'C', '4/4', 85, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

-- ==========================================
-- NÍVEL 3: INTERVALOS DE 4ª (21-30)
-- ==========================================

('4ª Justa Dó-Fá', 'iniciante', 1, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"half"}]', 'treble'),

('4ª Justa Descendente Fá-Dó', 'iniciante', 2, 'C', '4/4', 80, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('4ª Justa Ré-Sol', 'iniciante', 3, 'C', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

('4ª Justa Mi-Lá', 'iniciante', 4, 'C', '4/4', 80, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"half"}]', 'treble'),

('4ª Aumentada Fá-Si', 'iniciante', 5, 'C', '4/4', 75, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"half"}]', 'treble'),

('4ª Justa Sol-Dó', 'iniciante', 6, 'C', '4/4', 80, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"half"}]', 'treble'),

('4ª Justa Lá-Ré', 'iniciante', 7, 'C', '4/4', 80, '[{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"D5","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"D5","lyric":"Ré","duration":"half"}]', 'treble'),

('4ª Combinada Asc-Desc', 'iniciante', 8, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('4ª Sequência Mista', 'iniciante', 9, 'C', '4/4', 85, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"half"}]', 'treble'),

('4ª Movimento Ondulado', 'iniciante', 10, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"}]', 'treble'),

-- ==========================================
-- NÍVEL 4: INTERVALOS DE 5ª (31-40)
-- ==========================================

('5ª Justa Dó-Sol', 'iniciante', 11, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"half"}]', 'treble'),

('5ª Justa Descendente Sol-Dó', 'iniciante', 12, 'C', '4/4', 80, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('5ª Justa Ré-Lá', 'iniciante', 13, 'C', '4/4', 80, '[{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"half"}]', 'treble'),

('5ª Justa Mi-Si', 'iniciante', 14, 'C', '4/4', 80, '[{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"half"}]', 'treble'),

('5ª Justa Fá-Dó', 'iniciante', 15, 'C', '4/4', 80, '[{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C5","lyric":"Dó","duration":"half"}]', 'treble'),

('5ª Diminuta Si-Fá', 'iniciante', 16, 'C', '4/4', 75, '[{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"F5","lyric":"Fá","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"},{"note":"F5","lyric":"Fá","duration":"half"}]', 'treble'),

('5ª Justa Lá-Mi', 'iniciante', 17, 'C', '4/4', 80, '[{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"E5","lyric":"Mi","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"E5","lyric":"Mi","duration":"half"}]', 'treble'),

('5ª Combinada Asc-Desc', 'iniciante', 18, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble'),

('5ª Sequência Variada', 'iniciante', 19, 'C', '4/4', 85, '[{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"half"}]', 'treble'),

('5ª Movimento Complexo', 'iniciante', 20, 'C', '4/4', 80, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"B4","lyric":"Si","duration":"quarter"}]', 'treble'),

-- ==========================================
-- NÍVEL 5: INTERVALOS MISTOS E PROGRESSÕES (41-50)
-- ==========================================

('Mistos 2ª e 3ª', 'intermediário', 1, 'C', '4/4', 90, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"}]', 'treble'),

('Mistos 3ª e 4ª', 'intermediário', 2, 'C', '4/4', 90, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Mistos 4ª e 5ª', 'intermediário', 3, 'C', '4/4', 90, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Sobe 2ª Desce 3ª', 'intermediário', 4, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"B3","lyric":"Si","duration":"quarter"}]', 'treble'),

('Sobe 3ª Desce 2ª', 'intermediário', 5, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Sobe 4ª Desce 3ª', 'intermediário', 6, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Sobe 5ª Desce 4ª', 'intermediário', 7, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Intervalos Crescentes', 'intermediário', 8, 'C', '4/4', 90, '[{"note":"C4","lyric":"Dó","duration":"eighth"},{"note":"D4","lyric":"Ré","duration":"eighth"},{"note":"E4","lyric":"Mi","duration":"eighth"},{"note":"F4","lyric":"Fá","duration":"eighth"},{"note":"G4","lyric":"Sol","duration":"eighth"},{"note":"C5","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Intervalos Decrescentes', 'intermediário', 9, 'C', '4/4', 90, '[{"note":"C5","lyric":"Dó","duration":"eighth"},{"note":"A4","lyric":"Lá","duration":"eighth"},{"note":"F4","lyric":"Fá","duration":"eighth"},{"note":"E4","lyric":"Mi","duration":"eighth"},{"note":"D4","lyric":"Ré","duration":"eighth"},{"note":"C4","lyric":"Dó","duration":"quarter"}]', 'treble'),

('Movimento Zigzag', 'intermediário', 10, 'C', '4/4', 85, '[{"note":"C4","lyric":"Dó","duration":"quarter"},{"note":"G4","lyric":"Sol","duration":"quarter"},{"note":"D4","lyric":"Ré","duration":"quarter"},{"note":"A4","lyric":"Lá","duration":"quarter"},{"note":"E4","lyric":"Mi","duration":"quarter"},{"note":"F4","lyric":"Fá","duration":"quarter"},{"note":"C4","lyric":"Dó","duration":"half"}]', 'treble');

-- Atualizar sequência para IDs automáticos
SELECT setval('practice_solfege_id_seq', (SELECT MAX(id) FROM practice_solfege) + 1);