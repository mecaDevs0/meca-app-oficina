#!/bin/bash

echo "🚀 CORREÇÃO DA API MECABR"
echo "========================="

# Connection String fornecida pelo usuário
MONGODB_CONNECTION="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"

echo ""
echo "1. Parando serviços para manutenção..."
pm2 stop all || echo "PM2 não disponível ou sem processos"

echo ""
echo "2. Localizando diretório da API..."
if [ -d "/home/ubuntu/meca-api-main" ]; then
    API_DIR="/home/ubuntu/meca-api-main"
elif [ -d "/var/www/meca-api-main" ]; then
    API_DIR="/var/www/meca-api-main"
elif [ -d "/opt/meca-api-main" ]; then
    API_DIR="/opt/meca-api-main"
else
    echo "❌ Diretório da API não encontrado!"
    find / -name "*meca-api*" -type d 2>/dev/null | head -5
    exit 1
fi

echo "📁 API encontrada em: $API_DIR"
cd "$API_DIR"

echo ""
echo "3. Fazendo backup dos arquivos de configuração..."
if [ -f "appsettings.json" ]; then
    cp appsettings.json appsettings.json.backup.$(date +%Y%m%d_%H%M%S)
fi
if [ -f "appsettings.Production.json" ]; then
    cp appsettings.Production.json appsettings.Production.json.backup.$(date +%Y%m%d_%H%M%S)
fi

echo ""
echo "4. Atualizando connection string do MongoDB..."

# Procurar por arquivos de configuração
CONFIG_FILES="appsettings.json appsettings.Production.json"

for file in $CONFIG_FILES; do
    if [ -f "$file" ]; then
        echo "🔄 Atualizando $file..."
        
        # Backup
        cp "$file" "${file}.bak"
        
        # Atualizar connection string
        if grep -q "ConnectionStrings" "$file"; then
            # Usar sed para atualizar a connection string
            sed -i 's|"MongoDb":\s*"[^"]*"|"MongoDb": "'"$MONGODB_CONNECTION"'"|g' "$file"
            sed -i 's|"MongoDB":\s*"[^"]*"|"MongoDB": "'"$MONGODB_CONNECTION"'"|g' "$file"
            sed -i 's|"DefaultConnection":\s*"[^"]*"|"DefaultConnection": "'"$MONGODB_CONNECTION"'"|g' "$file"
        else
            echo "⚠️ Seção ConnectionStrings não encontrada em $file"
        fi
    fi
done

echo ""
echo "5. Verificando estrutura do projeto..."
ls -la

echo ""
echo "6. Compilando aplicação .NET..."
if [ -f "*.csproj" ] || [ -f "*.sln" ]; then
    dotnet restore
    dotnet build --configuration Release
else
    echo "⚠️ Projeto .NET não identificado"
fi

echo ""
echo "7. Iniciando aplicação via PM2..."

# Verificar se há um ecosystem.config.js
if [ -f "ecosystem.config.js" ]; then
    echo "📋 Usando ecosystem.config.js"
    pm2 start ecosystem.config.js --env production
else
    # Tentar identificar o executável
    if [ -f "bin/Release/net*/Meca.WebApi" ]; then
        EXE_PATH=$(find bin/Release -name "Meca.WebApi" -type f | head -1)
        pm2 start "$EXE_PATH" --name "meca-api"
    elif [ -f "bin/Release/net*/Meca.WebApi.exe" ]; then
        EXE_PATH=$(find bin/Release -name "Meca.WebApi.exe" -type f | head -1)
        pm2 start "$EXE_PATH" --name "meca-api"
    else
        echo "❌ Executável não encontrado!"
        find . -name "*.exe" -o -name "Meca.WebApi" | head -5
        exit 1
    fi
fi

echo ""
echo "8. Verificando status dos serviços..."
sleep 5
pm2 list
pm2 logs --lines 10

echo ""
echo "9. Testando endpoints..."
sleep 5

echo "🧪 Testando login endpoint..."
curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
     -H "Content-Type: application/json" \
     -d '{"email":"teste@test.com","password":"123456"}' \
     -s -w "Status: %{http_code}\n" || echo "Teste falhou"

echo ""
echo "========================="
echo "✅ Correção completa!"
echo "📊 Verifique os logs com: pm2 logs"