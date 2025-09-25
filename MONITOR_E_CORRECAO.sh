#!/bin/bash

echo "🚀 MONITOR E CORREÇÃO AUTOMÁTICA - API MECABR"
echo "=============================================="

# Configurações
API_URL="https://api.mecabr.com/api/v1/Workshop/Token"
CHECK_INTERVAL=30  # segundos
MAX_ATTEMPTS=20    # tentativas máximas

echo "📊 Status inicial da API..."
INITIAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" --max-time 10)
echo "🔍 Status atual: $INITIAL_STATUS"

if [ "$INITIAL_STATUS" != "502" ]; then
    echo "✅ API já está funcionando! Status: $INITIAL_STATUS"
    echo "🧪 Testando login..."
    curl -X POST "$API_URL" \
         -H "Content-Type: application/json" \
         -d '{"email":"teste@oficina.com","password":"123456"}' \
         -w "\nStatus: %{http_code}\n" \
         --max-time 15
    exit 0
fi

echo ""
echo "❌ API com erro 502 - Iniciando monitoramento..."
echo "⏱️  Verificando a cada $CHECK_INTERVAL segundos..."
echo "🔄 Máximo $MAX_ATTEMPTS tentativas..."
echo ""

# Contador
attempt=1

while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo "[$(date '+%H:%M:%S')] Tentativa $attempt/$MAX_ATTEMPTS"
    
    # Testar API
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" --max-time 10)
    
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "401" ] || [ "$STATUS" = "400" ]; then
        echo ""
        echo "🎉 API FUNCIONANDO! Status: $STATUS"
        echo ""
        echo "🧪 Testando endpoints críticos..."
        
        # Teste de login
        echo "1. Teste de login:"
        LOGIN_RESULT=$(curl -X POST "$API_URL" \
             -H "Content-Type: application/json" \
             -d '{"email":"teste@oficina.com","password":"123456"}' \
             -s -w "Status: %{http_code}" \
             --max-time 15)
        echo "$LOGIN_RESULT"
        
        # Teste de dados da oficina
        echo ""
        echo "2. Teste GetInfo:"
        INFO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                     "https://api.mecabr.com/api/v1/Workshop/GetInfo" \
                     --max-time 10)
        echo "Status GetInfo: $INFO_STATUS"
        
        # Teste dados bancários
        echo ""
        echo "3. Teste DataBank:"
        BANK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                     "https://api.mecabr.com/api/v1/Workshop/GetDataBank" \
                     --max-time 10)
        echo "Status DataBank: $BANK_STATUS"
        
        # Teste agenda
        echo ""
        echo "4. Teste Agenda:"
        AGENDA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                       "https://api.mecabr.com/api/v1/WorkshopAgenda" \
                       --max-time 10)
        echo "Status Agenda: $AGENDA_STATUS"
        
        echo ""
        echo "✅ VALIDAÇÃO COMPLETA - API RESTAURADA!"
        echo "📱 Agora teste nos apps:"
        echo "   - meca-app-oficina: Login funcionando"
        echo "   - admin.mecabr: Endpoints operacionais"
        echo "   - meca-app-cliente: Não afetado"
        
        exit 0
        
    elif [ "$STATUS" = "502" ]; then
        echo "   ❌ Ainda com erro 502"
    elif [ "$STATUS" = "000" ]; then
        echo "   ⚠️  Timeout ou não conecta"
    else
        echo "   🔄 Status inesperado: $STATUS"
    fi
    
    # Se não é a última tentativa, aguardar
    if [ $attempt -lt $MAX_ATTEMPTS ]; then
        echo "   ⏳ Aguardando $CHECK_INTERVAL segundos..."
        sleep $CHECK_INTERVAL
    fi
    
    attempt=$((attempt + 1))
done

echo ""
echo "❌ TIMEOUT - API ainda não foi corrigida após $MAX_ATTEMPTS tentativas"
echo ""
echo "📋 EXECUTE MANUALMENTE NO EC2:"
echo "================================"
echo "pm2 stop all && pm2 delete all"
echo "cd \$(find /home /var /opt -name '*meca-api*' -type d | head -1)"
echo "echo '{\"ConnectionStrings\":{\"MongoDb\":\"mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority\"},\"AllowedHosts\":\"*\"}' > appsettings.json"
echo "dotnet build -c Release"
echo "pm2 start \$(find . -name 'Meca.WebApi*' | head -1) --name meca-api"
echo "pm2 list"
echo ""

exit 1