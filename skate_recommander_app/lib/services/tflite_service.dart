import 'package:flutter/material.dart';
import 'package:skate_recommander_app/services/direction_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:skate_recommander_app/models/app_state.dart';


class TfliteService {
  late Interpreter _interpreter;
  final String modelPath = "assets/model.tflite";

  Future <void> loadModel() async {
    try{
      _interpreter = await Interpreter.fromAsset(modelPath);
      print("[+] Model Loaded, \nInput Tensor Shape: ${_interpreter.getInputTensor(0).shape}\nOutput Tensor Shape: ${_interpreter.getOutputTensor(0).shape}" );
    
    }
    catch(e){
      throw Exception("[-] Enable to load the model!");
    }
  }

  double predictRecommandationScore({
    required WeatherMetaData weather,
    required SkateSpotMetadata metadata,
  }){
    double weatherIndex = 2.0;
    if (weather.weather.contains('rain') || 
    weather.weather.contains('snow') || 
    weather.weather.contains('drizzle') || 
    weather.weather.contains('thunderstorm') || 
    weather.temp < 5.0) {
      weatherIndex =  0.0;
    }

    else if (weather.weather.contains('mist') || 
    weather.weather.contains('smoke') || 
    weather.weather.contains('haze') || 
    weather.weather.contains('fog') ||
    weather.weather.contains('squall') ||
    weather.weather.contains('tornado')) { 
      weatherIndex = 1.0;
    }

    else if (weather.weather.contains('cloud') || weather.weather.contains('overcast')) {
      weatherIndex = 2.0;
    }

    else if (weather.weather.contains('clear') || weather.weather.contains('sun')) {
      weatherIndex = 3.0;
    }

    final idInput = [
      [metadata.index.toDouble()]
    ];

    final weatherInput = [
      [weatherIndex]
    ];

    final output = <int, Object>{
      0: [
        [0.0]
      ]
    };

    _interpreter.runForMultipleInputs(
      [idInput, weatherInput],  // inputs (List<Object>)
      output                    // outputs (Map<int, Object>)
    );
      print(weatherIndex);
      print("output = $output");
     final recommandationScore =
      (output[0] as List<List<double>>)[0][0];

    return recommandationScore;
  }

  void close(){
    _interpreter.close();
  }
}