import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tflite/tflite.dart';

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
          title: Text("Bottle Classify",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  letterSpacing: 0.3))),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.camera),
      //   onPressed: () async {
      //     final pickedFile = await picker.getImage(source: ImageSource.camera);
      //
      //     print(pickedFile.path);
      //   },
      // ),
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

    if (recognitions.isNotEmpty) {
      Classification c = Classification(recognitions.first['confidence'],
          int.parse(recognitions.first['label']));

      _classificationController.add(c);
    }

    print(recognitions.first.toString());
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
      return 'Aprovado';
    case 1:
      return 'Reprovado';
    default:
      return 'Aguardando aprovação';
  }
}

Color maskClassColor(int label) {
  switch (label) {
    case 0:
      return Colors.green;
    case 1:
      return Colors.red;
    default:
      return Colors.blue[800];
  }
}

Icon maskClassIcon(int label) {
  switch (label) {
    case 0:
      return Icon(Icons.check_circle, color: Colors.green,);
    case 1:
      return Icon(Icons.close, color: Colors.red,);
    default:
      return Icon(Icons.access_time, color: Colors.blue[800],);
  }
}