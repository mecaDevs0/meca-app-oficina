class BankData {
  final String code;
  final String name;
  final String shortName;

  const BankData({
    required this.code,
    required this.name,
    required this.shortName,
  });
}

class BanksData {
  static const List<BankData> banks = [
    BankData(code: '001', name: 'Banco do Brasil S.A.', shortName: 'Banco do Brasil'),
    BankData(code: '033', name: 'Banco Santander (Brasil) S.A.', shortName: 'Santander'),
    BankData(code: '041', name: 'Banco do Estado do Rio Grande do Sul S.A.', shortName: 'Banrisul'),
    BankData(code: '070', name: 'BRB - Banco de Brasília S.A.', shortName: 'BRB'),
    BankData(code: '077', name: 'Banco Inter S.A.', shortName: 'Inter'),
    BankData(code: '104', name: 'Caixa Econômica Federal', shortName: 'Caixa'),
    BankData(code: '208', name: 'Banco BTG Pactual S.A.', shortName: 'BTG Pactual'),
    BankData(code: '212', name: 'Banco Original S.A.', shortName: 'Original'),
    BankData(code: '237', name: 'Banco Bradesco S.A.', shortName: 'Bradesco'),
    BankData(code: '260', name: 'Nu Pagamentos S.A.', shortName: 'Nubank'),
    BankData(code: '290', name: 'PagSeguro Internet S.A.', shortName: 'PagBank'),
    BankData(code: '323', name: 'Mercado Pago', shortName: 'Mercado Pago'),
    BankData(code: '336', name: 'Banco C6 S.A.', shortName: 'C6 Bank'),
    BankData(code: '341', name: 'Itaú Unibanco S.A.', shortName: 'Itaú'),
    BankData(code: '399', name: 'HSBC Bank Brasil S.A.', shortName: 'HSBC'),
    BankData(code: '403', name: 'Cora SCD S.A.', shortName: 'Cora'),
    BankData(code: '422', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '623', name: 'Banco Pan S.A.', shortName: 'Banco Pan'),
    BankData(code: '633', name: 'Banco Rendimento S.A.', shortName: 'Rendimento'),
    BankData(code: '655', name: 'Banco Votorantim S.A.', shortName: 'Votorantim'),
    BankData(code: '707', name: 'Banco Daycoval S.A.', shortName: 'Daycoval'),
    BankData(code: '735', name: 'Banco Neon S.A.', shortName: 'Neon'),
    BankData(code: '745', name: 'Banco Citibank S.A.', shortName: 'Citibank'),
    BankData(code: '746', name: 'Banco Modal S.A.', shortName: 'Modal'),
    BankData(code: '748', name: 'Sicredi', shortName: 'Sicredi'),
    BankData(code: '756', name: 'Sicoob', shortName: 'Sicoob'),
  ];

  static BankData? getBankByCode(String code) {
    try {
      return banks.firstWhere((bank) => bank.code == code);
    } catch (e) {
      return null;
    }
  }

  static List<BankData> searchBanks(String query) {
    if (query.isEmpty) return banks;

    final lowercaseQuery = query.toLowerCase();
    return banks.where((bank) {
      return bank.name.toLowerCase().contains(lowercaseQuery) ||
             bank.shortName.toLowerCase().contains(lowercaseQuery) ||
             bank.code.contains(query);
    }).toList();
  }
}
