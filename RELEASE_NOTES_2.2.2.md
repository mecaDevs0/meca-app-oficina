# MECA Oficinas — v2.2.2 (Build 222)

---

## Notes for Reviewers (English)

This update introduces a new pre-purchase inspection service workflow, improves the password recovery screen, and includes general stability improvements.

**Pre-Purchase Service (Pré-Compra):**
Workshops can now receive and manage "Pre-Purchase Inspection" requests — a service where a customer requests a detailed vehicle inspection before purchasing a used car. The workflow includes: receiving the request, confirming, starting the inspection, submitting a detailed inspection report (10 categories: engine, transmission, suspension, brakes, bodywork, interior, electrical, tires, A/C, general maintenance), and uploading a PDF report for the customer to download after payment confirmation.

Pre-purchase requests now appear in the main "Schedule" (Agenda) screen alongside regular bookings, with a clear "Pre-Purchase" badge for differentiation.

**Password Recovery:**
The "Forgot Password" screen was redesigned for clarity. The success screen now displays step-by-step instructions (3 numbered steps) explaining exactly how to use the temporary code to log in. Text colors now properly adapt to both dark and light mode themes.

No third-party SDKs were added or changed. No new permissions are required.

---

## What's New — v2.2.2

### English

**New Features**
- Pre-purchase inspection requests now appear in the Schedule screen alongside regular service bookings
- Pre-purchase items display a "Pre-Purchase" badge for easy identification
- Tapping a pre-purchase request opens the full management screen (confirm → start → submit inspection report → upload PDF)

**Bug Fixes**
- Fixed: "Forgot Password" success screen showed confusing text about "temporary code" with no clear instructions
- Fixed: "Forgot Password" text colors were hardcoded and invisible in dark mode

**Improvements**
- Password recovery success screen now shows 3 clear numbered steps for accessing the account
- Schedule screen loads pre-purchase and regular bookings in parallel for faster display
- Dark/light mode support improved on the password recovery screen

---

### Português (Brasil)

**Novas Funcionalidades**
- Solicitações de pré-compra agora aparecem na tela de Agenda junto com os agendamentos de serviços regulares
- Itens de pré-compra exibem um badge "Pré-Compra" para fácil identificação
- Ao tocar em uma pré-compra, abre a tela completa de gerenciamento (confirmar → iniciar → enviar laudo → upload PDF)

**Correções de Bugs**
- Corrigido: Tela de sucesso de "Recuperar Senha" exibia texto confuso sobre "código temporário" sem instruções claras
- Corrigido: Cores de texto na tela de "Recuperar Senha" eram fixas e ficavam invisíveis no modo escuro

**Melhorias**
- Tela de sucesso de recuperação de senha agora exibe 3 passos numerados e claros para acessar a conta
- Tela de agenda carrega pré-compras e agendamentos regulares em paralelo para exibição mais rápida
- Suporte a modo escuro/claro melhorado na tela de recuperação de senha
