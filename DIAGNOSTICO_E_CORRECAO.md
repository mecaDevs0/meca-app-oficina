# 🚨 DIAGNÓSTICO E CORREÇÃO - ECOSSISTEMA MECABR

## 📊 PROBLEMA IDENTIFICADO

**Status Atual**: API `https://api.mecabr.com` retornando **502 Bad Gateway**

- ✅ Nginx funcionando
- ❌ Aplicação API (PM2) com problemas
- ❌ Login da oficina falhando
- ❌ Endpoints de dados da oficina inacessíveis

## 🎯 ENDPOINTS CRÍTICOS AFETADOS

### Oficina (Workshop)
- `POST /api/v1/Workshop/Token` - Login
- `GET /api/v1/Workshop/GetInfo` - Dados do perfil
- `GET /api/v1/Workshop/GetDataBank` - Dados bancários
- `POST /api/v1/Workshop/UpdateDataBank` - Atualizar dados bancários
- `PATCH /api/v1/Workshop/{id}` - Atualizar oficina

### Agenda
- `GET /api/v1/WorkshopAgenda` - Agenda da oficina
- `POST /api/v1/WorkshopAgenda` - Criar agenda
- `PUT /api/v1/WorkshopAgenda` - Atualizar agenda

## 🔧 CORREÇÕES NECESSÁRIAS

### 1. **Reativar API no EC2**
```bash
# Executar no EC2:
./fix_api_quick.sh
```

### 2. **Connection String MongoDB**
**Correta**: `mongodb+srv://pedrosantana:qsmEphWv3dQ2wSGk@cluster0.ccsupmg.mongodb.net/meca-app-2025?retryWrites=true&w=majority`

### 3. **Verificar Configurações**
- `appsettings.json`
- `appsettings.Production.json`
- `ecosystem.config.js`

## 📱 APPS AFETADOS

### meca-app-oficina ✅
- **URL Base**: `https://api.mecabr.com/`
- **Endpoints mapeados**: ✅ Corretos
- **Modelo de dados**: ✅ Completo

### meca-app-cliente ⚠️
- **Status**: Não deve ser alterado (regra do usuário)
- **Impacto**: Indireta - depende da API funcionar

### admin.mecabr ⚠️
- **Status**: Deve permanecer funcionando
- **Impacto**: Direta - consome mesmos endpoints

## 🚀 SEQUÊNCIA DE EXECUÇÃO

### Etapa 1: Diagnóstico Completo
```bash
ssh -i "your-key.pem" ubuntu@ec2-instance "bash -s" < diagnose_api.sh
```

### Etapa 2: Correção Rápida
```bash
ssh -i "your-key.pem" ubuntu@ec2-instance "bash -s" < fix_api_quick.sh
```

### Etapa 3: Teste dos Endpoints
```bash
python3 test_oficina_endpoints.py
```

### Etapa 4: Validação por App
1. **meca-app-oficina**: Testar login e perfil
2. **admin.mecabr**: Verificar funcionalidades
3. **meca-app-cliente**: Confirmar não afetado

## 📋 CHECKLIST DE VALIDAÇÃO

### API Funcionando ✅
- [ ] Status 200 em `/Workshop/Token`
- [ ] PM2 com processo ativo
- [ ] Logs sem erros críticos

### Login da Oficina ✅
- [ ] Token válido retornado
- [ ] Dados da oficina carregados
- [ ] Sessão mantida

### Dados da Oficina ✅
- [ ] Perfil (`GetInfo`) funcionando
- [ ] Dados bancários (`GetDataBank`) funcionando
- [ ] Edição persistindo no MongoDB

### Agenda da Oficina ✅
- [ ] Listagem funcionando
- [ ] Criação/edição funcionando
- [ ] Dados reais do MongoDB

### Testes nas 3 Frentes ✅
- [ ] meca-app-oficina: Login + dados + edição
- [ ] admin.mecabr: Funcionalidades básicas
- [ ] meca-app-cliente: Não afetado

## ⚠️ REGRAS CRÍTICAS

1. **NÃO TOCAR**: MongoDB, meca-site, meca-app-cliente
2. **NÃO PARAR**: PM2 do site
3. **USAR APENAS**: Dados reais do MongoDB
4. **MANTER**: admin.mecabr funcionando

## 📞 NEXT STEPS

1. **Execute fix_api_quick.sh no EC2**
2. **Teste com test_oficina_endpoints.py**
3. **Valide cada app individualmente**
4. **Confirme dados reais sendo salvos no MongoDB**

---
*Diagnóstico realizado em: 25/09/2025*
*Status: Pronto para execução*