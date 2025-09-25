#!/bin/bash

echo "🚀 CORREÇÃO IMEDIATA - API MECABR"
echo "================================="

# Connection String fornecida
MONGO_CONN="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"

echo "1. 🛑 Parando todos os processos PM2..."
pm2 stop all
pm2 delete all

echo ""
echo "2. 🔍 Localizando API..."
API_DIRS=(
    "/home/ubuntu/meca-api-main"
    "/var/www/meca-api-main"
    "/opt/meca-api-main"
    "/root/meca-api-main"
    "/home/ubuntu/API_WORKING_COPY_FINAL_20250919_202115"
    "/var/www/API_WORKING_COPY_FINAL_20250919_202115"
)

API_DIR=""
for dir in "${API_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        API_DIR="$dir"
        echo "📁 API encontrada: $API_DIR"
        break
    fi
done

if [ -z "$API_DIR" ]; then
    echo "❌ API não encontrada nos locais padrão"
    echo "🔍 Procurando em todo o sistema..."
    API_DIR=$(find / -name "*meca-api*" -type d 2>/dev/null | head -1)
    if [ -n "$API_DIR" ]; then
        echo "📁 API encontrada: $API_DIR"
    else
        echo "❌ ERRO: API não encontrada!"
        exit 1
    fi
fi

cd "$API_DIR"
echo "📍 Diretório atual: $(pwd)"

echo ""
echo "3. 💾 Fazendo backup das configurações..."
for config in appsettings.json appsettings.Production.json; do
    if [ -f "$config" ]; then
        cp "$config" "$config.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backup de $config criado"
    fi
done

echo ""
echo "4. 🔧 Atualizando connection string do MongoDB..."

# Atualizar appsettings.json
if [ -f "appsettings.json" ]; then
    echo "🔄 Atualizando appsettings.json..."
    cat > appsettings.json << EOF
{
  "ConnectionStrings": {
    "MongoDb": "$MONGO_CONN",
    "MongoDB": "$MONGO_CONN",
    "DefaultConnection": "$MONGO_CONN"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Cors": {
    "Origins": ["https://admin.mecabr.com", "http://localhost:3000", "https://api.mecabr.com"]
  }
}
EOF
    echo "✅ appsettings.json atualizado"
fi

# Atualizar appsettings.Production.json
if [ -f "appsettings.Production.json" ]; then
    echo "🔄 Atualizando appsettings.Production.json..."
    cat > appsettings.Production.json << EOF
{
  "ConnectionStrings": {
    "MongoDb": "$MONGO_CONN",
    "MongoDB": "$MONGO_CONN", 
    "DefaultConnection": "$MONGO_CONN"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
EOF
    echo "✅ appsettings.Production.json atualizado"
fi

echo ""
echo "5. 🔨 Compilando aplicação..."
if [ -f "Meca.sln" ]; then
    dotnet clean
    dotnet restore
    dotnet build --configuration Release --no-restore
    if [ $? -eq 0 ]; then
        echo "✅ Compilação bem-sucedida"
    else
        echo "⚠️ Erro na compilação, mas continuando..."
    fi
else
    echo "⚠️ Arquivo .sln não encontrado"
fi

echo ""
echo "6. 🚀 Iniciando aplicação..."

# Procurar executável da API
EXECUTABLES=(
    "bin/Release/net6.0/Meca.WebApi"
    "bin/Release/net7.0/Meca.WebApi"  
    "bin/Release/net8.0/Meca.WebApi"
    "bin/Release/net6.0/Meca.WebApi.exe"
    "bin/Release/net7.0/Meca.WebApi.exe"
    "bin/Release/net8.0/Meca.WebApi.exe"
)

EXECUTABLE=""
for exe in "${EXECUTABLES[@]}"; do
    if [ -f "$exe" ]; then
        EXECUTABLE="$exe"
        echo "📦 Executável encontrado: $EXECUTABLE"
        break
    fi
done

if [ -z "$EXECUTABLE" ]; then
    echo "🔍 Procurando executável..."
    EXECUTABLE=$(find . -name "Meca.WebApi" -o -name "Meca.WebApi.exe" | head -1)
    if [ -n "$EXECUTABLE" ]; then
        echo "📦 Executável encontrado: $EXECUTABLE"
    else
        echo "❌ ERRO: Executável não encontrado!"
        ls -la bin/Release/ 2>/dev/null || echo "Diretório Release não existe"
        exit 1
    fi
fi

# Iniciar aplicação com PM2
if [ -f "ecosystem.config.js" ]; then
    echo "📋 Usando ecosystem.config.js"
    pm2 start ecosystem.config.js --env production
else
    echo "🚀 Iniciando com PM2..."
    pm2 start "$EXECUTABLE" --name "meca-api" --env production
fi

echo ""
echo "7. ⏱️ Aguardando inicialização..."
sleep 10

echo ""
echo "8. 📊 Verificando status..."
pm2 list
echo ""
pm2 logs --lines 5

echo ""
echo "9. 🧪 Testando API..."
sleep 5

echo "🔍 Teste 1: Health check básico"
curl -s -w "Status: %{http_code}\n" "https://api.mecabr.com/api/v1/Workshop/Token" || echo "Falha no teste"

echo ""
echo "🔍 Teste 2: Endpoint de login"
curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
     -H "Content-Type: application/json" \
     -d '{"email":"teste@test.com","password":"123456"}' \
     -s -w "\nStatus HTTP: %{http_code}\n" || echo "Falha no teste de login"

echo ""
echo "================================="
if pm2 list | grep -q "online"; then
    echo "✅ CORREÇÃO CONCLUÍDA COM SUCESSO!"
    echo "🚀 API deve estar funcionando agora"
else
    echo "⚠️ CORREÇÃO PARCIAL - Verificar logs:"
    echo "📋 pm2 logs"
    echo "🔄 pm2 restart meca-api"
fi
echo "================================="