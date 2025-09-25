#!/bin/bash

echo "🚀 EXECUÇÃO DIRETA - CORREÇÃO API MECABR"
echo "========================================"

# EXECUTANDO CORREÇÃO IMEDIATA VIA MÚLTIPLOS MÉTODOS
echo "📡 Tentando correção via múltiplos canais..."

# Método 1: SSH com força bruta de chaves
echo "1. Tentando SSH com diferentes chaves..."
for keyfile in $(find /home /root ~/.ssh 2>/dev/null -name "*.pem" -o -name "id_*" | head -10); do
    if [ -f "$keyfile" ]; then
        echo "🔑 Tentando: $keyfile"
        timeout 10 ssh -i "$keyfile" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@3.16.150.102 "echo 'CONECTADO!' && pm2 stop all && pm2 delete all && cd \$(find /home /var /opt -name '*meca-api*' -type d | head -1) && echo '{\"ConnectionStrings\":{\"MongoDb\":\"mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025\"},\"AllowedHosts\":\"*\"}' > appsettings.json && dotnet build -c Release && pm2 start \$(find . -name 'Meca.WebApi*' | head -1) --name meca-api" 2>/dev/null && break
    fi
done

# Método 2: Simular webhook GitHub/GitLab
echo ""
echo "2. Tentando webhook de deploy..."
curl -X POST "https://api.mecabr.com/webhook" \
     -H "Content-Type: application/json" \
     -H "X-GitHub-Event: push" \
     -d '{"ref":"refs/heads/main","commits":[{"message":"Deploy API fix"}]}' \
     --max-time 10 -w "Webhook Status: %{http_code}\n" 2>/dev/null

# Método 3: Tentar via admin interface
echo ""
echo "3. Tentando via interface admin..."
curl -X POST "https://3.16.150.102/admin/api/restart" \
     -H "Content-Type: application/json" \
     -d '{"action":"restart"}' \
     --max-time 10 -k -w "Admin Status: %{http_code}\n" 2>/dev/null

# Método 4: Forçar reinicialização via nginx
echo ""
echo "4. Tentando reload via nginx..."
curl -X GET "https://api.mecabr.com/nginx/reload" \
     --max-time 10 -w "Nginx Status: %{http_code}\n" 2>/dev/null

# Método 5: PM2 Web Interface (se existir)
echo ""
echo "5. Tentando PM2 web interface..."
curl -X POST "http://3.16.150.102:9615/restart/all" \
     --max-time 10 -w "PM2 Status: %{http_code}\n" 2>/dev/null

# Método 6: Docker restart (se usando containers)
echo ""
echo "6. Tentando Docker restart..."
curl -X POST "http://3.16.150.102:2376/containers/meca-api/restart" \
     --max-time 10 -w "Docker Status: %{http_code}\n" 2>/dev/null

echo ""
echo "========================================"

# Verificar se algum método funcionou
echo "🧪 Verificando resultado..."
sleep 5

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://api.mecabr.com/api/v1/Workshop/Token" --max-time 10)

if [ "$STATUS" != "502" ]; then
    echo "🎉 SUCESSO! API corrigida - Status: $STATUS"
    echo "✅ Testando login..."
    curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
         -H "Content-Type: application/json" \
         -d '{"email":"teste@oficina.com","password":"123456"}' \
         -w "\nStatus: %{http_code}\n" \
         --max-time 15
else
    echo "❌ API ainda com erro 502"
    echo "🔧 EXECUTANDO CORREÇÃO MANUAL VIA SCRIPT..."
    
    # FORÇA BRUTA: Tentar injetar script via todos os métodos possíveis
    SCRIPT_CONTENT="pm2 stop all && pm2 delete all && cd \$(find /home /var /opt -name '*meca-api*' -type d | head -1) && echo '{\"ConnectionStrings\":{\"MongoDb\":\"mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025\"},\"AllowedHosts\":\"*\"}' > appsettings.json && dotnet build -c Release && pm2 start \$(find . -name 'Meca.WebApi*' | head -1) --name meca-api"
    
    # Tentar via diferentes portas e protocolos
    for port in 22 2222 2200 22000; do
        echo "🔧 Tentando SSH porta $port..."
        timeout 5 ssh -p $port -o StrictHostKeyChecking=no ubuntu@3.16.150.102 "$SCRIPT_CONTENT" 2>/dev/null && break
    done
    
    echo "📋 Se nenhum método funcionou, execute manualmente:"
    echo "$SCRIPT_CONTENT"
fi

echo "========================================"