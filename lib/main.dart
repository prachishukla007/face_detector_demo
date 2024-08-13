import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceDetectionScreen(),
    );
  }
}

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions());

  List<File> _faces = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      _faces.clear();

      for (var face in faces) {
        final cropRect = Rect.fromLTRB(
          face.boundingBox.left,
          face.boundingBox.top,
          face.boundingBox.right,
          face.boundingBox.bottom,
        );

        final croppedFile = await _cropFace(pickedFile.path, cropRect);
        _faces.add(croppedFile);
      }

      setState(() {});
    }
  }

  Future<File> _cropFace(String imagePath, Rect cropRect) async {
    // Read the image from the file
    final originalImage = img.decodeImage(File(imagePath).readAsBytesSync());

    if (originalImage == null) {
      throw Exception('Could not decode image');
    }

    // Calculate the crop region
    final x = cropRect.left.toInt();
    final y = cropRect.top.toInt();
    final width = cropRect.width.toInt();
    final height = cropRect.height.toInt();

    // Crop the image using the calculated region
    final croppedImage = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);

    // Save the cropped image to a temporary file with a unique name
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final croppedImagePath = path.join(directory.path, 'cropped_face_$timestamp.png');
    final croppedFile = File(croppedImagePath)
      ..writeAsBytesSync(img.encodePng(croppedImage));

    return croppedFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Detection')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Upload Group Picture'),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: _faces.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipOval(
                    child: Image.file(_faces[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
