// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:skate_recommander_app/models/app_state.dart';
import 'package:skate_recommander_app/widgets/weather_spot_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return FutureBuilder<void>(
      // Ask to init data:
      future: appState.initializeData(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading page
          return Scaffold(
            body: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                  Image.asset(
                    "assets/icons/logo_skate_spot_advisor.png",
                    height: 80.0, 
                  ),
                  SizedBox(height: 30.0),
                  CircularProgressIndicator(),
                  SizedBox(height: 15.0,),
                  Text(
                    'Fetching Skate Spot Data...',
                    style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[700],
                  ),
                )
              ],
            )),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('SkateSpotRecommander')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }
        return _buildContent(context, Provider.of<AppState>(context)); 
      },
    );
  }

  Widget _buildContent(BuildContext context, AppState appState){
    final List<SkateModel> spots = appState.spots;
    final List<SkateModel> sortedSpots = List.from(spots);
    sortedSpots.sort((a, b) => b.score.compareTo(a.score));
    
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[200],
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: appState.centerMap,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.skaterecommander.app', // Obligatoire
                  ),
                  // Spot localisation on the map
                  MarkerLayer(
                    markers: appState.spots.map((data) {
                      return Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(data.latitude, data.longitude),
                        child: GestureDetector(
                          onTap: () {
                            _showSpotImage(context, data);
                          }, child: const Icon( 
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40.0,
                        ),
                        ) 
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // TODO: add the share Button
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),

          // Spots list:
          Expanded(
            flex: 2,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: appState.spots.length,
              itemBuilder: (context, index) {
                final data = sortedSpots[index]; 

                // Sort by Satisfaction score:
                return WeatherSpotCard(
                  spotName: 'Spot ${data.name}',
                  weather: data.weatherData.weather,
                  temp: data.weatherData.temp.toStringAsFixed(1),
                  feelsLike: data.weatherData.feelsLike.toStringAsFixed(1),
                  humidity: data.weatherData.humidity.toStringAsFixed(1),
                  wind: data.weatherData.wind.toStringAsFixed(1),
                  trafficTime: data.travelDirection.durationText,
                  distance: data.travelDirection.distanceText,
                  satisfaction: (data.score * 100).toStringAsFixed(1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSpotImage(BuildContext context, SkateModel data) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  data.skateSpotData.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return const Text(
                      "No image available.",
                      style: TextStyle(color: Colors.grey),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

}