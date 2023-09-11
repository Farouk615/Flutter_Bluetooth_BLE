import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BluetoothController extends GetxController{

  late BluetoothDevice connectedDevice;
  String ServiceUuidTx = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"; // Replace with your target UUID
  String ServiceUuidRx = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"; // Replace with your target UUID
  String characteristicUuidRx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  late List<BluetoothService> services;
  late BluetoothService serviceTx;
  late BluetoothService serviceRx;
  late BluetoothCharacteristic characteristicTx;
  late BluetoothCharacteristic characteristicRx;
  final mtu = 512;
  RxString ppg = "0".obs; 
  RxString eda = "0".obs; 



  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future scan() async {
    // Start scanning
  await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
// Stop scanning
  await FlutterBluePlus.stopScan();
  }


  Future<bool> connectDevice()async {
    try {
      await connectedDevice.connect();
    return true;    
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> setCharacteristics()async {
    print("getting chars");
    services = await connectedDevice.discoverServices();
    try {
      serviceTx = services.firstWhere(
                                (service) => service.serviceUuid.toString() == ServiceUuidTx,
                                 // Return null if no matching object is found
                              );
     serviceRx = services.firstWhere(
                                (service) => service.serviceUuid.toString() == ServiceUuidRx,
                                 // Return null if no matching object is found
                              );
       characteristicTx = serviceTx.characteristics.firstWhere(
                      (characteristic) => characteristic.properties.write ,
          );
          for (BluetoothCharacteristic characteristic in serviceRx.characteristics) {
                                // Compare the UUID of the current characteristic with the target UUID
                              if (characteristic.uuid.toString() == characteristicUuidRx) {
                                  // Found the target characteristic
                                  // Now you can use 'characteristic' for your desired operations
                               characteristicRx = characteristic;
                              break; // Optionally, you can break out of the loop if you only need one characteristic
                              }
                              }
    } catch (e) {
      print('there is an error ${e}');
    }
     
  }
  Future<void> writeSyncDate() async {
      print('writing down');
      final mtu = await connectedDevice.mtu.first;
      await connectedDevice.requestMtu(512);
      await characteristicTx.write(utf8.encode(getDate()));
  }

  Future<void> readIncomingData() async {
    String responseData = "";
    print("reading from char");
    await characteristicRx.setNotifyValue(true);
                              characteristicRx.lastValueStream.listen((value) {
                                final decoded = utf8.decode(value);
                                print("decoded decoded Data $decoded");
            //dataParser(decoded);
                                if (decoded.contains("--start--")) {
                                 responseData = decoded;
                                } else {
                                 responseData = responseData + decoded;
            }
                              print("decoded all Data $responseData");
                              if (responseData.contains("--end--")) {
                                Map<String,dynamic> data = extractData(responseData);
                                if (data['data'].containsKey('PPG')) {
                                print('PPG key found! ${data['data']['PPG']['heart_rate'].runtimeType}');
                                ppg.value=data['data']['PPG']['heart_rate'];
                                }
                                if (data['data'].containsKey('EDA')) {
                                print('EDA key found! ${data['data']['EDA'][0]['EDA'].runtimeType}');
                                eda.value=data['data']['EDA'][0]['EDA'];
                                }
                              }});
  }

  Map<String, dynamic> extractData(String data){
    String jsonString = data.replaceAll("--start--", "").replaceAll("--end--", "");
    var jsonObject = jsonDecode(jsonString);
    return jsonObject;
  }

  String getDate(){
    print("getting date");
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    String jsonString = "*#{\"request\":\"date_time\",\"action\":\"SET\",\"value\":{\"date\":\"${formattedDate}\",\"time\":\"${formattedTime}\"}}#*";
    return jsonString;
  }
}