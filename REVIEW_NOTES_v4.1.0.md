# Notas para Revisores — MECA Oficina v4.1.0

## Sobre o app
App para oficinas mecanicas gerenciarem agendamentos, servicos e recebimentos.
Oficinas recebem solicitacoes de clientes, fazem check-in do veiculo,
acompanham o servico e recebem pagamentos.

## Como testar as principais mudancas desta versao

1. Criar uma conta de oficina (ou usar login existente)
2. Fechar completamente o app (kill no task manager)
3. Reabrir — se a sessao tiver expirado (>7 dias), deve ir direto ao login
4. Com sessao valida, app deve carregar a home normalmente sem "tela fantasma"
5. Verificar notificacoes push — visual atualizado com alerta estilizado

## Permissoes utilizadas
- Camera: fotos de check-in do veiculo
- Galeria/Fotos: upload de fotos
- Notificacoes push: alertas de novos agendamentos (via OneSignal)
- Calendario: adicionar agendamento ao calendario (iOS)
- Internet: comunicacao com API
- Localizacao: cadastro de endereco da oficina

## Informacoes adicionais
- Nao ha compras in-app. Oficinas recebem pagamentos via gateway externo
- Conteudo gerado por usuarios: fotos de check-in e dados de servico
- Idade minima: 4+ (iOS) / Livre (Android)
- Backend: https://api.mecabr.com
- Conta de teste disponivel sob demanda
