-- ==========================================
-- SQL para criação da tabela solfege_progress no Supabase
-- ==========================================

-- Tabela para armazenar o progresso dos usuários nos exercícios de solfejo
CREATE TABLE IF NOT EXISTS public.solfege_progress (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL REFERENCES public.practice_solfege(id) ON DELETE CASCADE,
    best_score INTEGER NOT NULL DEFAULT 0 CHECK (best_score >= 0 AND best_score <= 100),
    attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    first_completed_at TIMESTAMPTZ NULL,
    last_attempt_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garantir que cada usuário tenha apenas um progresso por exercício
    UNIQUE(user_id, exercise_id)
);

-- Índices para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_solfege_progress_user_id ON public.solfege_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_solfege_progress_exercise_id ON public.solfege_progress(exercise_id);
CREATE INDEX IF NOT EXISTS idx_solfege_progress_user_exercise ON public.solfege_progress(user_id, exercise_id);
CREATE INDEX IF NOT EXISTS idx_solfege_progress_unlocked ON public.solfege_progress(user_id, is_unlocked);

-- Trigger para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION update_solfege_progress_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_solfege_progress_updated_at
    BEFORE UPDATE ON public.solfege_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_solfege_progress_updated_at();

-- Políticas RLS (Row Level Security)
ALTER TABLE public.solfege_progress ENABLE ROW LEVEL SECURITY;

-- Política para permitir que usuários vejam apenas seu próprio progresso
CREATE POLICY "Users can view own solfege progress" ON public.solfege_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Política para permitir que usuários insiram seu próprio progresso
CREATE POLICY "Users can insert own solfege progress" ON public.solfege_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para permitir que usuários atualizem seu próprio progresso
CREATE POLICY "Users can update own solfege progress" ON public.solfege_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Comentários para documentação
COMMENT ON TABLE public.solfege_progress IS 'Armazena o progresso dos usuários nos exercícios de solfejo';
COMMENT ON COLUMN public.solfege_progress.user_id IS 'ID do usuário (referência para auth.users)';
COMMENT ON COLUMN public.solfege_progress.exercise_id IS 'ID do exercício (referência para practice_solfege)';
COMMENT ON COLUMN public.solfege_progress.best_score IS 'Melhor pontuação obtida (0-100%)';
COMMENT ON COLUMN public.solfege_progress.attempts IS 'Número total de tentativas';
COMMENT ON COLUMN public.solfege_progress.is_unlocked IS 'Se o exercício está desbloqueado para o usuário';
COMMENT ON COLUMN public.solfege_progress.first_completed_at IS 'Data da primeira conclusão (score >= 50%)';
COMMENT ON COLUMN public.solfege_progress.last_attempt_at IS 'Data da última tentativa';