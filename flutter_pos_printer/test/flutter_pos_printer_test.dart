// import 'package:flutter/services.dart';
// import 'package:flutter_pos_printer/flutter_pos_printer.dart';
// import 'package:flutter_pos_printer/src/printers/backend.dart';
// import 'package:flutter_test/flutter_test.dart';

// void main() {
//   const MethodChannel channel = MethodChannel('flutter_pos_printer');

//   TestWidgetsFlutterBinding.ensureInitialized();

//   VirtualPrinter? printer1;
  
//   setUp(() {
//     channel.setMockMethodCallHandler((MethodCall methodCall) async {
//       return '42';
//     });
//   });

//   tearDown(() async {
//     channel.setMockMethodCallHandler(null);
//   });

//   test("initialize printer", () async {
//     printer1 = VirtualPrinter(
//         driver: PrinterDriver.Network,
//         type: PrinterType.ESCPOS,
//         endpoint: "192.168.0.1");
//     expect(VirtualPrinter.dictionary.length, 1);
//   });

//   test("retrieve Printer", () async {
//     expect(printer1?.printer, isNot(null));
//   });
  
//   test("dispose printer", () async {
//     await printer1?.dispose();
//     expect(VirtualPrinter.dictionary.length, lessThan(1));
//   });
// }
