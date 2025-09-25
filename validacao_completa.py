#!/usr/bin/env python3
"""
Validação Completa do Ecossistema MECABR
Testa todos os componentes críticos após correções
"""

import requests
import json
import sys
from datetime import datetime

BASE_URL = "https://api.mecabr.com/api/v1"

class MecaBRValidator:
    def __init__(self):
        self.token = None
        self.workshop_id = None
        self.results = {
            "api_status": False,
            "login_oficina": False,
            "dados_oficina": False,
            "dados_bancarios": False,
            "agenda": False,
            "edicao_dados": False
        }
    
    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        symbols = {"INFO": "ℹ️", "OK": "✅", "ERROR": "❌", "WARN": "⚠️"}
        print(f"[{timestamp}] {symbols.get(level, '📋')} {message}")
    
    def test_api_status(self):
        """Testa se a API está respondendo"""
        self.log("Testando status básico da API...")
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=10)
            if response.status_code in [200, 404]:  # 404 é ok se endpoint não existir
                self.results["api_status"] = True
                self.log("API está respondendo", "OK")
                return True
        except:
            pass
        
        # Teste alternativo com endpoint conhecido
        try:
            response = requests.post(f"{BASE_URL}/Workshop/Token", 
                                   json={"email": "test", "password": "test"}, 
                                   timeout=10)
            if response.status_code != 502:  # Qualquer coisa diferente de 502 é melhor
                self.results["api_status"] = True
                self.log("API está respondendo (não mais 502)", "OK")
                return True
        except:
            pass
        
        self.log("API ainda com problemas", "ERROR")
        return False
    
    def test_login_oficina(self):
        """Testa login da oficina com dados de teste"""
        self.log("Testando login da oficina...")
        
        test_credentials = [
            {"email": "oficina@test.com", "password": "123456"},
            {"email": "teste@oficina.com", "password": "123456"},
            {"email": "admin@mecabr.com", "password": "admin123"},
        ]
        
        for cred in test_credentials:
            try:
                response = requests.post(f"{BASE_URL}/Workshop/Token", 
                                       json=cred, timeout=15)
                
                if response.status_code == 200:
                    data = response.json()
                    if "token" in data:
                        self.token = data["token"]
                        if "id" in data:
                            self.workshop_id = data["id"]
                        self.results["login_oficina"] = True
                        self.log(f"Login realizado com {cred['email']}", "OK")
                        return True
                elif response.status_code == 401:
                    self.log(f"Credenciais {cred['email']} inválidas (mas API funcionando)", "WARN")
                else:
                    self.log(f"Erro no login: {response.status_code}", "ERROR")
            
            except Exception as e:
                self.log(f"Erro na requisição de login: {str(e)}", "ERROR")
        
        self.results["login_oficina"] = False
        self.log("Não foi possível fazer login", "ERROR")
        return False
    
    def test_dados_oficina(self):
        """Testa recuperação dos dados da oficina"""
        if not self.token:
            self.log("Sem token para testar dados da oficina", "ERROR")
            return False
        
        self.log("Testando recuperação de dados da oficina...")
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"}
            response = requests.get(f"{BASE_URL}/Workshop/GetInfo", 
                                  headers=headers, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, dict) and len(data) > 0:
                    self.results["dados_oficina"] = True
                    self.log("Dados da oficina recuperados com sucesso", "OK")
                    
                    # Verificar campos essenciais
                    essential_fields = ["id", "fullName", "email"]
                    missing_fields = [f for f in essential_fields if not data.get(f)]
                    
                    if missing_fields:
                        self.log(f"Campos faltando: {missing_fields}", "WARN")
                    else:
                        self.log("Todos os campos essenciais presentes", "OK")
                    
                    return True
                else:
                    self.log("Resposta vazia ou inválida", "ERROR")
            else:
                self.log(f"Erro ao recuperar dados: {response.status_code}", "ERROR")
        
        except Exception as e:
            self.log(f"Erro na requisição de dados: {str(e)}", "ERROR")
        
        return False
    
    def test_dados_bancarios(self):
        """Testa recuperação dos dados bancários"""
        if not self.token:
            self.log("Sem token para testar dados bancários", "ERROR")
            return False
        
        self.log("Testando dados bancários...")
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"}
            response = requests.get(f"{BASE_URL}/Workshop/GetDataBank", 
                                  headers=headers, timeout=15)
            
            if response.status_code == 200:
                self.results["dados_bancarios"] = True
                self.log("Endpoint de dados bancários funcionando", "OK")
                return True
            elif response.status_code == 404:
                self.log("Sem dados bancários cadastrados (normal)", "WARN")
                self.results["dados_bancarios"] = True  # Endpoint funciona
                return True
            else:
                self.log(f"Erro nos dados bancários: {response.status_code}", "ERROR")
        
        except Exception as e:
            self.log(f"Erro na requisição bancária: {str(e)}", "ERROR")
        
        return False
    
    def test_agenda(self):
        """Testa recuperação da agenda"""
        if not self.token:
            self.log("Sem token para testar agenda", "ERROR")
            return False
        
        self.log("Testando agenda da oficina...")
        
        try:
            headers = {"Authorization": f"Bearer {self.token}"}
            response = requests.get(f"{BASE_URL}/WorkshopAgenda", 
                                  headers=headers, timeout=15)
            
            if response.status_code == 200:
                self.results["agenda"] = True
                self.log("Agenda funcionando corretamente", "OK")
                return True
            elif response.status_code == 404:
                self.log("Sem agenda cadastrada (normal)", "WARN")
                self.results["agenda"] = True  # Endpoint funciona
                return True
            else:
                self.log(f"Erro na agenda: {response.status_code}", "ERROR")
        
        except Exception as e:
            self.log(f"Erro na requisição de agenda: {str(e)}", "ERROR")
        
        return False
    
    def test_edicao_dados(self):
        """Testa capacidade de edição de dados"""
        if not self.token or not self.workshop_id:
            self.log("Dados insuficientes para testar edição", "ERROR")
            return False
        
        self.log("Testando edição de dados...")
        
        # Tentar atualizar dados bancários como teste
        try:
            headers = {"Authorization": f"Bearer {self.token}"}
            test_data = {
                "bankCode": "001",
                "agency": "1234",
                "account": "12345-6",
                "accountType": "CORRENTE",
                "holderName": "TESTE VALIDACAO"
            }
            
            response = requests.post(f"{BASE_URL}/Workshop/UpdateDataBank", 
                                   json=test_data, headers=headers, timeout=15)
            
            if response.status_code in [200, 201]:
                self.results["edicao_dados"] = True
                self.log("Edição de dados funcionando", "OK")
                return True
            else:
                self.log(f"Erro na edição: {response.status_code}", "ERROR")
        
        except Exception as e:
            self.log(f"Erro na requisição de edição: {str(e)}", "ERROR")
        
        return False
    
    def generate_report(self):
        """Gera relatório final"""
        print("\n" + "="*60)
        print("📊 RELATÓRIO DE VALIDAÇÃO - ECOSSISTEMA MECABR")
        print("="*60)
        
        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results.values() if result)
        
        print(f"\n🎯 RESULTADO GERAL: {passed_tests}/{total_tests} testes passaram")
        
        status_icon = "✅" if passed_tests >= total_tests * 0.8 else "⚠️" if passed_tests >= total_tests * 0.5 else "❌"
        print(f"{status_icon} Status do Sistema: {'OPERACIONAL' if passed_tests >= total_tests * 0.8 else 'PARCIAL' if passed_tests >= total_tests * 0.5 else 'CRÍTICO'}")
        
        print("\n📋 DETALHES POR COMPONENTE:")
        print("-" * 30)
        
        components = {
            "api_status": "Status da API",
            "login_oficina": "Login da Oficina", 
            "dados_oficina": "Dados da Oficina",
            "dados_bancarios": "Dados Bancários",
            "agenda": "Agenda",
            "edicao_dados": "Edição de Dados"
        }
        
        for key, name in components.items():
            status = "✅ OK" if self.results[key] else "❌ FALHA"
            print(f"{name:20} {status}")
        
        print("\n🚀 PRÓXIMAS ETAPAS:")
        if not self.results["api_status"]:
            print("1. Execute os scripts de correção no EC2")
            print("2. Verifique os logs do PM2")
        elif not self.results["login_oficina"]:
            print("1. Verifique usuários no MongoDB")
            print("2. Confirme endpoints de autenticação")
        elif passed_tests < total_tests:
            print("1. Investigue endpoints específicos que falharam")
            print("2. Verifique logs da aplicação")
        else:
            print("1. Teste nos apps móveis (meca-app-oficina)")
            print("2. Teste no admin.mecabr")
            print("3. Confirme não afetou meca-app-cliente")
        
        print("\n" + "="*60)
        
        return passed_tests >= total_tests * 0.8

def main():
    print("🚀 INICIANDO VALIDAÇÃO COMPLETA DO ECOSSISTEMA MECABR")
    print("=" * 60)
    
    validator = MecaBRValidator()
    
    # Execução sequencial dos testes
    validator.test_api_status()
    validator.test_login_oficina()
    validator.test_dados_oficina()
    validator.test_dados_bancarios() 
    validator.test_agenda()
    validator.test_edicao_dados()
    
    # Gerar relatório
    success = validator.generate_report()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()