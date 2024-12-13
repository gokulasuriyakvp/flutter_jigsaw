import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_jigsaw/puzzle_widget.dart';

class JigsawInfo {
  int gridSize = 4; // Default grid size
  String? imagePath; // Store the image path
}

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Call the crop image method after selecting an image
      await _cropImage(File(pickedFile.path));
    }
  }

  Future<void> _cropImage(File imageFile) async {
    // Crop the selected image
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      // The aspect ratio can be set within the UI settings instead
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          hideBottomControls: true,
         // cropGridColor: Colors.black,
         initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          // Set the aspect ratio presets here
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
           /* CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,*/
          ],
        ),
       /* IOSUiSettings(
          title: 'Crop',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),*/
      ],
    );

    // Update the selected image with the cropped image
    if (cropped != null) {
      setState(() {
        _selectedImage = File(cropped.path);

      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Image from Gallery'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              _selectedImage != null
                  ? Image.file(
                _selectedImage!,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                fit: BoxFit.cover,
              )
                  : Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 100),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Pick Image from Gallery"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectedImage != null
                    ? () => _showDetailsDialog(context, JigsawInfo(), _selectedImage)
                    : null, // Disable button if no image is selected
                child: const Text("Proceed to Jigsaw"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, JigsawInfo item, File? imageFile) {
    var _gridSizeValue = 4;
    AwesomeDialog(
      dialogBackgroundColor: Colors.white,
      context: context,
      animType: AnimType.scale,
      width: 400,
      dialogType: DialogType.noHeader,
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: 180,
            height: 400,
            alignment: Alignment.center,
            child: Column(
              children: [
                const SizedBox(height: 100),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildSelectGridSize(2, _gridSizeValue, (v) {
                      setState(() {
                        _gridSizeValue = 2;
                      });
                    }),
                    const SizedBox(height: 20.0),
                    buildSelectGridSize(3, _gridSizeValue, (v) {
                      setState(() {
                        _gridSizeValue = 3;
                      });
                    }),
                    const SizedBox(height: 20.0),
                    buildSelectGridSize(4, _gridSizeValue, (v) {
                      setState(() {
                        _gridSizeValue = 4;
                      });
                    }),
                    const SizedBox(height: 20.0),
                    buildSelectGridSize(5, _gridSizeValue, (v) {
                      setState(() {
                        _gridSizeValue = 5;
                      });
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      btnOk: Center(
        child: SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: () async {
              item.gridSize = _gridSizeValue;
              if (imageFile != null) {
                item.imagePath = imageFile.path; // Set image path to JigsawInfo
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PuzzleWidget(
                    imageFile: item.imagePath!, // Pass the image path to PuzzleWidget
                    gridSize: item.gridSize,
                  ),
                ));
              }
            },
            child: const Text("Start"),
          ),
        ),
      ),
    )..show();
  }

  Widget buildSelectGridSize(int num, int _gridSizeValue, void Function(int) onChanged) {
    final Color selectedColor = Colors.blue;
    final Color unselectedColor = Colors.grey;
    return GestureDetector(
      onTap: () {
        onChanged(num);
      },
      child: Container(
        width: 200,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _gridSizeValue == num ? selectedColor : unselectedColor,
        ),
        child: Center(
          child: Text(
            "${num * num}",
            style: const TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}


