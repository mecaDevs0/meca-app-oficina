enum RequirementsStripe {
  bankAccount('Conta Bancária', 0),
  email('E-mail', 1),
  phone('Telefone', 2),
  birthDate('Data de Nascimento', 3),
  cpf('CPF', 4),
  cnpj('CNPJ', 5),
  ssnLast4Digits('Últimos 4 dígitos do SSN', 7), //template
  additionalDocument('Documento Adicional', 8), //template
  //meiCard
  businessRegistrationDocument('Documento de Registro Empresarial', 9),
  //meiCard
  businessVerificationDocument('Documento de Verificação Empresarial', 10),
  //fileDocument
  photoDocument('Documento com Foto', 11),
  //form_address
  fullAddress('Endereço completo', 12),
  //phone(ali encima)
  supportPhone('Telefone de suporte', 15),
  //template
  websiteUrl('Url do site', 16),
  //nao mapeado
  pending('Pendência não mapeada', 999);

  const RequirementsStripe(this.name, this.code);
  final String name;
  final int code;
}
