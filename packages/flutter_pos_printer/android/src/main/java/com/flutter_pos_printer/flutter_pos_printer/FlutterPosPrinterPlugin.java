package com.flutter_pos_printer.flutter_pos_printer;

import android.hardware.usb.UsbDevice;
import android.content.Context;
import com.flutter_pos_printer.flutter_pos_printer.adapter.USBPrinterAdapter;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterPosPrinterPlugin */
public class FlutterPosPrinterPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context;

  private static USBPrinterAdapter adapter;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_pos_printer");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
    adapter = USBPrinterAdapter.getInstance();
    adapter.init(context);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getList")) {
      getUSBDeviceList(result);
    } else if (call.method.equals("connectPrinter")) {
      Integer vendor = call.argument("vendor");
      Integer product = call.argument("product");
      connectPrinter(vendor, product, result);
    } else if (call.method.equals("close")) {
      closeConn(result);
    } else if (call.method.equals("printText")) {
      String text = call.argument("text");
      printText(text, result);
    } else if (call.method.equals("printRawData")) {
      String raw = call.argument("raw");
      printRawData(raw, result);
    } else if (call.method.equals("printBytes")) {
      ArrayList<Integer> bytes = call.argument("bytes");
      printBytes(bytes, result);
    } else {
      result.notImplemented();
    }
  }

  public void getUSBDeviceList(Result result) {
    List<UsbDevice> usbDevices = adapter.getDeviceList();
    ArrayList<HashMap> list = new ArrayList<HashMap>();
    for (UsbDevice usbDevice : usbDevices) {
      HashMap<String, String> deviceMap = new HashMap();
      deviceMap.put("name", usbDevice.getDeviceName());
      deviceMap.put("manufacturer", usbDevice.getManufacturerName());
      deviceMap.put("product", usbDevice.getProductName());
      deviceMap.put("deviceId", Integer.toString(usbDevice.getDeviceId()));
      deviceMap.put("vendorId", Integer.toString(usbDevice.getVendorId()));
      deviceMap.put("productId", Integer.toString(usbDevice.getProductId()));
      list.add(deviceMap);
    }
    result.success(list);
  }

  public void connectPrinter(Integer vendorId, Integer productId, Result result) {
    if (!adapter.selectDevice(vendorId, productId)) {
      result.success(false);
    } else {
      result.success(true);
    }
  }

  public void closeConn(Result result) {
    adapter.closeConnection();
    result.success(true);
  }

  public void printText(String text, Result result) {
    adapter.printText(text);
    result.success(true);
  }

  public void printRawData(String base64Data, Result result) {
    adapter.printRawData(base64Data);
    result.success(true);
  }

  public void printBytes(ArrayList<Integer> bytes, Result result) {
    adapter.printBytes(bytes);
    result.success(true);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
