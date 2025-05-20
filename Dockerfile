# Etapa 1: build da aplicação
FROM dart:stable AS build

# Instala o Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Aceita as licenças
RUN flutter doctor

# Ativa suporte para web
RUN flutter channel stable && flutter upgrade && flutter config --enable-web

# Cria diretório de app e copia os arquivos
WORKDIR /app
COPY . .

# Cria um usuário não-root para rodar o Flutter
RUN useradd -m flutteruser && chown -R flutteruser:flutteruser /app && chown -R flutteruser:flutteruser /flutter

# Troca para o usuário não-root
USER flutteruser

# Adiciona /flutter como diretório seguro para o git
RUN git config --global --add safe.directory /flutter

# Faz download das dependências
RUN flutter pub get

# Limpa build antigo antes de gerar novo build
RUN flutter clean

# Gera o build web (com verbose para debug)
RUN flutter build web --release --verbose

# Lista todos os arquivos do build para debug
RUN ls -lR build/web

# Volta para root para copiar arquivos na próxima etapa
USER root

# Etapa 2: imagem leve com Nginx para servir o conteúdo
FROM nginx:alpine

# Remove a configuração padrão do nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia o build para a pasta do nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# (Opcional) Liste os arquivos copiados para debug
RUN ls -lR /usr/share/nginx/html

# Copia uma configuração customizada do nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponha a porta 8080
EXPOSE 8080

# Inicia o nginx
CMD ["nginx", "-g", "daemon off;"]
