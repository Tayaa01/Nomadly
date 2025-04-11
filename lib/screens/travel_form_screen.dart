import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/travel_request.dart';
import 'budget_free_travel_form.dart';
import '../services/weather_service.dart';

class TravelFormScreen extends StatefulWidget {
  const TravelFormScreen({Key? key}) : super(key: key);

  @override
  _TravelFormScreenState createState() => _TravelFormScreenState();
}

class _TravelFormScreenState extends State<TravelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _daysController = TextEditingController();
  final DateTime _sessionDateTime = DateTime.utc(2025, 03, 09, 02, 34, 10);
  final String _username = 'haddari';
  DateTime? _selectedDate;
  int _selectedDayIndex = -1;
  bool _showImportantNotes = false;
  bool _isLoadingWeather = false;
  Map<int, String> _dailyWeatherAdvice = {}; // Store weather advice for each day

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final chatProvider = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.green.shade900, Colors.black]
                  : [Colors.green.shade600, Colors.green.shade100],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.planeDeparture,
              color: Colors.white,
              size: 28,
            ).animate().fadeIn(duration: 500.ms).slideX(),
            const SizedBox(width: 12),
            Text(
              'Travel Assistant',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () => chatProvider.clearHistory(),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.black, Colors.black87]
                : [Colors.white, Colors.green.shade50],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Session Info Card
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDarkMode ? Colors.black45 : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.user,
                            size: 16,
                            color: isDarkMode ? Colors.green : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current User: $_username',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.clock,
                            size: 16,
                            color: isDarkMode ? Colors.green : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Date and Time (UTC): ${_sessionDateTime.toIso8601String()}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(),

              // Travel Plan Form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _countryController,
                        label: 'Country',
                        icon: FontAwesomeIcons.earthAmericas,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a country';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _budgetController,
                        label: 'Budget (USD)',
                        icon: FontAwesomeIcons.dollarSign,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your budget';
                          }
                          final budget = int.tryParse(value!);
                          if (budget == null || budget <= 0) {
                            return 'Please enter a valid budget';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _daysController,
                        label: 'Number of Days',
                        icon: FontAwesomeIcons.calendar,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter number of days';
                          }
                          final days = int.tryParse(value!);
                          if (days == null || days <= 0 || days > 14) {
                            return 'Please enter between 1-14 days';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(context),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: chatProvider.isLoading ? null : _generatePlan,
                        icon: Icon(
                          chatProvider.isLoading
                              ? Icons.hourglass_empty
                              : FontAwesomeIcons.wandMagicSparkles,
                        ),
                        label: Text(
                          chatProvider.isLoading ? 'Generating...' : 'Generate Travel Plan',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ).animate().fadeIn(duration: 700.ms).slideY(),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BudgetFreeTravelForm(),
                            ),
                          );
                        },
                        icon: Icon(
                          FontAwesomeIcons.moneyBillWave,
                          color: isDarkMode ? Colors.green : Colors.green.shade700,
                        ),
                        label: Text(
                          'Generate Budget-Free Plan',
                          style: TextStyle(
                            color: isDarkMode ? Colors.green : Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(),
                    ],
                  ),
                ),
              ),

              // Generated Plan Display
              if (chatProvider.lastGeneratedItinerary != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isDarkMode ? Colors.black45 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.route,
                                color: isDarkMode ? Colors.green : Colors.green.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Your Travel Plan',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: isDarkMode ? Colors.green : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() {
                                _showImportantNotes = !_showImportantNotes;
                              }),
                              icon: Icon(
                                _showImportantNotes ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white,
                              ),
                              label: Text(
                                _showImportantNotes ? 'Hide Important Notes' : 'Show Important Notes',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          if (_showImportantNotes)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black54 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode ? Colors.green.withOpacity(0.3) : Colors.green.shade200,
                                ),
                              ),
                              child: _buildImportantNotes(
                                _extractImportantNotes(chatProvider.lastGeneratedItinerary!),
                                isDarkMode,
                              ),
                            ),
                          Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _getItineraryDays(chatProvider.lastGeneratedItinerary!).length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton(
                                    onPressed: () => setState(() {
                                      _selectedDayIndex = index;
                                    }),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      backgroundColor: _selectedDayIndex == index
                                          ? (isDarkMode ? Colors.green : Colors.green.shade600)
                                          : (isDarkMode ? Colors.black54 : Colors.green.shade100),
                                      foregroundColor: _selectedDayIndex == index
                                          ? Colors.white
                                          : (isDarkMode ? Colors.white70 : Colors.green.shade700),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: _selectedDayIndex == index ? 4 : 1,
                                    ),
                                    child: Text(
                                      'Day ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: _selectedDayIndex == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_selectedDayIndex != -1)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black54 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode ? Colors.green.withOpacity(0.3) : Colors.green.shade200,
                                ),
                              ),
                              child: _buildDayDetails(
                                _getItineraryDays(chatProvider.lastGeneratedItinerary!)[_selectedDayIndex],
                                isDarkMode,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: chatProvider.lastGeneratedItinerary!,
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Travel plan copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: isDarkMode ? Colors.green : Colors.green.shade700,
                                ),
                                label: Text(
                                  'Copy Plan',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.green : Colors.green.shade700,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addToCalendar,
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Add to Calendar'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportantNotes(String importantNotes, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Notes:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.green : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            importantNotes,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Weather Advice:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.green : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingWeather)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: isDarkMode ? Colors.green : Colors.green.shade700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetching weather information...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else if (_dailyWeatherAdvice[_selectedDayIndex] != null)
            Text(
              _dailyWeatherAdvice[_selectedDayIndex]!,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            )
          else
            Text(
              'No weather data available. Please select a date and generate a plan.',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(String dayDetails, bool isDarkMode) {
    final dayParts = dayDetails.split('|');
    final day = dayParts[1].trim();
    final morning = dayParts[2].trim();
    final afternoon = dayParts[3].trim();
    final evening = dayParts[4].trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day: $day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.green : Colors.green.shade700,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _fetchWeatherForDay(_selectedDayIndex),
              icon: Icon(
                _isLoadingWeather && _selectedDayIndex == _selectedDayIndex
                    ? Icons.refresh
                    : Icons.cloud,
                color: Colors.white,
              ),
              label: Text(
                _isLoadingWeather && _selectedDayIndex == _selectedDayIndex
                    ? 'Loading...'
                    : 'Weather',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        if (_dailyWeatherAdvice[_selectedDayIndex] != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black54 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.green.withOpacity(0.3) : Colors.green.shade200,
              ),
            ),
            child: Text(
              _dailyWeatherAdvice[_selectedDayIndex]!,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildPlaceText('Morning: $morning', isDarkMode),
        const SizedBox(height: 8),
        _buildPlaceText('Afternoon: $afternoon', isDarkMode),
        const SizedBox(height: 8),
        _buildPlaceText('Evening: $evening', isDarkMode),
      ],
    );
  }

  Future<void> _fetchWeatherForDay(int dayIndex) async {
    if (_selectedDate == null || _countryController.text.isEmpty) {
      setState(() {
        _dailyWeatherAdvice[dayIndex] = 'Please select a destination and date to get weather information.';
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _dailyWeatherAdvice[dayIndex] = '';
    });

    try {
      final targetDate = _selectedDate!.add(Duration(days: dayIndex));
      print('Fetching weather for: ${_countryController.text} on $targetDate'); // Debug log
      final weatherData = await WeatherService.getWeatherForecast(
        _countryController.text.trim(),
        targetDate,
      );
      final advice = WeatherService.getTravelAdvice(weatherData);
      
      setState(() {
        _dailyWeatherAdvice[dayIndex] = advice;
        _isLoadingWeather = false;
      });
    } catch (e) {
      print('Error fetching weather: $e'); // Debug log
      setState(() {
        _dailyWeatherAdvice[dayIndex] = 'Unable to fetch weather data. Please try again later.';
        _isLoadingWeather = false;
      });
    }
  }

  Widget _buildPlaceText(String text, bool isDarkMode) {
    final words = text.split(' ');
    final placeNames = ['Louvre Museum', 'Dar Ben Abdallah Museum', 'Tokyo', 'Shibuya', 'Harajuku', 'Asakusa', 'Ueno', 'Ginza', 'Hakone', 'Akihabara', 'Japan', 'Tunisia', 'Sousse', 'Tunis', 'Sfax', 'Monastir', 'Nabeul', 'Bizerte', 'Gabes', 'Gafsa', 'Kairouan', 'Kasserine', 'Kebili', 'Kef', 'Mahdia', 'Manouba', 'Medenine', 'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid', 'Siliana', 'Sousse', 'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan' , 'France', 'Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Nimes', 'Toulon', 'Aix-en-Provence', 'Lille', 'Rennes', 'Reims', 'Tours', 'Angers', 'Le Havre', 'Orléans', 'Limoges', 'Clermont-Ferrand', 'Toulouse', 'Nimes', 'Toulon', 'Aix-en-Provence', 'Lille', 'Rennes', 'Reims', 'Tours', 'Angers', 'Le Havre', 'Orléans', 'Limoges', 'Clermont-Ferrand', 'Thailand', 'New York', 'London', 'Paris', 'Tokyo', 'Beijing', 'Moscow', 'Sydney', 'Toronto', 'Berlin', 'Madrid', 'Rome', 'Dubai', 'Singapore', 'Los Angeles', 'Chicago', 'San Francisco', 'Seoul', 'Mumbai', 'São Paulo', 'Istanbul', 'Bangkok', 'Cairo', 'Johannesburg', 'Mexico City', 'Buenos Aires', 'Lagos', 'Nairobi', 'Jakarta', 'Kuala Lumpur', 'Amsterdam', 'Brussels', 'Vienna', 'Stockholm', 'Oslo', 'Helsinki', 'Copenhagen', 'Lisbon', 'Prague', 'Warsaw', 'Budapest', 'Zurich', 'Geneva', 'Barcelona', 'Munich', 'Frankfurt', 'Doha', 'Manila', 'Tel Aviv', 'Athens', 'Edinburgh', 'Dublin', 'Melbourne', 'Brisbane', 'Perth', 'Vancouver', 'Montreal', 'Calgary', 'Hamburg', 'Cologne', 'Lyon', 'Marseille', 'Nice', 'Seville', 'Valencia', 'Florence', 'Venice', 'Naples', 'Krakow', 'Gdańsk', 'Bratislava', 'Belgrade', 'Sarajevo', 'Skopje', 'Tirana', 'Sofia', 'Bucharest', 'Ankara', 'Izmir', 'Doha', 'Muscat', 'Riyadh', 'Jeddah', 'Abu Dhabi', 'Kuwait City', 'Amman', 'Damascus', 'Beirut', 'Casablanca', 'Marrakesh', 'Algiers', 'Tunis', 'Addis Ababa', 'Kampala', 'Accra', 'Dakar', 'Harare', 'Lusaka', 'Windhoek', 'Maputo', 'Luanda', 'Kinshasa', 'Kigali', 'Dar es Salaam', 'Hanoi', 'Ho Chi Minh City', 'Yangon', 'Phnom Penh', 'Vientiane', 'Ulaanbaatar', 'Kathmandu', 'Colombo', 'Thimphu', 'Male', 'Port Louis', 'Suva', 'Apia', 'Pago Pago', 'La Paz', 'Quito', 'Asunción', 'Montevideo', 'Caracas', 'Santiago', 'Lima', 'Port-au-Prince', 'Kingston', 'San Juan', 'Belmopan', 'Panama City', 'San José', 'Managua', 'Tegucigalpa', 'Guatemala City', 'San Salvador', 'Georgetown', 'Paramaribo', 'Nouakchott', 'Bamako', 'Niamey', 'Ouagadougou', 'Libreville', 'Malabo', 'Lomé', 'Porto-Novo', 'Cotonou', 'Yaoundé', 'Bissau', 'Conakry', 'Freetown', 'Monrovia', 'Victoria', 'Moroni', 'Antananarivo', 'Majuro', 'Palikir', 'Ngerulmud', 'Hagatna', 'Tarawa', 'Funafuti', 'Yaren', 'Baku', 'Tbilisi', 'Yerevan', 'Ashgabat', 'Dushanbe', 'Bishkek', 'Almaty', 'Astana', 'Honiara', 'Port Moresby','Louvre Museum', 'The British Museum', 'The Metropolitan Museum of Art', 'Vatican Museums', 'Rijksmuseum', 'Museo Nacional del Prado', 'The Uffizi Gallery', 'The State Hermitage Museum', 'National Gallery', 'Tate Modern', 'The Museum of Modern Art (MoMA)', 'Smithsonian Institution', 'National Museum of China', 'The Getty Center', 'Museum of Contemporary Art', 'The Egyptian Museum', 'The Acropolis Museum', 'The Van Gogh Museum', 'The Guggenheim Museum', 'Musée Rodin', 'The National Gallery of Art', 'The Picasso Museum', 'Altes Museum', 'The Pergamon Museum', 'The Frick Collection', 'The Dallas Museum of Art', 'The National Museum of Anthropology', 'The Art Institute of Chicago', 'National Palace Museum', 'Museum of Fine Arts', 'The Guggenheim Bilbao', 'The São Paulo Museum of Art', 'The National Archaeological Museum', 'The Louvre Abu Dhabi', 'The Tokyo National Museum', 'The National Museum of Korea', 'The Shanghai Museum', 'The Denver Art Museum', 'The Reina Sofia Museum', 'The National Museum of Scotland', 'The J. Paul Getty Museum', 'The Egyptian Museum of Cairo', 'The Solomon R. Guggenheim Museum', 'The Rijksmuseum Amsterdam', 'The Museum of Fine Arts in Boston', 'The Museum of Contemporary Art in Los Angeles', 'The Queensland Art Gallery', 'The State Tretyakov Gallery', 'The Israel Museum', 'The National Gallery of Canada', 'The Shanghai Museum of Art', 'The Museum of Islamic Art', 'The Museum of the History of Science', 'The International Red Cross and Red Crescent Museum', 'The Tate Britain', 'The Van Gogh Museum in Amsterdam', 'The Victoria and Albert Museum', 'The Museum of the History of Art', 'The Kunsthistorisches Museum', 'The Dubai Mall', 'Mall of America', 'The Galleria', 'West Edmonton Mall', 'SM Megamall', 'Harrods', 'Galeries Lafayette', 'Istanbul Cevahir Mall', 'King of Prussia Mall', 'Siam Paragon', 'Mall of the Emirates', 'CentralWorld', 'Palladium Mall', 'Chadstone Shopping Centre', 'Oxford Street', 'The Shops at Columbus Circle', 'Rodeo Drive', 'Milan Galleria Vittorio Emanuele II', 'The Grove', 'Dubai Marina Mall', 'Lotte World Mall', 'Mitsukoshi Ginza', 'Times Square Mall', 'K11 Musea', 'Roppongi Hills', 'Pacific Place', 'Moynihan Train Hall', 'Suntec City', 'Westfield London', 'L.A. Live', 'Ilikai Mall', 'Nanjing Deji Plaza', 'The Forum Shops at Caesars', 'Woolworth Building Mall', 'CentralPlaza Chonburi', 'VivoCity', 'Westfield Sydney', 'Ayala Center Cebu', 'La Roca Village', 'Changi City Point', 'Greenbelt Mall', 'Ion Orchard', 'Qatar Mall', 'Raffles City Shanghai', 'Vancouver Mall', 'Plaza Las Americas', 'Mall of Asia', 'Tokyo Midtown', 'The Mall at Millenia', 'Park Lane Mall', 'The Landmark', 'Dalian Youhao Mall', 'Beverly Center', 'Mall of the South', 'Mandarin Oriental Mall', 'Pacific Mall', 'Hartsfield-Jackson Atlanta International Airport', 'Beijing Capital International Airport', 'Los Angeles International Airport', 'Dubai International Airport', 'Tokyo Haneda Airport', 'London Heathrow Airport', 'Paris Charles de Gaulle Airport', 'Amsterdam Schiphol Airport', 'Hong Kong International Airport', 'Frankfurt Airport', 'Singapore Changi Airport', 'Incheon International Airport', 'Dallas/Fort Worth International Airport', 'Soekarno-Hatta International Airport', 'John F. Kennedy International Airport', 'Kuala Lumpur International Airport', 'Sydney Kingsford Smith Airport', 'Suvarnabhumi Airport', 'Moscow Sheremetyevo Airport', 'Shanghai Pudong International Airport', 'San Francisco International Airport', 'Toronto Pearson International Airport', 'Rome Fiumicino Airport', 'Munich Airport', 'Dubai Al Maktoum International Airport', 'Bali Ngurah Rai International Airport', 'Bangkok Don Mueang International Airport', 'Zurich Airport', 'Vienna International Airport', 'Beirut Rafic Hariri International Airport', 'Jeddah King Abdulaziz International Airport', 'Amman Queen Alia International Airport', 'Athens Eleftherios Venizelos Airport', 'Doha Hamad International Airport', 'Istanbul Airport', 'Cape Town International Airport', 'Mexico City International Airport', 'Chennai International Airport', 'Newark Liberty International Airport', 'Indira Gandhi International Airport', 'Lisbon Humberto Delgado Airport', 'Sao Paulo Guarulhos International Airport', 'Cairo International Airport', 'Abu Dhabi International Airport', 'Helsinki-Vantaa Airport', 'Oslo Gardermoen Airport', 'Kigali International Airport', 'Addis Ababa Bole International Airport', 'Lagos Murtala Muhammed International Airport', 'Kigali International Airport', 'Guangzhou Baiyun International Airport']; // Add more place names as needed

    return Wrap(
      children: words.map((word) {
        final cleanedWord = word.replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
        if (placeNames.contains(cleanedWord)) {
          return InkWell(
            onTap: () => _openMap(cleanedWord),
            child: Text(
              '$word ',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          );
        } else {
          return Text(
            '$word ',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          );
        }
      }).toList(),
    );
  }

  Future<void> _openMap(String place) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$place';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.green : Colors.green.shade700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Colors.green.withOpacity(0.5) 
                : Colors.green.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.green : Colors.green.shade700,
          ),
        ),
        filled: true,
        fillColor: isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.green.shade50,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Travel Start Date',
          prefixIcon: Icon(
            Icons.calendar_today,
            color: isDarkMode ? Colors.green : Colors.green.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.green.withOpacity(0.5)
                  : Colors.green.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.green : Colors.green.shade700,
            ),
          ),
          filled: true,
          fillColor: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.green.shade50,
        ),
        child: Text(
          _selectedDate == null
              ? 'Select Date'
              : _selectedDate!.toLocal().toString().split(' ')[0],
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  List<String> _getItineraryDays(String itinerary) {
    final lines = itinerary.split('\n');
    final days = <String>[];
    for (final line in lines) {
      if (line.startsWith('| **')) {
        days.add(line);
      }
    }
    return days;
  }

  String _extractImportantNotes(String itinerary) {
    final importantNotesStart = itinerary.indexOf('**Important Notes:**');
    final importantNotesEnd = itinerary.indexOf('**Explanation of Cost Savings:**');
    if (importantNotesStart != -1 && importantNotesEnd != -1) {
      return itinerary.substring(importantNotesStart, importantNotesEnd).trim();
    }
    return 'No important notes found.';
  }

  void _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a travel start date'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

    try {
      final request = TravelRequest(
        country: _countryController.text.trim(),
        budget: double.parse(_budgetController.text),
        days: int.parse(_daysController.text),
        startDate: _selectedDate!,
      );

      await context.read<ChatProvider>().generateItinerary(request);
      // Clear previous weather data when generating new plan
      setState(() {
        _dailyWeatherAdvice.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _addToCalendar() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a travel start date'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    if (chatProvider.lastGeneratedItinerary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please generate a travel plan first'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

    final itinerary = chatProvider.lastGeneratedItinerary!;
    final events = _parseItineraryToEvents(itinerary);

    for (final event in events) {
      Add2Calendar.addEvent2Cal(event);
    }
  }

  List<Event> _parseItineraryToEvents(String itinerary) {
    final events = <Event>[];
    final lines = itinerary.split('\n');
    DateTime currentDay = _selectedDate!;

    for (final line in lines) {
      if (line.startsWith('| **')) {
        final dayParts = line.split('|');
        final day = dayParts[1].trim();
        final morning = dayParts[2].trim();
        final afternoon = dayParts[3].trim();
        final evening = dayParts[4].trim();

        // Add morning event
        if (morning.isNotEmpty) {
          events.add(Event(
            title: 'Morning: $morning',
            description: 'Itinerary for $day',
            location: 'Travel destination',
            startDate: currentDay.add(Duration(hours: 8)),
            endDate: currentDay.add(Duration(hours: 12)),
          ));
        }

        // Add afternoon event
        if (afternoon.isNotEmpty) {
          events.add(Event(
            title: 'Afternoon: $afternoon',
            description: 'Itinerary for $day',
            location: 'Travel destination',
            startDate: currentDay.add(Duration(hours: 13)),
            endDate: currentDay.add(Duration(hours: 17)),
          ));
        }

        // Add evening event
        if (evening.isNotEmpty) {
          events.add(Event(
            title: 'Evening: $evening',
            description: 'Itinerary for $day',
            location: 'Travel destination',
            startDate: currentDay.add(Duration(hours: 18)),
            endDate: currentDay.add(Duration(hours: 22)),
          ));
        }

        currentDay = currentDay.add(Duration(days: 1));
      }
    }

    return events;
  }
}
