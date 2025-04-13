class WeatherData {
  final String? cityName;
  final double? temperature;
  final String? condition;
  final int? humidity;
  final double? windSpeed;  // in m/s
  final int? pressure;     // in hPa
  final int? visibility;   // in meters
  final String? iconCode;  // for weather icons

  WeatherData({
    this.cityName,
    this.temperature,
    this.condition,
    this.humidity,
    this.windSpeed,
    this.pressure,
    this.visibility,
    this.iconCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'],
      temperature: json['main']['temp']?.toDouble(),
      condition: json['weather'][0]['main'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed']?.toDouble(),
      pressure: json['main']['pressure'],
      visibility: json['visibility'] != null ? (json['visibility'] / 1000).round() : null, // Convert to km
      iconCode: json['weather'][0]['icon'],
    );
  }
}