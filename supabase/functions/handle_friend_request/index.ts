import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  // Trata a requisição OPTIONS para CORS, necessária para a invocação a partir do navegador
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Cria um cliente Supabase que se autentica como o usuário que fez a chamada
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // Obtém os dados do usuário autenticado a partir do token
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: 'Acesso não autorizado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      });
    }

    // Extrai o ID do usuário alvo e a ação a ser executada do corpo da requisição
    const { target_user_id, action } = await req.json();

    if (!target_user_id || !action) {
      return new Response(JSON.stringify({ error: 'Parâmetros em falta: target_user_id e action são obrigatórios.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const current_user_id = user.id;

    // Lógica para adicionar um amigo
    if (action === 'add') {
      const { error } = await supabase.from('friends').insert({
        user_id: current_user_id,
        friend_id: target_user_id,
        status: 'pending',
      });
      if (error) throw error;
      return new Response(JSON.stringify({ message: 'Pedido de amizade enviado.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 201,
      });
    }

    // Lógica para aceitar um pedido de amizade
    if (action === 'accept') {
      const { error } = await supabase.from('friends')
        .update({ status: 'accepted' })
        .eq('user_id', target_user_id) // O pedido foi enviado pelo target_user_id
        .eq('friend_id', current_user_id); // E recebido pelo usuário atual
      if (error) throw error;
      
      return new Response(JSON.stringify({ message: 'Amizade aceite.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Lógica para remover ou recusar uma amizade
    if (action === 'remove' || action === 'decline') {
      const { error } = await supabase.from('friends')
        .delete()
        .or(`(user_id.eq.${current_user_id},friend_id.eq.${target_user_id}),(user_id.eq.${target_user_id},friend_id.eq.${current_user_id})`);
      if (error) throw error;
      return new Response(JSON.stringify({ message: 'Amizade removida/recusada.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    return new Response(JSON.stringify({ error: 'Ação inválida.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});