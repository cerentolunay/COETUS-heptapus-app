class CreditCalculator {
  const CreditCalculator._();

  static int calculateCreditCost({
    required int baseCredit,
    required int teacherLevel,
    int minCredit = 10,
    int maxCredit = 100,
  }) {
    final rawCredit = baseCredit * (teacherLevel / 3);
    return rawCredit.round().clamp(minCredit, maxCredit).toInt();
  }
}
