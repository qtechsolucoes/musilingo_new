# ai_server/Dockerfile

# Usamos uma imagem base do Python que é leve e eficiente
FROM python:3.9-slim-bullseye

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o arquivo de dependências primeiro para aproveitar o cache do Docker
COPY requirements.txt .

# Instala as bibliotecas do projeto (agora mais leve, sem ffmpeg)
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do código da aplicação
COPY . .

# Expõe a porta que a nossa aplicação Flask vai usar
EXPOSE 5000

# O comando para iniciar a aplicação quando o container for executado
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]