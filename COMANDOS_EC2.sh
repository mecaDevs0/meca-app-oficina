#!/bin/bash

echo "🖥️ COMANDOS PARA EXECUTAR NO EC2 - CORREÇÃO API MECABR"
echo "======================================================"

echo ""
echo "📋 PASSO 1: DIAGNÓSTICO INICIAL"
echo "--------------------------------"
echo "Execute no EC2:"
cat << 'EOF'
# Verificar status atual
pm2 list

# Ver logs da API
pm2 logs --lines 20

# Verificar processos
ps aux | grep -E "(dotnet|mono|node)" | head -5

# Testar API atual
curl -s -w "Status: %{http_code}\n" "https://api.mecabr.com/api/v1/Workshop/Token"
EOF

echo ""
echo "📋 PASSO 2: CORREÇÃO RÁPIDA"
echo "---------------------------"
echo "Execute este bloco completo no EC2:"
cat << 'EOF'
# Connection String MongoDB
MONGO_CONN="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"

# Parar processos
pm2 stop all

# Procurar API
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
    echo "❌ Procurando API..."
    find /home -name "*meca-api*" -type d 2>/dev/null | head -3
    find /var -name "*meca-api*" -type d 2>/dev/null | head -3
    exit 1
fi

cd "$API_DIR"
echo "📍 Diretório atual: $(pwd)"

# Atualizar configuração
for config in appsettings.json appsettings.Production.json; do
    if [ -f "$config" ]; then
        echo "🔄 Atualizando $config"
        cp "$config" "$config.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Atualizar MongoDB connection
        sed -i "s|\"MongoDb\":\s*\"[^\"]*\"|\"MongoDb\": \"$MONGO_CONN\"|g" "$config"
        sed -i "s|\"MongoDB\":\s*\"[^\"]*\"|\"MongoDB\": \"$MONGO_CONN\"|g" "$config"
        
        echo "✅ $config atualizado"
    fi
done

# Compilar
if [ -f "Meca.sln" ]; then
    echo "🔨 Compilando..."
    dotnet restore
    dotnet build --configuration Release
fi

# Iniciar
if [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js --env production
else
    EXE=$(find . -name "Meca.WebApi" -o -name "Meca.WebApi.exe" | head -1)
    if [ -n "$EXE" ]; then
        pm2 start "$EXE" --name "meca-api"
    fi
fi

# Verificar
sleep 10
pm2 list
pm2 logs --lines 5
EOF

echo ""
echo "📋 PASSO 3: TESTE FINAL"
echo "-----------------------"
echo "Execute para testar:"
cat << 'EOF'
# Testar API
curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
     -H "Content-Type: application/json" \
     -d '{"email":"teste@oficina.com","password":"123456"}' \
     -s -w "\nStatus: %{http_code}\n"

# Verificar outros endpoints básicos
curl -s -w "Status: %{http_code}\n" "https://api.mecabr.com/api/v1/Workshop/GetInfo" \
     -H "Authorization: Bearer SEU_TOKEN_AQUI"
EOF

echo ""
echo "📋 COMANDOS DE MONITORAMENTO"
echo "----------------------------"
cat << 'EOF'
# Ver logs em tempo real
pm2 logs

# Ver status detalhado
pm2 show meca-api

# Reiniciar se necessário  
pm2 restart meca-api

# Ver uso de recursos
pm2 monit
EOF

echo ""
echo "======================================================"
echo "✅ Execute os comandos na ordem apresentada"
echo "🔄 Após execução, teste com: python3 test_oficina_endpoints.py"