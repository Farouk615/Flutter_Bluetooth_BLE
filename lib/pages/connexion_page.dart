import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:knowlepsy_mobile/controllers/bluetooth_controller.dart';
import 'package:knowlepsy_mobile/pages/home_page.dart';
import 'dart:convert';
import 'package:intl/intl.dart';


class ConnexionPage extends StatelessWidget {
  const ConnexionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<BluetoothController>(
        init: BluetoothController(),
        builder: (controller)  {
          return SingleChildScrollView(
            child: Column(children: [
              Container(
                height: 100,
                width: double.infinity,
                color: Colors.blue,
                child: Text('Bluetooth App'),
              ),
              const SizedBox(height: 20,),
              Center(
                child: ElevatedButton(onPressed: () => controller.scan(),
                child: Text("Scan"),),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: controller.scanResults,
                builder: (context,snapshot){
                  if (snapshot.data != null && snapshot.data!.isNotEmpty){
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context,index){
                        final data = snapshot.data![index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(data.device.localName),
                            subtitle: Text(data.device.id.id),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                controller.connectedDevice=data.device;
                                controller.connectDevice().then((value) => Get.off(const HomePage()));
                            },
                            child: Text("Connect"),
                          ),
                          ),
                        );
                      },
                    );
                  }else{
                    return const Center(child: Text("No devices found"),);
                  }
                })
            ]),
          );
        },),
    );
  }
}