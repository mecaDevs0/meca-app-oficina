#!/usr/bin/env python3
"""
Teste completo dos endpoints da Oficina - API MECABR
"""

import requests
import json
import sys

BASE_URL = "https://api.mecabr.com/api/v1"

def test_endpoint(method, endpoint, data=None, headers=None, token=None):
    """Testa um endpoint específico"""
    url = f"{BASE_URL}{endpoint}"
    
    if headers is None:
        headers = {"Content-Type": "application/json"}
    
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    try:
        if method.upper() == "GET":
            response = requests.get(url, headers=headers, timeout=30)
        elif method.upper() == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=30)
        elif method.upper() == "PUT":
            response = requests.put(url, json=data, headers=headers, timeout=30)
        elif method.upper() == "PATCH":
            response = requests.patch(url, json=data, headers=headers, timeout=30)
        elif method.upper() == "DELETE":
            response = requests.delete(url, headers=headers, timeout=30)
        
        print(f"🧪 {method} {endpoint}")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            print(f"   ✅ OK")
            if response.text:
                try:
                    json_data = response.json()
                    print(f"   📄 Resposta: {json.dumps(json_data, indent=2)[:200]}...")
                except:
                    print(f"   📄 Resposta (text): {response.text[:100]}...")
        elif response.status_code in [401, 403]:
            print(f"   🔐 Não autorizado")
        elif response.status_code == 404:
            print(f"   ❓ Não encontrado")
        elif response.status_code >= 500:
            print(f"   💥 Erro servidor: {response.text[:100]}")
        else:
            print(f"   ⚠️ Status inesperado: {response.text[:100]}")
        
        print()
        return response
    
    except requests.exceptions.Timeout:
        print(f"   ⏰ Timeout")
        print()
        return None
    except requests.exceptions.ConnectionError:
        print(f"   🔌 Erro de conexão")
        print()
        return None
    except Exception as e:
        print(f"   ❌ Erro: {str(e)}")
        print()
        return None

def main():
    print("🚀 TESTE DOS ENDPOINTS DA OFICINA - API MECABR")
    print("=" * 50)
    print()
    
    # 1. Teste de Login
    print("1. 🔐 TESTANDO LOGIN DA OFICINA")
    print("-" * 30)
    
    login_data = {
        "email": "teste@oficina.com",
        "password": "123456"
    }
    
    login_response = test_endpoint("POST", "/Workshop/Token", login_data)
    
    token = None
    if login_response and login_response.status_code == 200:
        try:
            login_result = login_response.json()
            token = login_result.get("token")
            if token:
                print(f"🎫 Token obtido: {token[:20]}...")
        except:
            pass
    
    # 2. Testes de Dados da Oficina (precisam de token)
    print("2. 📊 TESTANDO DADOS DA OFICINA")
    print("-" * 30)
    
    # Perfil da oficina
    test_endpoint("GET", "/Workshop/GetInfo", token=token)
    
    # Dados bancários
    test_endpoint("GET", "/Workshop/GetDataBank", token=token)
    
    # 3. Testes de Agenda
    print("3. 📅 TESTANDO AGENDA")
    print("-" * 30)
    
    test_endpoint("GET", "/WorkshopAgenda", token=token)
    
    # 4. Outros endpoints importantes
    print("4. 🛠️ TESTANDO OUTROS ENDPOINTS")
    print("-" * 30)
    
    test_endpoint("GET", "/WorkshopServices", token=token)
    test_endpoint("GET", "/Scheduling", token=token)
    test_endpoint("GET", "/FinancialHistory", token=token)
    
    # 5. Testes com dados reais (se tivermos token)
    if token:
        print("5. ✏️ TESTANDO EDIÇÃO (SIMULAÇÃO)")
        print("-" * 30)
        
        # Simular atualização de dados bancários
        bank_data = {
            "bankCode": "001",
            "agency": "1234",
            "account": "12345-6",
            "accountType": "CORRENTE",
            "holderName": "OFICINA TESTE"
        }
        
        test_endpoint("POST", "/Workshop/UpdateDataBank", bank_data, token=token)
    
    print("=" * 50)
    print("✅ TESTE COMPLETO!")
    print("Verifique os resultados acima para identificar problemas específicos.")

if __name__ == "__main__":
    main()