# Changelog - Meca Oficina

## [2.0.0] - 2025-01-19

### Novidades
- Integração PagBank: fluxo de vinculação de conta revisado e documentado na tela
- Tela PagBank deixa claro que há um único fluxo (autorizar no navegador); informar Account ID é opcional e não substitui a autorização
- Mensagens de sucesso ao vincular Account ID alinhadas à API (orientam a tocar em "Conectar PagBank" para concluir)
- Home e tela PagBank mostram corretamente "Conexão pendente" quando só o Account ID foi vinculado (sem OAuth)

### Melhorias
- UI/UX da configuração PagBank: texto "Opcional: já tem o Account ID?" e explicação "Não é um ou outro"
- Passo 1 do guia marcado como "(obrigatório)" e descrição reforçando que sem autorização não é possível receber pagamentos
- Changelog e versão alinhados para publicação nas lojas (App Store e Play Store)

### Correções
- Mensagem de sucesso ao vincular Account ID não afirma mais "Você já pode receber pagamentos" sem concluir OAuth
- Consistência entre status na Home e na tela PagBank (ambos usam o retorno da API)

---

## [1.8.0] - Anteriores
- Funcionalidades de oficina, agendamentos, PagBank e perfil.
