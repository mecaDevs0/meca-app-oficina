enum ServiceHistoryType {
  orderPlaced('Pedido realizado'),
  scheduling('Agendamento'),
  budget('Orçamento'),
  payment('Pagamento'),
  service('Serviço'),
  approval('Aprovação'),
  completed('Concluído');

  const ServiceHistoryType(this.description);
  final String description;
}
