String numberToWords(double amount) {
  if (amount == 0) return "Zero";

  final int number = amount.floor();
  final int paise = ((amount - number) * 100).round();

  String words = _convert(number);
  
  if (paise > 0) {
    words += " and ${_convert(paise)} Paise";
  }

  return words;
}

String _convert(int n) {
  if (n < 0) return "Minus ${_convert(-n)}";
  if (n == 0) return "";

  if (n <= 19) return _units[n];
  if (n <= 99) return _tens[n ~/ 10] + (n % 10 != 0 ? " ${_units[n % 10]}" : "");
  if (n <= 999) return "${_units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${_convert(n % 100)}" : ""}";
  if (n <= 99999) return "${_convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convert(n % 1000)}" : ""}";
  if (n <= 9999999) return "${_convert(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_convert(n % 100000)}" : ""}";
  
  return "${_convert(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${_convert(n % 10000000)}" : ""}";
}

String getCurrentFinancialYear() {
  final now = DateTime.now();
  final int startYear = now.month >= 4 ? now.year : now.year - 1;
  final int endYear = startYear + 1;
  return 'FY $startYear-${endYear.toString().substring(2)}';
}

const _units = [
  "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
  "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
];

const _tens = [
  "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
];
