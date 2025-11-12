// 📘 استيراد المكتبات
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  List<double> M = [];
  List<double> sinrInit = [];
  List<double> sinrOpt = [];
  String explanation = '';

  final double Ps = 10.0;
  final double Pr = 10.0;
  final int N = 5;
  static const double ln2 = 0.69314718056;

  double safe(double x) {
    if (x.isNaN || x.isInfinite || x < 0) return 0;
    return x;
  }

  void calculateData(int maxM) {
    M.clear();
    sinrInit.clear();
    sinrOpt.clear();

    for (int i = 50; i <= maxM; i += 25) {
      M.add(i.toDouble());
      double hsn = 0.001 * i;

      List<double> Psi = [0.6, 0.8, 1.0, 0.9, 0.7];
      List<double> Hsi = [1.1, 0.95, 1.0, 1.05, 1.2];

      double anp = Ps * pow(hsn, 4);
      double sum1 = 0, sum2 = 0;

      for (int k = 0; k < N; k++) {
        if (k != 0) sum1 += Psi[k] * pow(hsn * Hsi[k], 2);
        sum2 += Psi[k] * pow(hsn * Hsi[k], 2);
      }

      double bnp = sum1 + sum2 + pow(hsn, 2);
      double deltaOld = anp / bnp;
      double deltaNew = deltaOld * 1.3;

      sinrInit.add(safe(10 * log(deltaOld) / ln2));
      sinrOpt.add(safe(10 * log(deltaNew) / ln2));
    }

    double improvement = sinrOpt.last - sinrInit.first;

    explanation = '''
📘 Simulation Summary
--------------------------------
• Transmit Power (Ps) = $Ps
• Receive Power (Pr) = $Pr
• Number of Channels (N) = $N
• Power Optimization = 30%

The simulation shows that increasing the number of antennas (M)
leads to higher SINR values, indicating better signal quality.

Overall improvement ≈ ${improvement.toStringAsFixed(2)} dB
--------------------------------
''';

    setState(() {});
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('SINR Simulation Report',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text(explanation, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Center(
                  child: pw.Text(
                      'Graphical Representation of SINR vs Antennas',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 200,
                child: pw.Center(
                    child: pw.Text('[Graph Image Placeholder]',
                        style: const pw.TextStyle(color: PdfColors.grey))),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Numerical Results:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Table.fromTextArray(
                headers: ['M', 'Initial SINR (dB)', 'Optimized SINR (dB)'],
                data: List.generate(
                  M.length,
                      (i) => [
                    M[i].toStringAsFixed(0),
                    sinrInit[i].toStringAsFixed(2),
                    sinrOpt[i].toStringAsFixed(2),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      return pdf.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SINR Simulation & Report')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Enter Max Number of Antennas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'e.g. 400',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(_controller.text);
                if (value != null && value > 50) {
                  calculateData(value);
                }
              },
              child: const Text('Calculate & Show Chart'),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: M.isEmpty
                  ? const Center(child: Text('Enter value then press Calculate'))
                  : Column(
                children: [
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: 10,
                        maxY: 24,
                        minX: 50,
                        maxX: M.last,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            axisNameWidget:
                            const Text('Number of Antennas (M)'),
                            sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text('SINR (dB)'),
                            sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              M.length,
                                  (i) => FlSpot(M[i], sinrInit[i]),
                            ),
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 3,
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              M.length,
                                  (i) => FlSpot(M[i], sinrOpt[i]),
                            ),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Report (A4 PDF)'),
                    onPressed: _printPdf,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
