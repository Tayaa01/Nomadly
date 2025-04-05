/// Méthodes de règlement disponibles pour les transactions entre membres
enum SettlementMethod {
  cash,       // Espèces
  bankTransfer, // Virement bancaire
  mobileMoney, // Paiement mobile (ex: Lydia, Paylib)
  check,      // Chèque
  creditCard, // Carte de crédit
  other,      // Autre méthode
}

/// Extension pour ajouter des fonctionnalités à l'énumération SettlementMethod
extension SettlementMethodExtension on SettlementMethod {
  String get displayName {
    switch (this) {
      case SettlementMethod.cash:
        return 'Espèces';
      case SettlementMethod.bankTransfer:
        return 'Virement bancaire';
      case SettlementMethod.mobileMoney:
        return 'Paiement mobile';
      case SettlementMethod.check:
        return 'Chèque';
      case SettlementMethod.creditCard:
        return 'Carte de crédit';
      case SettlementMethod.other:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case SettlementMethod.cash:
        return 'money';
      case SettlementMethod.bankTransfer:
        return 'account_balance';
      case SettlementMethod.mobileMoney:
        return 'smartphone';
      case SettlementMethod.check:
        return 'description';
      case SettlementMethod.creditCard:
        return 'credit_card';
      case SettlementMethod.other:
        return 'more_horiz';
    }
  }
}