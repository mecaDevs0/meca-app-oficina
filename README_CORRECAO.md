# 🔧 CORREÇÃO COMPLETA - ECOSSISTEMA MECABR

## 📋 RESUMO EXECUTIVO

**PROBLEMA IDENTIFICADO**: API `https://api.mecabr.com` com erro 502 Bad Gateway

**CAUSA**: Serviços PM2 da API inativos ou com problemas de configuração

**SOLUÇÃO**: Scripts de correção automática criados e prontos para execução

---

## 📁 ARQUIVOS CRIADOS

### 🔍 Diagnóstico
- `diagnose_api.sh` - Diagnóstico completo do servidor
- `DIAGNOSTICO_E_CORRECAO.md` - Análise detalhada do problema

### 🛠️ Correção 
- `fix_api_quick.sh` - Correção rápida (PRINCIPAL)
- `fix_api_mecabr.sh` - Correção completa 
- `COMANDOS_EC2.sh` - Comandos manuais para EC2

### 🧪 Teste
- `test_oficina_endpoints.py` - Teste específico dos endpoints da oficina
- `validacao_completa.py` - Validação completa do ecossistema

---

## 🚀 EXECUÇÃO IMEDIATA

### ⚡ CORREÇÃO RÁPIDA (RECOMENDADA)

Execute este comando no EC2:

```bash
ssh -i "sua-chave.pem" ubuntu@seu-ec2 'bash -s' < fix_api_quick.sh
```

**OU execute diretamente no servidor:**

```bash
# Baixar o script
curl -O https://raw.githubusercontent.com/seu-repo/fix_api_quick.sh

# Executar
chmod +x fix_api_quick.sh
./fix_api_quick.sh
```

### 📊 VALIDAÇÃO

Após a correção, teste localmente:

```bash
python3 validacao_completa.py
```

---

## 🎯 ENDPOINTS CRÍTICOS

### Login da Oficina
```bash
POST https://api.mecabr.com/api/v1/Workshop/Token
{
  "email": "oficina@email.com",
  "password": "senha123"
}
```

### Dados da Oficina
```bash
GET https://api.mecabr.com/api/v1/Workshop/GetInfo
Authorization: Bearer {token}
```

### Dados Bancários
```bash
GET https://api.mecabr.com/api/v1/Workshop/GetDataBank
Authorization: Bearer {token}

POST https://api.mecabr.com/api/v1/Workshop/UpdateDataBank
Authorization: Bearer {token}
```

### Agenda
```bash
GET https://api.mecabr.com/api/v1/WorkshopAgenda
Authorization: Bearer {token}
```

---

## 🔑 CONFIGURAÇÕES CRÍTICAS

### Connection String MongoDB
```
mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority
```

### Arquivos de Configuração
- `appsettings.json`
- `appsettings.Production.json`
- `ecosystem.config.js`

---

## ✅ CHECKLIST DE VALIDAÇÃO

### Pré-Correção
- [ ] API retorna 502 Bad Gateway
- [ ] PM2 com processos inativos
- [ ] Apps não conseguem fazer login

### Pós-Correção
- [ ] API responde 200/401 (não mais 502)
- [ ] PM2 com processo "meca-api" ativo
- [ ] Login da oficina funcional
- [ ] Dados da oficina carregados
- [ ] Edição de dados persistindo no MongoDB

### Teste nos Apps
- [ ] **meca-app-oficina**: Login + perfil + edição
- [ ] **admin.mecabr**: Funcionalidades básicas
- [ ] **meca-app-cliente**: Não afetado ✅

---

## 🚨 REGRAS CRÍTICAS

⚠️ **NÃO TOCAR**:
- MongoDB (dados existentes)
- meca-site 
- meca-app-cliente
- Processos PM2 do site

✅ **PODE ALTERAR**:
- API (meca-api-main)
- Arquivos de configuração da API
- Processos PM2 da API

---

## 📞 SEQUÊNCIA RECOMENDADA

1. **Execute** `fix_api_quick.sh` no EC2
2. **Aguarde** 30 segundos para inicialização
3. **Execute** `python3 validacao_completa.py` localmente
4. **Teste** login no meca-app-oficina
5. **Confirme** que admin.mecabr continua funcionando
6. **Valide** que meca-app-cliente não foi afetado

---

## 📊 MONITORAMENTO

### Logs da API
```bash
pm2 logs meca-api --lines 50
```

### Status dos Processos
```bash
pm2 list
pm2 show meca-api
```

### Teste Rápido da API
```bash
curl -s -w "Status: %{http_code}\n" https://api.mecabr.com/api/v1/Workshop/Token
```

---

## 🆘 EM CASO DE PROBLEMAS

1. **Verificar logs**: `pm2 logs`
2. **Reiniciar API**: `pm2 restart meca-api`
3. **Status completo**: `pm2 show meca-api`
4. **Teste manual**: Execute `test_oficina_endpoints.py`

---

**Status**: ✅ Scripts prontos para execução
**Próximo passo**: Executar `fix_api_quick.sh` no EC2
**Tempo estimado**: 5-10 minutos para correção completa