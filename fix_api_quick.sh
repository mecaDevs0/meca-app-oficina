#!/bin/bash

echo "🔧 CORREÇÃO RÁPIDA API MECABR"
echo "============================="

# Connection String MongoDB
MONGO_CONN="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"

echo "1. Status atual PM2..."
pm2 list

echo ""
echo "2. Parando API atual..."
pm2 stop all

echo ""
echo "3. Procurando API..."
API_PATHS=(
    "/home/ubuntu/meca-api-main"
    "/var/www/meca-api-main"
    "/opt/meca-api-main"
    "/home/ubuntu/API_WORKING_COPY_FINAL_20250919_202115"
    "/var/www/API_WORKING_COPY_FINAL_20250919_202115"
)

API_DIR=""
for path in "${API_PATHS[@]}"; do
    if [ -d "$path" ]; then
        API_DIR="$path"
        echo "📁 API encontrada: $API_DIR"
        break
    fi
done

if [ -z "$API_DIR" ]; then
    echo "❌ API não encontrada! Procurando..."
    find /home -name "*meca-api*" -type d 2>/dev/null | head -3
    find /var -name "*meca-api*" -type d 2>/dev/null | head -3
    exit 1
fi

cd "$API_DIR"

echo ""
echo "4. Atualizando configuração MongoDB..."
for config in appsettings.json appsettings.Production.json; do
    if [ -f "$config" ]; then
        echo "🔄 Atualizando $config"
        cp "$config" "$config.backup"
        
        # Substituir connection string MongoDB
        sed -i "s|\"MongoDb\":\s*\"[^\"]*\"|\"MongoDb\": \"$MONGO_CONN\"|g" "$config"
        sed -i "s|\"MongoDB\":\s*\"[^\"]*\"|\"MongoDB\": \"$MONGO_CONN\"|g" "$config"
        sed -i "s|\"DefaultConnection\":\s*\"[^\"]*\"|\"DefaultConnection\": \"$MONGO_CONN\"|g" "$config"
    fi
done

echo ""
echo "5. Compilando aplicação..."
if [ -f "Meca.sln" ]; then
    dotnet restore
    dotnet build --configuration Release
fi

echo ""
echo "6. Iniciando aplicação..."
if [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js --env production
else
    # Procurar executável
    EXE=$(find . -name "Meca.WebApi" -o -name "Meca.WebApi.exe" | head -1)
    if [ -n "$EXE" ]; then
        pm2 start "$EXE" --name "meca-api"
    else
        echo "❌ Executável não encontrado"
        exit 1
    fi
fi

echo ""
echo "7. Verificando resultado..."
sleep 10
pm2 list
pm2 logs --lines 5

echo ""
echo "8. Testando API..."
curl -s -w "Status: %{http_code}\n" "https://api.mecabr.com/api/v1/Workshop/Token" -X POST -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"123456"}'

echo ""
echo "✅ Correção completa!"