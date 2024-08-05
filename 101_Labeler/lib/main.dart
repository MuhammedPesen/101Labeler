import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? _outputImage;
  CroppedFile? _croppedFile;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndProcess() async {
    const accessToken = String.fromEnvironment('ACCESS_TOKEN');

    if (accessToken.isEmpty) {
      print("ACCESS_TOKEN is not set");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'ACCESS_TOKEN is not set. Please provide it when running the app.')),
      );
      return;
    }

    setState(() {
      _outputImage = null; // Clear previous output image
    });

    try {
      await _initializeControllerFuture;
      print("Taking picture...");
      final image = await _controller.takePicture();
      print("Picture taken, path: ${image.path}");

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );

      if (croppedFile == null) {
        print("Image cropping cancelled");
        return;
      }

      File croppedImageFile = File(croppedFile.path);
      print("Cropped image path: ${croppedImageFile.path}");

      // API call
      final dio = Dio();
      dio.options.headers['cache-control'] = 'no-cache';
      dio.options.headers['pragma'] = 'no-cache';
      print("Preparing API call...");

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(croppedImageFile.path,
            filename: 'image_$timestamp.jpg'),
      });

      print("Sending API request...");
      final response = await dio.post(
        // !!! Free version of ngrok changes the URL in each session so CHECK !!!
        'https://3cb7-176-234-216-222.ngrok-free.app/detect/', 
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
            'access_token': accessToken,
          },
          responseType: ResponseType.bytes,
          // Disable caching
          extra: {'cache': false},
        ),
      );

      print("API response received, status code: ${response.statusCode}");

      // Save the response image
      final tempDir = await getTemporaryDirectory();
      File outputFile = File('${tempDir.path}/output_$timestamp.png');
      await outputFile.writeAsBytes(response.data);
      print("Output image saved to: ${outputFile.path}");

      // Extract the sum of digits from the headers
      String? labelSumHeader = response.headers.value('X-Label-Sum');
      int labelSum = int.tryParse(labelSumHeader ?? '0') ?? 0;

      // Update state to show new image
      setState(() {
        _outputImage = outputFile;
      });
      print("State updated with new image");

      // Navigate to output screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutputScreen(imageFile: outputFile, labelSum: labelSum),
        ),
      );
    } catch (e) {
      print("Error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('101 Labeler')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            _isProcessing = true;
          });
          await _takePictureAndProcess();
          setState(() {
            _isProcessing = false;
          });
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}

class OutputScreen extends StatelessWidget {
  final File imageFile;
  final int labelSum;

  const OutputScreen({Key? key, required this.imageFile, required this.labelSum}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Output Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(imageFile),
            SizedBox(height: 16.0),
            Text(
              'Sum of Digits: $labelSum',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}
