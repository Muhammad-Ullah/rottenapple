
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rotten_apple_detection/main.dart';
import 'package:tflite/tflite.dart';

class Model extends StatefulWidget {
  const Model({Key? key}) : super(key: key);

  @override
  State<Model> createState() => _ModelState();
}

class _ModelState extends State<Model> {


  late File _image;
  bool selImage=false;
  List result=[];
  String output='kh';
  CameraController? cameraController;
  CameraImage? cameraImage;

  @override
  void initState()
  {
    super.initState();
    loadModel().then((value){
      setState((){

      });
    });
    loadCamera();
  }
  @override
  dispose()
  {
    super.dispose();
    Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: const Text("Rotten Apple Detection"),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height*0.8,
              width: MediaQuery.of(context).size.width,
              child: (cameraController!.value.isInitialized)?AspectRatio(aspectRatio: cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!)):Container(),
              ),
          ),
          Text(output,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
          // (selImage)?Image.file(_image):Container(),
          // const SizedBox(
          //   height: 30,
          // ),
          // (result.isEmpty)?Container():Text(result[0]['label'],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
          // InkWell(
          //   onTap: (){
          //     chooseImage();
          //   },
          //   child: Container(
          //     margin: const EdgeInsets.only(top: 20),
          //     padding: const EdgeInsets.all(10),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(10),
          //       color: Colors.indigoAccent,
          //     ),
          //     child: const Text("Pick an Image",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
          //   ),
          // )
        ],
      ),
    ));
  }

  Future<void> chooseImage()
  async {
    final image=await ImagePicker().pickImage(source: ImageSource.gallery);
    if(image!.path!=null)
      {
        setState((){
          selImage=true;
          _image=File(image.path);
        });
      }
    predictImage(_image);
  }

  loadModel() async
  {
    await Tflite.loadModel(model: 'assets/model_unquant.tflite',labels: 'assets/labels.txt');
  }
  predictImage(File image) async{
    var output=await Tflite.runModelOnImage(path: image.path,numResults: 5,threshold: 0.5,imageMean: 127.5,imageStd: 127.5);
    setState((){
      result=output!;
    });
    print("Result is: $result");
  }

  loadCamera(){
    cameraController=CameraController((camera![0]), ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if(!mounted)
        {
          return;
        }
      else
        {
          setState(() {
            cameraController!.startImageStream((image) {
              cameraImage=image;
              runModel();
            });
          });
        }
    });
  }
  runModel() async {
    if(cameraImage!=null)
      {
        var predictions= await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 5,
          threshold: 0.1,
          asynch: true
        );
        for (var element in predictions!)
          {
            setState(() {
              output=element['label'];
            });
          }
      }
  }
}
