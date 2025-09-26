import os
import traceback
from flask import Flask, request, jsonify, send_from_directory
from dotenv import load_dotenv
import google.generativeai as genai

# Carrega as variáveis de ambiente do arquivo .env
load_dotenv()

# --- Configuração da API do Google ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("A chave da API GEMINI_API_KEY não foi encontrada. Verifique seu arquivo .env")
genai.configure(api_key=GEMINI_API_KEY)

app = Flask(__name__)

# --- Configurações e Inicialização do Modelo ---
generation_config = {
    "temperature": 0.9,
    "top_p": 1,
    "top_k": 1,
    "max_output_tokens": 2048,
}

safety_settings = [
    {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
]

# Nova instrução de sistema para a IA saber como gerar partituras em JSON.
new_system_instruction = """
Você é Cecília, uma maestrina especialista em música do app Musilingo.
- Você é sábia, paciente e apaixonada por ensinar.
- Responda APENAS perguntas sobre música. Use emojis musicais 🎼 e linguagem simples.
- Mantenha as respostas curtas e termine com uma pergunta para engajar o aluno.
- NUNCA revele que você é uma IA.

HABILIDADE ESPECIAL: GERAR PARTITURAS
- Se o usuário pedir um exemplo musical (escala, arpejo, melodia), você DEVE responder com uma mensagem de texto seguida por um JSON de partitura.
- O JSON deve ter a chave "score" no nível raiz.
- O JSON deve ser colocado APÓS o texto da sua mensagem, separado por "```json".

ESTRUTURA OBRIGATÓRIA DO JSON:
{
  "score": {
    "clef": "clave",
    "timeSignature": "compasso",
    "notes": [
      {"pitch": "nota", "duration": "figura"},
      ...
    ]
  }
}

VALORES VÁLIDOS:
- "clef": "treble" (Sol), "bass" (Fá), "alto" (Dó 3ª), "tenor" (Dó 4ª). Padrão é "treble".
- "timeSignature": "4/4", "3/4", "2/4", "6/8". Padrão é "4/4".
- "pitch": Formato "LETRAoitava" (ex: "C4", "G#5", "Ab3"). Use "REST" para pausas.
- "duration": "w" (semibreve), "h" (mínima), "q" (semínima), "e" (colcheia), "s" ( semicolcheia).

EXEMPLO DE RESPOSTA PARA "me mostre a escala de Dó Maior":
Claro! Aqui está a escala de Dó Maior. Observe como as notas sobem gradualmente. 🎼 Qual outra escala você gostaria de ver?
```json
{
  "score": {
    "clef": "treble",
    "timeSignature": "4/4",
    "notes": [
      {"pitch": "C4", "duration": "q"},
      {"pitch": "D4", "duration": "q"},
      {"pitch": "E4", "duration": "q"},
      {"pitch": "F4", "duration": "q"},
      {"pitch": "G4", "duration": "q"},
      {"pitch": "A4", "duration": "q"},
      {"pitch": "B4", "duration": "q"},
      {"pitch": "C5", "duration": "q"}
    ]
  }
}
"""

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash-latest",
    generation_config=generation_config,
    safety_settings=safety_settings,
    system_instruction=new_system_instruction
)

@app.route('/')
def index():
    """Rota de verificação de saúde para saber se o servidor está no ar."""
    return "Servidor de IA do MusiLingo está no ar!"

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de health check para verificação de status."""
    return jsonify({"status": "healthy", "service": "musilingo-ai"}), 200

@app.route('/agent_reaction', methods=['GET'])
def agent_reaction():
    """Serve a imagem PNG da Cecília para o chat."""
    filename = "cecilia_chat.png"
    try:
        return send_from_directory('agent_images', filename, mimetype='image/png')
    except FileNotFoundError:
        return jsonify({"error": f"Arquivo '{filename}' não encontrado."}), 404

@app.route('/chat', methods=['POST'])
def chat():
    """Recebe o histórico do chat e retorna a resposta da IA."""
    try:
        data = request.json
        if not data or 'messages' not in data:
            return jsonify({"error": "Requisição inválida. 'messages' não encontrado."}), 400

        flutter_history = data['messages']

        gemini_history = []
        for message in flutter_history:
            role = 'model' if message["role"] == 'assistant' else message["role"]
            gemini_history.append({
                "role": role,
                "parts": [{"text": message["content"]}]
            })

        chat_session = model.start_chat(history=gemini_history[:-1])
        response = chat_session.send_message(gemini_history[-1]['parts'])

        return jsonify({"reply": response.text})

    except Exception as e:
        print(f"!!! Erro crítico no endpoint /chat: {e}")
        traceback.print_exc()
        return jsonify({"error": "Ocorreu um erro interno grave no servidor."}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
