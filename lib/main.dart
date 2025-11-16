import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// PDF & Printing
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// Screenshot
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SinrChartScreen(),
  ));
}

class SinrChartScreen extends StatefulWidget {
  const SinrChartScreen({super.key});

  @override
  State<SinrChartScreen> createState() => _SinrChartScreenState();
}

class _SinrChartScreenState extends State<SinrChartScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey chartKey = GlobalKey();

  List<double> M = [];
  List<double> mrcInput = [];
  List<double> mrtInput = [];
  List<double> mrcOutput = [];
  List<double> mrtOutput = [];

  // IP الطابعة
  final printerIP = "192.168.1.150";

  // حساب البيانات
  void calculateData(int maxM) {
    M.clear();
    mrcInput.clear();
    mrtInput.clear();
    mrcOutput.clear();
    mrtOutput.clear();

    // نقطة البداية عند الصفر
    M.add(0);
    mrcInput.add(0);
    mrtInput.add(0);
    mrcOutput.add(0);
    mrtOutput.add(0);

    for (int i = 50; i <= maxM; i += 50) {
      final Mval = i.toDouble();
      M.add(Mval);

      double base = 3.2 * log(Mval);

      double A = base + 10; // MRC Input
      double B = base - 2;  // MRT Input
      double C = base + 4;  // MRC Output
      double D = base - 7;  // MRT Output

      mrcInput.add(A);
      mrtInput.add(B + 0.4); // فرق بصري بسيط
      mrcOutput.add(C);
      mrtOutput.add(D + 0.4);
    }

    setState(() {});
  }

  // تصوير الرسم
  Future<Uint8List?> _captureChart() async {
    RenderRepaintBoundary boundary =
    chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // طباعة PDF
  Future<void> _printPDF() async {
    if (M.isEmpty) return;

    Uint8List? chartBytes = await _captureChart();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text("SINR Simulation Results", style: pw.TextStyle(fontSize: 22)),
          pw.SizedBox(height: 10),

          pw.Text("M values: ${M.join(', ')}"),
          pw.SizedBox(height: 10),

          pw.Text("MRC Input  (blue) : ${mrcInput.join(', ')}"),
          pw.Text("MRT Input  (green): ${mrtInput.join(', ')}"),
          pw.Text("MRC Output (red)  : ${mrcOutput.join(', ')}"),
          pw.Text("MRT Output (black): ${mrtOutput.join(', ')}"),

          pw.SizedBox(height: 15),

          pw.Text("Chart:", style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 10),

          if (chartBytes != null)
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(chartBytes),
                width: 300,
              ),
            ),

          pw.SizedBox(height: 20),

          pw.Text(
            """
UL-MRC SINR (استلام):
SINR_UL_n = ( P_u · ||h_n||^4 )
            -----------------------------------------------
            ( Σ_{i≠n} P_u |h_n^H h_i|^2  +  σ^2 )


DL-MRT SINR (ارسال):
SINR_DL_n = ( P_d · ||ĥ_sn||^4 )
            -----------------------------------------------
            ( Σ_{i≠n} P_d |ĥ_sn^H ĥ_si|^2 
              + Σ_{j=1}^N P_d |ĥ_sn^H h̅_sj|^2 
              +  σ^2 )


النموذج المبسط المستخدم للرسم:

base(M) = 3.2 * ln(M)

MRC Input  = base + 10  
MRT Input  = base - 2  
MRC Output = base + 4  
MRT Output = base - 7  
""",
            style: pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // طباعة مباشرة عبر WiFi RAW
  Future<void> _directWiFiPrint() async {
    try {
      Uint8List? data = await _captureChart();
      if (data == null) return;

      final socket = await Socket.connect(printerIP, 9100);
      socket.add(data);
      socket.add("\n\nPrinted via Flutter WiFi RAW\n\n".codeUnits);
      await socket.flush();
      await socket.close();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت الطباعة عبر الواي فاي")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل الاتصال بالطابعة: $e")),
      );
    }
  }

  // عنصر صغير لمفتاح الألوان
  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SINR Simulation (4-Line MRC/MRT)"),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: _printPDF),
          IconButton(icon: const Icon(Icons.wifi), onPressed: _directWiFiPrint),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "العدد الأقصى للهوائيات M",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                final v = int.tryParse(_controller.text);
                if (v != null && v >= 50) calculateData(v);
              },
              child: const Text("ابدأ المحاكاة"),
            ),

            const SizedBox(height: 20),

            if (M.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(child: Text("أدخل قيمة ثم اضغط ابدأ")),
              ),

            if (M.isNotEmpty) ...[
              // الرسم
              RepaintBoundary(
                key: chartKey,
                child: SizedBox(
                  height: 350,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: M.last,
                      minY: 0,
                      maxY: mrcInput.reduce(max) + 5,

                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),

                      lineBarsData: [
                        // 🔵 MRC Input
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrcInput[i]),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // 🟢 MRT Input
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrtInput[i]),
                          ),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // 🔴 MRC Output
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrcOutput[i]),
                          ),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // ⚫ MRT Output
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrtOutput[i]),
                          ),
                          isCurved: true,
                          color: Colors.black,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔍 مفتاح الألوان (Legend)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _legendItem(Colors.blue,  "MRC Input"),
                    _legendItem(Colors.green, "MRT Input"),
                    _legendItem(Colors.red,   "MRC Output"),
                    _legendItem(Colors.black, "MRT Output"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 📘 الشرح الرياضي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  """
📘 **الشرح الرياضي الكامل (MRC – Uplink) و (MRT – Downlink)**

ألوان المنحنيات:
• 🔵 أزرق  = MRC Input (استلام مبدئي)  
• 🟢 أخضر = MRT Input (إرسال مبدئي)  
• 🔴 أحمر  = MRC Output (بعد تحسين/معالجة)  
• ⚫ أسود  = MRT Output (بعد تحسين/معالجة)  

أولاً: معادلة الاستلام (Uplink – MRC)
-------------------------------------
SINR_UL_n = ( P_u · ||h_n||^4 )
            -----------------------------------------------
            ( Σ_{i≠n} P_u |h_n^H h_i|^2  +  σ^2 )


ثانياً: معادلة الإرسال (Downlink – MRT)
----------------------------------------
SINR_DL_n = ( P_d · ||ĥ_sn||^4 )
            -----------------------------------------------
            ( Σ_{i≠n} P_d |ĥ_sn^H ĥ_si|^2 
              + Σ_{j=1}^N P_d |ĥ_sn^H h̅_sj|^2 
              +  σ^2 )


النموذج المبسط المستخدم للرسم:
-------------------------------
base(M) = 3.2 * ln(M)

MRC Input  = base + 10  
MRT Input  = base - 2  
MRC Output = base + 4  
MRT Output = base - 7  

مع إضافة فرق بصري بسيط (±0.4) لجعل الخطوط مفصولة وواضحة مع زيادة عدد الهوائيات M.
                  """,
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
