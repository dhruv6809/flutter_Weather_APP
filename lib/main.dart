import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global Weather',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey = 'b4495f1a8fb749a8b22124150250604';
  final TextEditingController _searchController = TextEditingController();
  WeatherData? _currentWeather;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _usingCurrentLocation = true;
  bool _showSearchBar = false;

  final Map<String, String> _nameCorrections = {
    'Yaman': 'Yemen',
    'Al Qāhirah': 'Cairo',
    'Makkah': 'Mecca',
    'Al-Iskandariyah': 'Alexandria',
    'Westampton': 'New Jersey',
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();
    });
  }

  void _precacheImages() {
    final images = [
      'assets/images/sunny.jpg',
      'assets/images/rain.jpg',
      'assets/images/cloudy.jpg',
      'assets/images/thunder.jpg',
      'assets/images/snow.jpg',
      'assets/images/main.jpg',
    ];
    for (var image in images) {
      final assetImage = AssetImage(image);
      assetImage.resolve(ImageConfiguration.empty);
    }
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _usingCurrentLocation = true;
      _showSearchBar = false;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await _fetchWeatherData(lat: position.latitude, lon: position.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocationWeather() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _usingCurrentLocation = false;
      _showSearchBar = false;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=${_searchController.text}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _fetchWeatherData(data: data);
      } else {
        throw Exception('Failed to search location');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherData({double? lat, double? lon, Map<String, dynamic>? data}) async {
    try {
      if (data == null) {
        final response = await http.get(Uri.parse(
            'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$lat,$lon'));
        if (response.statusCode != 200) {
          throw Exception('Failed to load weather data');
        }
        data = jsonDecode(response.body);
      }

      setState(() {
        _currentWeather = WeatherData.fromJson(data!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getWeatherAnimation(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny': return 'assets/animation/sunny1.json';
      case 'rain': case 'drizzle': return 'assets/animation/rain.json';
      case 'cloudy': case 'partly cloudy': return 'assets/animation/cloudy.json';
      case 'thunderstorm': return 'assets/animation/thunder.json';
      case 'light snow': case 'snow': return 'assets/animation/snow.json';
      default: return 'assets/animation/cloudy.json';
    }
  }

  String _getWeatherBackground(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny': return 'assets/images/sunny.jpg';
      case 'little rain': case 'rain': case 'drizzle': return 'assets/images/rain.jpg';
      case 'cloudy':case 'mist': case 'partly cloudy': return 'assets/images/cloudy.jpg';
      case 'thunderstorm': return 'assets/images/thunder.jpg';
      case 'light snow': case 'snow': return 'assets/images/snow.jpg';
      default: return 'assets/images/main.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Global Weather', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _getCurrentLocationWeather,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentWeather != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_getWeatherBackground(_currentWeather?.condition)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 20),
                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search any city...',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(color: Colors.black87),
                                cursorColor: Colors.blue,
                                onSubmitted: (_) => _searchLocationWeather(),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.search, color: Colors.blue[800]),
                              onPressed: _searchLocationWeather,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else if (_errorMessage.isNotEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _usingCurrentLocation ? _getCurrentLocationWeather : _searchLocationWeather,
                        child: const Text('Try Again'),
                      ),
                    ],
                  )
                else if (_currentWeather == null)
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 50, color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          'Search for any location or use your current location',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Material(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      _currentWeather?.cityName ?? 'Unknown Location',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_currentWeather?.lat?.toStringAsFixed(4)}°N, ${_currentWeather?.lon?.toStringAsFixed(4)}°E',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Text(
                                      '${_currentWeather?.temperature?.toStringAsFixed(1) ?? '--'}°C',
                                      style: const TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: Lottie.asset(
                                        _getWeatherAnimation(_currentWeather?.condition),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _currentWeather?.condition ?? '',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Material(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _buildWeatherDetails(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailItem(Icons.water_drop, '${_currentWeather?.humidity}%', 'Humidity'),
            _buildDetailItem(Icons.air, '${_currentWeather?.windSpeed?.toStringAsFixed(1)} kph', 'Wind'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailItem(Icons.thermostat, '${_currentWeather?.feelsLike?.toStringAsFixed(1)}°C', 'Feels Like'),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class WeatherData {
  final String? cityName;
  final double? temperature;
  final double? feelsLike;
  final String? condition;
  final int? humidity;
  final double? windSpeed;
  final double? lat;
  final double? lon;

  WeatherData({
    this.cityName,
    this.temperature,
    this.feelsLike,
    this.condition,
    this.humidity,
    this.windSpeed,
    this.lat,
    this.lon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['location']['name'],
      temperature: json['current']['temp_c']?.toDouble(),
      feelsLike: json['current']['feelslike_c']?.toDouble(),
      condition: json['current']['condition']['text'],
      humidity: json['current']['humidity'],
      windSpeed: json['current']['wind_kph']?.toDouble(),
      lat: json['location']['lat']?.toDouble(),
      lon: json['location']['lon']?.toDouble(),
    );
  }
}