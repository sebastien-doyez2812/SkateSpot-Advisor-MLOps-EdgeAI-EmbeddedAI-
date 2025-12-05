import 'package:flutter/foundation.dart';
import 'package:skate_recommander_app/services/api_services.dart';
import 'package:skate_recommander_app/services/geolocation_servcice.dart';
import 'package:skate_recommander_app/services/tflite_service.dart';
import 'package:skate_recommander_app/services/direction_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SkateSpotMetadata {
  final String name;
  final double index;
  final double latitude;
  final double longitude;
  final String imageUrl;

  SkateSpotMetadata({
    required this.name,
    required this.index,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });
}

class WeatherMetaData{
  final String weather;
  final double temp;
  final double feelsLike;
  final double humidity;
  final double wind;

  WeatherMetaData({
    required this.weather,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
  });
}

class SkateModel {
  final SkateSpotMetadata skateSpotData;
  final WeatherMetaData weatherData;
  final DirectionsInfo travelDirection;
  double recommendationScore;

  WeatherMetaData get snapshot => weatherData;
  DirectionsInfo get snapshotTravel => travelDirection;

  bool get isRecommended => recommendationScore > 0.5;

  SkateModel({
    required this.skateSpotData, 
    required this.weatherData, 
    required this.travelDirection,
    required this.recommendationScore
  });

  String get name => skateSpotData.name;
  double get latitude => skateSpotData.latitude;
  double get longitude => skateSpotData.longitude;
  double get score => recommendationScore;
}

class AppState extends ChangeNotifier{
  final ApiService _apiService;
  final DirectionService _directionService;
  final TfliteService _tfliteService;

  final double _defaultLat = 45.514752; 
  final double _defaultLng = -73.4789632;
  double _userLatitude = 45.514752;
  double _userLongitude = -73.4789632;
  
  LatLng get centerMap =>LatLng(_userLatitude, _userLongitude);

  bool _isLoading = false;
  bool _hasError = false;
  
  List<SkateModel> _spots = []; 

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  List<SkateModel> get spots => _spots;
  
  int get recommendedSpotCount => _spots.where((s) => s.isRecommended).length;

  final List<Map<String, dynamic>> _spotMetadataRaw = [
    { 'index': 0, 'spot': 'Ahuntsic', 'latitude': 45.5549710, 'longitude': -73.6655090, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/ahuntsic.jpg' },
    { 'index': 1, 'spot': 'VanHorne', 'latitude': 45.5280967, 'longitude': -73.6032037, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/vanhorne.jpg' },
    { 'index': 2, 'spot': 'Verdun', 'latitude': 45.4651901, 'longitude': -73.5612674, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/verdun.jpg' },
    { 'index': 3, 'spot': 'Lasalle', 'latitude': 45.4279386, 'longitude': -73.6020374, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/lasalle.jpg' },
    { 'index': 4, 'spot': 'Préfontaine', 'latitude': 45.5420670, 'longitude': -73.5540844, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/prefontaine.jpg' },
    { 'index': 5, 'spot': 'Boucherville', 'latitude': 45.6045212, 'longitude': -73.4455350, 'url': '' },
    { 'index': 6, 'spot': 'Taz', 'latitude': 45.5607671, 'longitude': -73.6350361, 'url': '' },
    { 'index': 7, 'spot': 'Spin', 'latitude': 45.4442666, 'longitude': -73.4335593, 'url': '' },
    { 'index': 8, 'spot': 'Saint Jérome', 'latitude': 45.783333, 'longitude': -74.00000, 'url': '' },
    { 'index': 9, 'spot': 'Saint Sauveur', 'latitude': 45.8984171, 'longitude': -74.1579093, 'url': '' },
    { 'index': 10, 'spot': 'Assomption', 'latitude': 45.8509996, 'longitude': -73.4196890, 'url': ''},
    { 'index': 11, 'spot': 'Benny', 'latitude': 45.4661667, 'longitude': -73.6329167, 'url': '' },
    { 'index': 12, 'spot': 'Dorval', 'latitude': 45.4418142, 'longitude': -73.7554385, 'url': '' }, 
    { 'index': 13, 'spot': 'Magog', 'latitude': 45.2661561, 'longitude': -72.1582782, 'url': '' },
    { 'index': 14, 'spot': 'Berthierville', 'latitude': 46.0653026, 'longitude': -73.1858064, 'url': 'https://raw.githubusercontent.com/sebastien-doyez2812/SkateSpot-Advisor-MLOps-EdgeAI-EmbeddedAI-/main/skate_recommander_app/images/berthierville.jpg' },
  ];

  AppState({
    required ApiService apiService,
    required DirectionService directionService,
    required TfliteService tfliteService,
  }) : _apiService = apiService, 
  _directionService = directionService,
  _tfliteService = tfliteService
  {
    final DirectionsInfo defaultDirections = DirectionsInfo(distanceText: "0.0 km", durationText: "0 min", duration: 0.0, distance: 0.0);

    _spots = _spotMetadataRaw.map((data) {
      final meta = SkateSpotMetadata(
        name: data['spot'] as String,
        index: data['index'].toDouble(),
        latitude: data['latitude'].toDouble(),
        longitude: data['longitude'].toDouble(), 
        imageUrl: data['url'] as String
      );

      final defaultSnapShot = WeatherMetaData(
        weather: "Clouds",
        temp: 0.0,
        feelsLike: 0.0,
        humidity: 0.0,
        wind: 0.0
      );
      _tfliteService.loadModel();
      return SkateModel(skateSpotData: meta, weatherData: defaultSnapShot, travelDirection: defaultDirections, recommendationScore: 1.0);
    }).toList();
  }

  Future <void> initializeData() async{
    await updateUserLocation();
    await fetchAndProcessData();
  }
  Future <void> updateUserLocation() async {
    try{
      final position = await getCurrentLocation();
      if (position != null){
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      }
    }
    catch(e){
      print(e);
    }

    await calculateAllSpotDirections();

    notifyListeners();
  }

  Future<void> calculateAllSpotDirections() async {
    if (_userLatitude == _defaultLat && _userLongitude == _defaultLng) return;

    final List<SkateModel> updatedSpots = [];
    for(final spot in _spots){
      DirectionsInfo newDirections = spot.travelDirection;
      try{
        final DirectionsInfo? info = await _directionService.getDirections(originLat: _userLatitude, originLng: _userLongitude, destLat: spot.latitude, destLng: spot.longitude);
        if (info != null){
          newDirections = info;
        }
      }
      catch(e){
        if (kDebugMode) print('[-] Error for spot ${spot.name}: $e');
      }
      // To avoid the error 429 too much request per second:
      await Future.delayed(const Duration(milliseconds: 20));


      updatedSpots.add(SkateModel(
        skateSpotData: spot.skateSpotData, 
        weatherData: spot.weatherData, 
        travelDirection: newDirections, 
        recommendationScore: spot.recommendationScore
      ));
    }
    _spots = updatedSpots;
  }

  Future<void> sendFeedback({
    required String spotName,
    required String liked, 
    required String modelScore, 
    required String weather, 
    required String distance, 
    required String travelTime
  }) async {

    final url = Uri.parse("https://script.google.com/macros/s/AKfycbyhIwSnZu1xmGkCzGDolwzgdLHvFqDvudfcc9wko4VAvJqqXgcvJbJJy_aSyFTwwhyEAw/exec"
    "?spot_name=$spotName&liked=$liked&model_score=$modelScore&weather=$weather&distance=$distance&travel_time=$travelTime"); 
    try{
      final response = await http.get(url);
      print("[+] Feedback sent: ${response.body}");
    } catch(e){
      print("[-] Failed to send feedback: $e");
    }
  }


  Future <void> fetchAndProcessData() async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final List<Future<SkateModel>> futures = _spots.map((spot) async {
        
        WeatherMetaData newWeather = spot.weatherData;
        double newScore = 0.0; 
        
        try {
          // 1. Appel de l'API Météo
          final WeatherMetaData snapshot = await _apiService.fetchWeatherForSpot(spot.skateSpotData);
          
          newWeather = WeatherMetaData(
            weather: snapshot.weather,
            temp: snapshot.temp,
            feelsLike: snapshot.feelsLike,
            humidity: snapshot.humidity,
            wind: snapshot.wind,
          );
          // TensorflowLite prediction:
          newScore = _tfliteService.predictRecommandationScore(
            weather: newWeather,
            metadata: spot.skateSpotData,
          );

          if (newScore > 1) {
            newScore = 1;
          }
          else if (newScore < 0) {
            newScore = 0;
          }

        } catch (e) {
          if (kDebugMode) print('[-] Error fetching weather for ${spot.name}: $e. Stay on the previous data.');
        }
        
        return SkateModel(
          skateSpotData: spot.skateSpotData, 
          weatherData: newWeather, 
          travelDirection: spot.travelDirection,
          recommendationScore: newScore
        );
      }).toList();

      _spots = await Future.wait(futures);

    } catch (e) {
      if (kDebugMode) print('Erreur globale: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}