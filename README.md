# 🏢 MECA App Oficina

Aplicativo móvel Flutter para oficinas da plataforma MECA - marketplace de serviços automotivos.

## 🎯 Funcionalidades

- **Cadastro/Login:** CNPJ, email, senha
- **Onboarding:** Configuração inicial pós-aprovação
- **Dashboard:** Métricas e ações pendentes
- **Gestão de Agendamentos:** Aceitar, rejeitar, reagendar
- **Configuração de Horários:** Agenda de funcionamento
- **Gestão de Serviços:** Selecionar serviços oferecidos
- **Perfil:** Editar informações da oficina
- **Histórico Financeiro:** Receitas e comissões
- **Notificações:** Push notifications

## 🛠️ Tecnologias

- **Framework:** Flutter 3.24+
- **Linguagem:** Dart
- **Estado:** Provider
- **HTTP:** Dio
- **Storage:** SharedPreferences
- **Charts:** FL Chart
- **Auth:** Firebase Auth
- **Notifications:** Firebase Cloud Messaging

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.24+
- Dart SDK
- Android Studio / VS Code
- Emulador ou dispositivo físico

### Instalação
```bash
# Clone o repositório
git clone https://github.com/mecaDevs0/meca-app-oficina.git
cd meca-app-oficina

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Web
```bash
# Execute na web
flutter run -d web-server --web-port 8082
```

## 📱 Telas Principais

### Autenticação
- **Login:** Email/senha
- **Cadastro:** CNPJ, dados da oficina
- **Verificação:** Aguardando aprovação

### Onboarding (Pós-Aprovação)
- **Bem-vindo:** Confirmação de aprovação
- **Dados Bancários:** Configurar conta
- **Horários:** Definir agenda
- **Serviços:** Selecionar serviços oferecidos

### Dashboard
- **Métricas:** Agendamentos, receita, avaliações
- **Ações Pendentes:** Cards de tarefas
- **Agendamentos Hoje:** Lista do dia
- **Notificações:** Alertas importantes

### Agendamentos
- **Lista:** Todos os agendamentos
- **Filtros:** Status, data, cliente
- **Detalhes:** Informações completas
- **Ações:** Aceitar, rejeitar, reagendar

### Configurações
- **Horários:** Agenda semanal
- **Serviços:** Lista de serviços oferecidos
- **Perfil:** Dados da oficina
- **Fotos:** Galeria de imagens

### Financeiro
- **Receita Total:** Valor bruto
- **Comissão MECA:** Taxa cobrada
- **Receita Líquida:** Valor final
- **Histórico:** Transações detalhadas

## 🎨 Design

### Cores
- **Primária:** Azul (#252940)
- **Secundária:** Verde MECA (#00c977)
- **Fundo:** Branco (#FFFFFF)
- **Texto:** Cinza escuro (#334155)

### Componentes
- **Botões:** Bordas arredondadas (25px)
- **Cards:** Sombras suaves, bordas arredondadas
- **Inputs:** Bordas arredondadas (20px)
- **Ícones:** Lucide Icons

### Responsividade
- **Mobile First:** Otimizado para smartphones
- **Tablet:** Layout adaptativo
- **Web:** Interface web responsiva

## 🔧 Estrutura

```
lib/
├── main.dart                 # Entry point
├── screens/                  # Telas do app
│   ├── auth/                # Autenticação
│   ├── onboarding/          # Configuração inicial
│   ├── dashboard/           # Dashboard
│   ├── bookings/            # Agendamentos
│   ├── settings/            # Configurações
│   ├── financial/           # Financeiro
│   └── profile/             # Perfil
├── providers/               # Gerenciamento de estado
├── models/                  # Modelos de dados
├── services/                # Serviços (API)
├── utils/                   # Utilitários
└── widgets/                 # Widgets reutilizáveis
```

## 🌐 Integração API

### Endpoints Principais
```dart
// Autenticação
POST /auth/user/token
POST /store/workshops

// Oficina
GET /store/workshops/me
PUT /store/workshops/me

// Agendamentos
GET /store/bookings
POST /store/bookings/:id/confirm
POST /store/bookings/:id/reject

// Serviços
GET /store/my-services
POST /store/my-services
PUT /store/my-services/:id

// Financeiro
GET /store/financial-history
```

## 🔐 Autenticação

### Login Oficina
```dart
final authProvider = Provider.of<AuthProvider>(context);
await authProvider.login(email, password);
```

### Verificar Status
```dart
final status = await apiService.getWorkshopStatus();
if (status == 'pending') {
  // Mostrar tela de aguardo
} else if (status == 'approved') {
  // Mostrar onboarding
}
```

## 📊 Dashboard Analytics

### Métricas Principais
```dart
class DashboardMetrics {
  final int totalBookings;
  final double totalRevenue;
  final double mecaCommission;
  final double netRevenue;
  final double averageRating;
  final int totalReviews;
}
```

### Gráficos
- **Receita Mensal:** FL Line Chart
- **Agendamentos por Dia:** FL Bar Chart
- **Avaliações:** FL Pie Chart

## 🗓️ Gestão de Agendamentos

### Estados
- **Pendente:** Aguardando confirmação
- **Confirmado:** Aceito pela oficina
- **Rejeitado:** Recusado pela oficina
- **Finalizado:** Serviço concluído
- **Cancelado:** Cancelado pelo cliente

### Ações
```dart
// Aceitar agendamento
await apiService.confirmBooking(bookingId);

// Rejeitar agendamento
await apiService.rejectBooking(bookingId, reason);

// Reagendar
await apiService.rescheduleBooking(bookingId, newDateTime);
```

## ⏰ Configuração de Horários

### Agenda Semanal
```dart
class WeeklySchedule {
  final Map<DayOfWeek, DaySchedule> schedule;
}

class DaySchedule {
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final List<TimeSlot> breaks;
}
```

## 🔔 Notificações

### Tipos de Notificação
- **Novo Agendamento:** Cliente agendou serviço
- **Agendamento Cancelado:** Cliente cancelou
- **Pagamento Confirmado:** Pagamento aprovado
- **Avaliação Recebida:** Cliente avaliou
- **Lembrete:** Agendamento em breve

### FCM Setup
```dart
await FirebaseMessaging.instance.requestPermission();
final token = await FirebaseMessaging.instance.getToken();
await apiService.updateFCMToken(token);
```

## 🚀 Build

### Debug
```bash
flutter run --debug
```

### Release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📦 Deploy

### Google Play Store
```bash
flutter build appbundle --release
# Upload para Play Console
```

### Apple App Store
```bash
flutter build ios --release
# Upload via Xcode
```

### Web
```bash
flutter build web --release
# Deploy para servidor web
```

## 📝 Licença

© 2024 MECA - Todos os direitos reservados.

## 👥 Equipe

Desenvolvido pela equipe MECA Devs.