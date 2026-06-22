import 'package:camera/camera.dart';
import 'package:emotion_detechtion_app/homepg.dart';
import 'package:flutter/material.dart';

//making a list for our cameras
List<CameraDescription>? camera;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  camera = await availableCameras();
  for (var c in camera!) {
    print('${c.name} - ${c.lensDirection}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Homepg());
  }
}
