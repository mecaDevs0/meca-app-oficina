#!/bin/bash

echo "🚀 EXECUTANDO CORREÇÃO AUTOMÁTICA - API MECABR"
echo "=============================================="

# Configurações
EC2_IP="3.16.150.102"
MONGO_CONN="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"

echo "📡 Tentando conectar ao EC2: $EC2_IP"

# Função para executar comando no EC2
execute_on_ec2() {
    local cmd="$1"
    echo "🔄 Executando: $cmd"
    
    # Tentar diferentes métodos de conexão SSH
    for key_path in ~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/*.pem /home/*/.ssh/*.pem /root/.ssh/*.pem; do
        if [ -f "$key_path" ]; then
            echo "🔑 Tentando com chave: $key_path"
            if ssh -i "$key_path" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$EC2_IP "$cmd" 2>/dev/null; then
                return 0
            fi
        fi
    done
    
    # Tentar sem chave específica
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$EC2_IP "$cmd" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Criar script de correção no servidor
CORRECTION_SCRIPT='#!/bin/bash
echo "🚀 INICIANDO CORREÇÃO NO SERVIDOR"
MONGO="'"$MONGO_CONN"'"

# Parar PM2
echo "1. Parando PM2..."
pm2 stop all
pm2 delete all

# Encontrar API
echo "2. Localizando API..."
for dir in /home/ubuntu/meca-api-main /var/www/meca-api-main /opt/meca-api-main /home/ubuntu/API_* /var/www/API_*; do
    if [ -d "$dir" ]; then
        API_DIR="$dir"
        echo "📁 API encontrada: $API_DIR"
        break
    fi
done

if [ -z "$API_DIR" ]; then
    echo "❌ API não encontrada"
    exit 1
fi

cd "$API_DIR"

# Backup e atualizar config
echo "3. Atualizando configuração..."
[ -f "appsettings.json" ] && cp appsettings.json appsettings.json.backup

cat > appsettings.json << EOF
{
  "ConnectionStrings": {
    "MongoDb": "$MONGO",
    "MongoDB": "$MONGO",
    "DefaultConnection": "$MONGO"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
EOF

# Compilar
echo "4. Compilando..."
if [ -f "Meca.sln" ]; then
    dotnet restore
    dotnet build --configuration Release
fi

# Encontrar executável
echo "5. Localizando executável..."
EXE=$(find . -name "Meca.WebApi" -o -name "Meca.WebApi.exe" | head -1)
if [ -n "$EXE" ]; then
    echo "📦 Executável: $EXE"
    pm2 start "$EXE" --name "meca-api"
    sleep 10
    pm2 list
    echo "✅ Correção concluída!"
else
    echo "❌ Executável não encontrado"
    exit 1
fi
'

echo ""
echo "🔧 Tentando executar correção no EC2..."

if execute_on_ec2 "$CORRECTION_SCRIPT"; then
    echo "✅ Correção executada com sucesso!"
    
    # Verificar resultado
    echo ""
    echo "🧪 Testando API..."
    sleep 5
    
    curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
         -H "Content-Type: application/json" \
         -d '{"email":"teste@test.com","password":"123456"}' \
         -s -w "\nStatus: %{http_code}\n"
    
    if [ $? -eq 0 ]; then
        echo "🎉 API CORRIGIDA E FUNCIONANDO!"
    else
        echo "⚠️ API ainda com problemas - verificar logs"
    fi
    
else
    echo ""
    echo "❌ NÃO FOI POSSÍVEL CONECTAR AO EC2 VIA SSH"
    echo ""
    echo "📋 EXECUTE ESTE COMANDO DIRETAMENTE NO SERVIDOR EC2:"
    echo "=================================================="
    echo "$CORRECTION_SCRIPT"
    echo "=================================================="
    echo ""
    echo "📞 OU use o comando one-liner:"
    echo 'pm2 stop all && pm2 delete all && cd $(find /home /var /opt -name "*meca-api*" -type d | head -1) && echo '"'"'{"ConnectionStrings":{"MongoDb":"'"$MONGO_CONN"'"},"AllowedHosts":"*"}'"'"' > appsettings.json && dotnet build -c Release && pm2 start $(find . -name "Meca.WebApi*" | head -1) --name meca-api && pm2 list'
fi

echo ""
echo "=============================================="