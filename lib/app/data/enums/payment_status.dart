enum PaymentStatus {
  pending('Pendente'),
  paid('Pago'),
  refused('Recusado'),
  overdue('Vencido'),
  canceled('Cancelado'),
  released('Liberado'),
  reversed('Estornado');

  const PaymentStatus(this.name);
  final String name;
}
