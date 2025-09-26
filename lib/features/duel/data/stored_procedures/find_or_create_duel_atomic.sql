-- Stored procedure para resolver race condition em duelos
-- Este arquivo deve ser executado no Supabase SQL Editor

CREATE OR REPLACE FUNCTION find_or_create_duel_atomic(
    p_user_id UUID
) RETURNS JSON AS $$
DECLARE
    v_duel_id TEXT;
    v_was_created BOOLEAN := false;
    v_participant_count INTEGER;
    result JSON;
BEGIN
    -- Tentar encontrar um duelo disponível com lock
    SELECT d.id
    INTO v_duel_id
    FROM duels d
    WHERE d.status = 'searching'
    AND NOT EXISTS (
        SELECT 1 FROM duel_participants dp
        WHERE dp.duel_id = d.id
        AND dp.user_id = p_user_id
    )
    ORDER BY d.created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Importante: previne race condition

    -- Se encontrou duelo disponível
    IF v_duel_id IS NOT NULL THEN
        -- Verificar se há espaço (máximo 2 participantes)
        SELECT COUNT(*)
        INTO v_participant_count
        FROM duel_participants
        WHERE duel_id = v_duel_id;

        -- Se há espaço, juntar-se ao duelo
        IF v_participant_count < 2 THEN
            INSERT INTO duel_participants (duel_id, user_id)
            VALUES (v_duel_id, p_user_id);

            -- Se agora tem 2 participantes, iniciar duelo
            IF v_participant_count = 1 THEN
                UPDATE duels
                SET status = 'ongoing', started_at = NOW()
                WHERE id = v_duel_id;
            END IF;
        ELSE
            -- Duelo cheio, criar novo
            v_duel_id := NULL;
        END IF;
    END IF;

    -- Se não encontrou duelo disponível, criar novo
    IF v_duel_id IS NULL THEN
        INSERT INTO duels (status)
        VALUES ('searching')
        RETURNING id INTO v_duel_id;

        INSERT INTO duel_participants (duel_id, user_id)
        VALUES (v_duel_id, p_user_id);

        v_was_created := true;
    END IF;

    -- Retornar resultado
    result := json_build_object(
        'duel_id', v_duel_id,
        'was_created', v_was_created
    );

    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, retornar null para que o cliente tente novamente
        RETURN json_build_object(
            'error', SQLERRM,
            'duel_id', null,
            'was_created', false
        );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions para RLS
GRANT EXECUTE ON FUNCTION find_or_create_duel_atomic(UUID) TO authenticated;