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
    BankData(code: '104', name: 'Caixa Econômica Federal', shortName: 'Caixa'),
    BankData(code: '341', name: 'Itaú Unibanco S.A.', shortName: 'Itaú'),
    BankData(code: '033', name: 'Banco Santander (Brasil) S.A.', shortName: 'Santander'),
    BankData(code: '237', name: 'Banco Bradesco S.A.', shortName: 'Bradesco'),
    BankData(code: '260', name: 'Nu Pagamentos S.A.', shortName: 'Nubank'),
    BankData(code: '422', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '070', name: 'BRB - Banco de Brasília S.A.', shortName: 'BRB'),
    BankData(code: '756', name: 'Sicoob', shortName: 'Sicoob'),
    BankData(code: '748', name: 'Sicredi', shortName: 'Sicredi'),
    BankData(code: '041', name: 'Banco do Estado do Rio Grande do Sul S.A.', shortName: 'Banrisul'),
    BankData(code: '077', name: 'Banco Inter S.A.', shortName: 'Inter'),
    BankData(code: '745', name: 'Banco Citibank S.A.', shortName: 'Citibank'),
    BankData(code: '399', name: 'HSBC Bank Brasil S.A.', shortName: 'HSBC'),
    BankData(code: '212', name: 'Banco Original S.A.', shortName: 'Original'),
    BankData(code: '623', name: 'Banco Pan S.A.', shortName: 'Banco Pan'),
    BankData(code: '633', name: 'Banco Rendimento S.A.', shortName: 'Rendimento'),
    BankData(code: '652', name: 'Itaú Unibanco Holding S.A.', shortName: 'Itaú Holding'),
    BankData(code: '655', name: 'Banco Votorantim S.A.', shortName: 'Votorantim'),
    BankData(code: '707', name: 'Banco Daycoval S.A.', shortName: 'Daycoval'),
    BankData(code: '712', name: 'Banco Ourinvest S.A.', shortName: 'Ourinvest'),
    BankData(code: '735', name: 'Banco Neon S.A.', shortName: 'Neon'),
    BankData(code: '739', name: 'Banco Cetelem S.A.', shortName: 'Cetelem'),
    BankData(code: '743', name: 'Banco Semear S.A.', shortName: 'Semear'),
    BankData(code: '746', name: 'Banco Modal S.A.', shortName: 'Modal'),
    BankData(code: '747', name: 'Banco Rabobank International Brasil S.A.', shortName: 'Rabobank'),
    BankData(code: '751', name: 'Scotiabank Brasil S.A.', shortName: 'Scotiabank'),
    BankData(code: '752', name: 'Banco Banco BNP Paribas Brasil S.A.', shortName: 'BNP Paribas'),
    BankData(code: '753', name: 'Novo Banco Continental S.A.', shortName: 'Continental'),
    BankData(code: '754', name: 'Banco Sistema S.A.', shortName: 'Sistema'),
    BankData(code: '755', name: 'Banco Merrill Lynch S.A.', shortName: 'Merrill Lynch'),
    BankData(code: '756', name: 'Banco Cooperativo do Brasil S.A.', shortName: 'Cooperativo'),
    BankData(code: '757', name: 'Banco KEB HANA do Brasil S.A.', shortName: 'KEB HANA'),
    BankData(code: '758', name: 'Banco J.P. Morgan S.A.', shortName: 'J.P. Morgan'),
    BankData(code: '759', name: 'Banco BNP Paribas Brasil S.A.', shortName: 'BNP Paribas'),
    BankData(code: '760', name: 'Banco Sumitomo Mitsui Brasileiro S.A.', shortName: 'Sumitomo'),
    BankData(code: '761', name: 'Banco Banrisul S.A.', shortName: 'Banrisul'),
    BankData(code: '762', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '763', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '764', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '765', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '766', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '767', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '768', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '769', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '770', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '771', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '772', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '773', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '774', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '775', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '776', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '777', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '778', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '779', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '780', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '781', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '782', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '783', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '784', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '785', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '786', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '787', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '788', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '789', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '790', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '791', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '792', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '793', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '794', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '795', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '796', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '797', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '798', name: 'Banco Safra S.A.', shortName: 'Safra'),
    BankData(code: '799', name: 'Banco Safra S.A.', shortName: 'Safra'),
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






















