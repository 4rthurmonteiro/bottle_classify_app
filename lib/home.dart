import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File _image;
  final picker = ImagePicker();

  final _classificationController = BehaviorSubject<Classification>();

  Stream<Classification> get outClassification =>
      _classificationController.stream;

  void dispose() {
    super.dispose();
    _classificationController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black87),
          elevation: 2.0,
          backgroundColor: Colors.red,
          centerTitle: true,
          title: Text("Classificador de frutas",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  letterSpacing: 0.3))),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: SpeedDial(
        marginRight: 18,
        marginBottom: 20,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child: Icon(Icons.add),
        visible: true,
        // If true user is forced to close dial manually
        // by tapping main button and overlay is not rendered.
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
              child: Icon(Icons.camera),
              backgroundColor: Colors.red,
              label: 'Tire a foto da garrada',
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () async {
                final pickedFile =
                    await picker.getImage(source: ImageSource.camera);
                File croppedImage;
                if (pickedFile != null) {
                  croppedImage = await cropped(pickedFile.path, context);

                  if (croppedImage == null)
                    croppedImage = File(pickedFile.path);
                }
                loadModel();

                setState(() {
                  if (pickedFile != null) {
                    _image = croppedImage;

                    predictImage(_image);

                  } else {
                    print('No image selected.');
                  }
                });
              }),
          SpeedDialChild(
            child: Icon(Icons.photo_album),
            backgroundColor: Colors.blue,
            label: 'Use uma foto do celular',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              PickedFile pickedFile =
                  await picker.getImage(source: ImageSource.gallery);
              File croppedImage;

              if (pickedFile != null) {
                croppedImage = await cropped(pickedFile.path, context);

                if (croppedImage == null) croppedImage = File(pickedFile.path);
              }

              loadModel();


              setState(() {
                if (pickedFile != null) {
                  _image = croppedImage;


                  predictImage(_image);
                } else {
                  print('No image selected.');
                }
              });


            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: _image == null
                  ? Text(
                      "Clique no botão a direita para classificar a imagem da garrafa")
                  : Image.file(_image),
            ),
            StreamBuilder<Classification>(
                stream: outClassification,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();

                  }else{
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                          child: Column(
                            children: <Widget>[
                              Card(
                                child: ExpansionTile(
                                  leading: maskClassIcon(snapshot.data.classification),
                                  initiallyExpanded: true,
                                  title: Text(
                                    maskClass(snapshot.data.classification, context),
                                    style: TextStyle(
                                        color: maskClassColor(snapshot.data.classification),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, right: 16, top: 0, bottom: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[

                                              ListTile(
                                                title: Text('Confiança'),
                                                subtitle: Text(
                                                    snapshot.data.confidence != null ? "${(snapshot.data.confidence*100).toStringAsFixed(2)} %" :
                                                    ""),
                                                trailing: Icon(Icons.verified_user),
                                              ),
                                              ListTile(
                                                title: Text('Acurácia'),
                                                subtitle: Text(
                                                    "87 %"),
                                                trailing: Icon(Icons.my_location),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Card(
                                child: ExpansionTile(
                                  leading: Icon(Icons.info),
                                  initiallyExpanded: false,
                                  title: Text(
                                    'Saiba mais',
                                    style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  children: <Widget>[
                                    Text('O que é confiança?', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text('......................'),

                                    ),
                                    Text('O que é acurácia?', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text('............'),

                                    ),
                                  ],
                                ),
                              ),

                            ],
                          )
                      ),
                    );
                  }
                  return Container();
                })
          ],
        ),
      ),
    );
  }

  Future<File> cropped(String path, BuildContext context) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: path,
      compressQuality: 100,
      aspectRatioPresets: const [
        CropAspectRatioPreset.square,
      ],
      androidUiSettings: AndroidUiSettings(
        toolbarTitle: 'Cortar Imagem',
        toolbarWidgetColor: Colors.black87,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
        backgroundColor: Colors.black87,
      ),
    );

    return croppedFile;
  }

  loadModel() async {
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/tflite/converted_model.tflite",
        labels: "assets/tflite/converted_model.txt",
      );

      print(res);
    } catch (e) {
      print(e);
      print("Failed to load the model");
    }
  }

  predictImage(File image) async {
    if (image == null) return;

    await mobileNet(image);
  }

  mobileNet(File image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageStd: 128.0,
        imageMean: 128.0,
        threshold: 0.40,
        numResults: 1);
    // var imageBytes = image.readAsBytesSync();
    // img.Image oriImage = img.decodeJpg(imageBytes);
    // img.Image resizedImage = img.copyResize(oriImage, height: 224, width: 224);
    //
    // var recognitions = await Tflite.runModelOnBinary(
    //   binary: imageToByteListFloat32(resizedImage, 224, 127.5, 127.5),
    //   numResults: 6,
    //   threshold: 0.05,
    // );

    // var recognitions = await Tflite.runModelOnBinary(
    //     binary: imageToByteListFloat32(image.path, 224, 127.5, 127.5),// required
    //     numResults: 6,    // defaults to 5
    //     threshold: 0.05,  // defaults to 0.1
    //     asynch: true      // defaults to true
    // );

    if (recognitions.isNotEmpty) {
      Classification c = Classification(recognitions.first['confidence'],
          int.parse(recognitions.first['label']));

      _classificationController.add(c);
    }

    print(recognitions.first.toString());
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}

class Classification {
  double confidence;
  int classification;

  Classification(this.confidence, this.classification);
}

String maskClass(int label, BuildContext context) {
  switch (label) {
    case 0:
      return 'Abacaxi';
    case 1:
      return 'Coco';
    case 2:
      return 'Limão';
    case 3:
      return 'Laranja';
    case 4:
      return 'Pera';
    default:
      return 'Aguardando aprovação';
  }
}

Color maskClassColor(int label) {
  switch (label) {
    case 0:
      return Colors.yellow;
    case 1:
      return Colors.brown;
    case 2:
      return Colors.green;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.lightGreen;
    default:
      return Colors.blue[800];
  }
}

Icon maskClassIcon(int label) {
  switch (label) {
    default:
      return Icon(Icons.class_, color: Colors.blue[800],);
  }
}