#!/bin/bash

echo "🔍 DIAGNÓSTICO DA API MECABR"
echo "=============================="

echo ""
echo "1. Verificando status do PM2..."
pm2 list

echo ""
echo "2. Verificando logs da API..."
pm2 logs --lines 20 

echo ""
echo "3. Verificando processos em execução..."
ps aux | grep -E "(node|dotnet|mono)" | head -10

echo ""
echo "4. Verificando conexão MongoDB..."
if command -v mongosh &> /dev/null; then
    echo "Testing MongoDB connection..."
    mongosh "mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/" --eval "db.adminCommand('ping')" || echo "Falha na conexão MongoDB"
else
    echo "mongosh não está instalado"
fi

echo ""
echo "5. Verificando portas em uso..."
netstat -tulpn | grep -E "(80|443|3000|5000|8000|8080)" | head -10

echo ""
echo "6. Verificando uso de recursos..."
df -h | head -5
free -h

echo ""
echo "7. Verificando nginx..."
sudo systemctl status nginx

echo ""
echo "=============================="
echo "✅ Diagnóstico completo!"