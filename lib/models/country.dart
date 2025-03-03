
class Country {
  final String code;
  final String name;
  
  const Country(this.code, this.name);
  
  // Common countries list
  static const List<Country> common = [
    Country('US', 'United States'),
    Country('FR', 'France'),
    Country('GB', 'United Kingdom'),
    Country('DE', 'Germany'),
    Country('IT', 'Italy'),
    Country('ES', 'Spain'),
    Country('CA', 'Canada'),
    Country('JP', 'Japan'),
    Country('CN', 'China'),
    Country('AU', 'Australia'),
    Country('BR', 'Brazil'),
    Country('IN', 'India'),
    Country('TN', 'Tunisia'),
    Country('MA', 'Morocco'),
    Country('EG', 'Egypt'),
    Country('AE', 'United Arab Emirates'),
    Country('SA', 'Saudi Arabia'),
    Country('TR', 'Turkey'),
    Country('RU', 'Russia'),
    Country('KR', 'South Korea'),
  ];
  
  // Find a country by code
  static Country? findByCode(String code) {
    try {
      return common.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }
}