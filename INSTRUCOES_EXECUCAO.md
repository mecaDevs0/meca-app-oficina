# 🚀 EXECUTE AGORA NO EC2 - CORREÇÃO IMEDIATA

## 📍 STATUS ATUAL
✅ **Scripts de correção criados e prontos**  
❌ **API ainda retornando 502 Bad Gateway**  
🎯 **AÇÃO REQUERIDA**: Executar comandos no servidor EC2

---

## 🔥 CORREÇÃO IMEDIATA - COPIE E COLE NO EC2

### COMANDO COMPLETO (RECOMENDADO)
```bash
#!/bin/bash
echo "🚀 CORREÇÃO API MECABR INICIADA..." && \
MONGO="mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority" && \
echo "1. Parando PM2..." && pm2 stop all && pm2 delete all && \
echo "2. Localizando API..." && \
API_DIR=$(find /home /var /opt /root -name "*meca-api*" -type d 2>/dev/null | head -1) && \
echo "📁 API encontrada: $API_DIR" && cd "$API_DIR" && \
echo "3. Backup configuração..." && \
[ -f "appsettings.json" ] && cp appsettings.json appsettings.json.backup.$(date +%Y%m%d_%H%M%S) && \
echo "4. Atualizando MongoDB connection..." && \
cat > appsettings.json << EOF
{
  "ConnectionStrings": {
    "MongoDb": "$MONGO",
    "MongoDB": "$MONGO",
    "DefaultConnection": "$MONGO"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Cors": {
    "Origins": ["https://admin.mecabr.com", "http://localhost:3000"]
  }
}
EOF
echo "5. Compilando aplicação..." && \
[ -f "Meca.sln" ] && dotnet restore && dotnet build --configuration Release && \
echo "6. Localizando executável..." && \
EXE=$(find . -name "Meca.WebApi" -o -name "Meca.WebApi.exe" | head -1) && \
echo "📦 Executável: $EXE" && \
echo "7. Iniciando com PM2..." && \
pm2 start "$EXE" --name "meca-api" --env production && \
echo "8. Aguardando inicialização..." && sleep 15 && \
echo "9. Verificando status..." && pm2 list && \
echo "10. Testando API..." && \
curl -s -w "Status: %{http_code}\n" "https://api.mecabr.com/api/v1/Workshop/Token" && \
echo "✅ CORREÇÃO CONCLUÍDA!"
```

### COMANDO SUPER RÁPIDO (ALTERNATIVA)
```bash
pm2 stop all && pm2 delete all && cd $(find / -name "*meca-api*" -type d | head -1) && echo '{"ConnectionStrings":{"MongoDb":"mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority"},"AllowedHosts":"*"}' > appsettings.json && dotnet build -c Release && pm2 start $(find . -name "Meca.WebApi*" | head -1) --name meca-api && sleep 10 && pm2 list && curl -s -w "Status: %{http_code}" https://api.mecabr.com/api/v1/Workshop/Token
```

---

## 🔍 VERIFICAÇÃO PÓS-CORREÇÃO

### 1. Status do PM2
```bash
pm2 list
pm2 show meca-api
```

### 2. Logs da Aplicação
```bash
pm2 logs meca-api --lines 20
```

### 3. Teste da API
```bash
curl -X POST "https://api.mecabr.com/api/v1/Workshop/Token" \
     -H "Content-Type: application/json" \
     -d '{"email":"teste@oficina.com","password":"123456"}' \
     -w "Status: %{http_code}\n"
```

### 4. Resultado Esperado
- PM2 mostrando processo "meca-api" como **online**
- API retornando **200** ou **401** (não mais 502)
- Logs sem erros críticos

---

## 🚨 SE HOUVER PROBLEMAS

### Reiniciar Aplicação
```bash
pm2 restart meca-api
pm2 logs meca-api --lines 10
```

### Verificar Executável
```bash
find /home -name "*meca-api*" -type d
cd [DIRETORIO_ENCONTRADO]
ls -la bin/Release/*/Meca.WebApi*
```

### Compilar Novamente
```bash
dotnet clean
dotnet restore
dotnet build --configuration Release
```

---

## ✅ VALIDAÇÃO FINAL

Após executar os comandos, execute localmente:

```bash
python3 validacao_completa.py
```

**Resultado esperado:**
- ✅ API Status: OK
- ✅ Login Funcionando
- ✅ Dados da Oficina Carregados
- ✅ Endpoints Operacionais

---

## 📱 TESTE NOS APPS

1. **meca-app-oficina**: Fazer login e verificar dados
2. **admin.mecabr**: Confirmar funcionalidades
3. **meca-app-cliente**: Não deve ser afetado

---

**🎯 EXECUTE OS COMANDOS AGORA NO EC2**
**⏱️ Tempo estimado: 5-10 minutos**
**📞 API estará funcional após execução**