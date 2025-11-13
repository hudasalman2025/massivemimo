import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<double> mrcIn = [];
  List<double> mrcOp = [];
  List<double> mrtIn = [];
  List<double> mrtOp = [];

  // نحاكي شكل المنحنيات (مش محاكاة فيزيائية 100% لكن قريبة من MATLAB)
  void calculateData(int maxM) {
    M.clear();
    mrcIn.clear();
    mrcOp.clear();
    mrtIn.clear();
    mrtOp.clear();

    // نختار قيم M متباعدة حتى المؤشرات تكون متباعدة وواضحة
    for (int i = 50; i <= maxM; i += 50) {
      double Mval = i.toDouble();
      M.add(Mval);

      // base = 3.2 * ln(M) يعطي منحنى صاعد مع عدد الهوائيات
      double base = 3.2 * log(Mval);

      // نفصل المنحنيات عن بعضها بمساحات كبيرة
      mrcIn.add(base + 10);   // 🔵 الأعلى
      mrcOp.add(base + 4);    // 🔴 تحته
      mrtIn.add(base - 2);    // 🟣 تحتهم
      mrtOp.add(base - 7);    // ⚫ أسفل واحد
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SINR Simulation (MATLAB style)")),
      body: GestureDetector(
        // حتى إذا ضغطت خارج الـ TextField يختفي الكيبورد
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "أدخل العدد الأقصى للهوائيات (M):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "مثال: 400",
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () {
                  final v = int.tryParse(_controller.text);
                  if (v != null && v >= 50) {
                    calculateData(v);
                  }
                },
                child: const Text("ابدأ المحاكاة"),
              ),

              const SizedBox(height: 20),

              if (M.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("أدخل قيمة ثم اضغط ابدأ المحاكاة"),
                  ),
                ),

              if (M.isNotEmpty) ...[
                // 🎨 الرسم داخل SizedBox فقط (بدون Expanded) حتى ما يصير Overflow
                SizedBox(
                  height: 350,
                  child: LineChart(
                    LineChartData(
                      minX: 50,
                      maxX: M.last,
                      minY: -0,
                      maxY: null,
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text("Number of Antennas (M)"),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text("SINR (dB)"),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      lineBarsData: [
                        // 🔵 MRCin
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrcIn[i]),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // 🔴 MRCop
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrcOp[i]),
                          ),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // 🟣 MRTin
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrtIn[i]),
                          ),
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),

                        // ⚫ MRTopt
                        LineChartBarData(
                          spots: List.generate(
                            M.length,
                                (i) => FlSpot(M[i], mrtOp[i]),
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

                const SizedBox(height: 20),

                // 🔍 عنوان صغير فوق الشرح
                const Text(
                  "Detailed explanation of the process:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // 📄 شرح تفصيلي بالإنكليزي + توضيح بالعربي
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    """
1️⃣ Step 1: Choose the maximum number of antennas (M_max)
--------------------------------------------------------
You enter a value like M_max = 400.
The code generates M = 50, 100, 150, ..., M_max.
These are the points on the x-axis (number of antennas).


2️⃣ Step 2: Basic SINR growth with M
------------------------------------
For each M, we compute a base value:

    base(M) = 3.2 · ln(M)

This mimics the theoretical behavior:
when M increases → the array gain increases → SINR grows roughly like log(M).


3️⃣ Step 3: Building 4 different curves
---------------------------------------

We construct 4 SINR curves, each one shifted to separate them visually:

    MRCin  = base(M) + 10   (blue)   → initial MRC receive link
    MRCop  = base(M) +  4   (red)    → MRC after power optimization
    MRTin  = base(M) -  2   (purple) → initial MRT transmit link
    MRTopt = base(M) -  7   (black)  → MRT in another operating point

So all curves have the same general trend (increasing with M),
but they are vertically separated so you can clearly see them.


4️⃣ Step 4: Relation with the theoretical SINR formula
------------------------------------------------------

In theory, the SINR for user n can be written as:

    δ_n = ( P_d · ||h_n||² ) / ( I_n + 1 )

where:
    • P_d  = data power
    • h_n  = channel vector for user n
    • I_n  = interference plus noise term
    • 1    = normalized noise power

And in dB:

    SINR_dB = 10 · log10( δ_n )

In our simple Flutter demo we do NOT simulate the full random channels.
Instead, we emulate the overall behavior (growth with M) using:

    SINR(M) ~ A · ln(M) + B

This keeps the figure simple and stable on mobile, while still reflecting that:
more antennas → higher SINR.


5️⃣ Interpretation of the four curves
-------------------------------------

• MRCin  (blue):
  SINR for the MRC receiver before any power optimization.

• MRCop  (red):
  Same MRC scheme but with better power allocation (optimized),
  so it is slightly lower than MRCin in this toy example, but you can shift it as you wish.

• MRTin  (purple):
  MRT transmit beamforming with some initial power configuration.

• MRTopt (black):
  Another MRT configuration, can represent a different constraint or scenario.

📌 In your real MATLAB model:
You can replace our simple base(M) by the exact formula you derived
from your Massive MIMO / relay system, and then just plot the resulting SINR
for each algorithm (MRC, MRT, etc.) versus M.

""",
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
