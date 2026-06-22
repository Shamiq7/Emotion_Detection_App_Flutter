import 'package:camera/camera.dart';
import 'package:emotion_detechtion_app/main.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

//what we want to do
// loadmodal()
//     ↓
// loadcamera()
//     ↓
// Camera starts
//     ↓
// Get camera frame
//     ↓
// Convert frame to model input
//     ↓
// Run model
//     ↓
// Show emotion

class Homepg extends StatefulWidget {
  const Homepg({super.key});

  @override
  State<Homepg> createState() => _HomepgState();
}

class _HomepgState extends State<Homepg> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  late Interpreter interpreter;
  bool isDetecting = false;

  // Open camera
  //     ↓
  // Start camera preview
  //     ↓
  // Continuously receive frames
  //     ↓
  // Store latest frame in cameraImage, everyframe us stored inside cameraImage = ImageStream,
  //so everytime cameraImage loads it contains the latest camera frame
  //Opens camera
  // Starts receiving frames ,        Prepare the eyes
  loadcamera() {
    cameraController = CameraController(camera![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
      cameraController!.startImageStream((ImageStream) async {
        cameraImage = ImageStream;
        if (!isDetecting) {
          isDetecting = true;
          print('Frame: ${ImageStream.width} x ${ImageStream.height}');
          await runModel();
          isDetecting = false;
        }
      });
      //  else {
      //   setState(() {
      //     cameraController!.startImageStream((ImageStream) {
      //       cameraImage = ImageStream;
      //       print('frame: ${ImageStream.width} x ${ImageStream.height}');
      //       // if (!isDetecting) {
      //       //   isDetecting = true;
      //       //   print('frame: ${ImageStream.width} x ${ImageStream.height}');
      //       //   isDetecting = false;
      //       // }
      //     });
      //   });
      // }
    });
  }

  // Load TensorFlow model
  //       ↓
  // Create Interpreter
  //       ↓
  // Model ready for predictions
  //interpreter = Brain of AI, we call it in init state so that when screen opeans - load modal - test image - show result
  Future<void> loadmodal() async {
    interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
    print('Model loaded Successfully');
    print('input shape: ${interpreter.getInputTensor(0).shape}');
    print('output shape: ${interpreter.getOutputTensor(0).shape}');
    print('input type: ${interpreter.getInputTensor(0).type}');
    print('output type: ${interpreter.getOutputTensor(0).type}');
    // await testImage();
  }

  // Take latest frame
  // Ask brain what it sees
  // Return prediction           Brain analyzes what eyes see
  Future runModel() async {
    if (cameraImage == null) return;
    print('converting frame..........');
    final img.Image image = img.Image(
      width: cameraImage!.width,
      height: cameraImage!.height,
    );
    print('image oblect created');
    print(cameraImage!.format.group);
    print('Running Model..........');
    print('plane0: ${cameraImage!.planes[0].bytes.length}');
    print('plane1: ${cameraImage!.planes[1].bytes.length}');
    print('plane2: ${cameraImage!.planes[2].bytes.length}');
    await Future.delayed(Duration(seconds: 9));
    print('width: ${cameraImage!.width}');
    print('height: ${cameraImage!.height}');
    print('planes: ${cameraImage!.planes.length}');
    final y = cameraImage!.planes[0].bytes[0];
    final u = cameraImage!.planes[1].bytes[0];
    final v = cameraImage!.planes[2].bytes[0];
    print('Y: $y');
    print('U: $u');
    print('V: $v');
    int r = (y + 1.402 * (v - 128)).round();
    int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
    int b = (y + 1.772 * (u - 128)).round();

    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    print('R: $r');
    print('G: $g');
    print('B: $b');
  }

  // Load Image
  //     ↓
  // Resize Image
  //     ↓
  // Convert Pixels
  //     ↓
  // Run AI
  //     ↓
  // Get Prediction
  //     ↓
  // Show Result
  //how the func works
  // testImage()
  //     ↓
  // Load pic1.jpeg
  //     ↓
  // Convert bytes → image
  //     ↓
  // Resize to 224×224
  //     ↓
  // Convert pixels → tensor
  //     ↓
  // Create empty output tensor
  //     ↓
  // Run TensorFlow model
  //     ↓
  // Get [Happy,Sad,Angry] scores
  //     ↓
  // Find highest score
  //     ↓
  // Create output text
  //     ↓
  // Update UI
  Future<void> testImage() async {
    final ByteData data = await rootBundle.load(
      'images/pic1.jpeg',
    ); // loads/reads image from assets folder
    final Uint8List bytes = data.buffer
        .asUint8List(); //converts image data into raw bytes
    img.Image image = img.decodeImage(
      bytes,
    )!; //converts raw bytes into an actual image object that dart can work with
    image = img.copyResize(
      image,
      width: 224,
      height: 224,
    ); // resizes image, why 224 because we got Model input shape = [1, 224, 224, 3] so every image must be 224 x 224
    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );
    var modeloutput = List.generate(1, (_) => List.filled(3, 0.0));
    interpreter.run(input, modeloutput);
    // print(output);
    List<String> labels = ['Happy', 'Sad', 'Angry'];
    var scores = modeloutput[0];
    double maxScore = scores[0];
    int maxIndex = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }
    // print('Emotion ${labels[maxIndex]}');
    // print('Confidence: ${(maxScore * 100).toStringAsFixed(2)}');
    setState(() {
      output = '${labels[maxIndex]} (${(maxScore * 100).toStringAsFixed(2)}%)';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadmodal();
    loadcamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face detectt'), centerTitle: true),
      body: cameraController == null || !cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : CameraPreview(cameraController!),
      // Center(
      //   child: Text(
      //     output,
      //     style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      //   ),
      // ),
    );
  }
}




// pic1.jpeg
//     ↓
// Resize to 224x224
//     ↓
// Convert RGB pixels to float values
//     ↓
// TensorFlow Lite model
//     ↓
// [Happy, Sad, Angry]
//     ↓
// Find highest score
//     ↓
// Print prediction