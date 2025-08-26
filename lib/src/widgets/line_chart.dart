import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class LineCharts extends StatelessWidget {
  const LineCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: const Color(0xff37434d), strokeWidth: 0.5),
              getDrawingVerticalLine: (value) =>
                  FlLine(color: const Color(0xff37434d), strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: 7,
            minY: 0,
            maxY: 6,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 1),
                  FlSpot(1, 3),
                  FlSpot(2, 1),
                  FlSpot(3, 4),
                  FlSpot(4, 2),
                  FlSpot(5, 5),
                  FlSpot(6, 3),
                ],
                isCurved: true,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
                dotData: FlDotData(show: false),
              ),
              LineChartBarData(
                spots: [
                  FlSpot(0, 2),
                  FlSpot(1, 2.5),
                  FlSpot(2, 1.5),
                  FlSpot(3, 3),
                  FlSpot(4, 1),
                  FlSpot(5, 4),
                  FlSpot(6, 2),
                ],
                isCurved: true,
                color: Colors.red,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withValues(alpha: 0.3),
                ),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarChartSample extends StatelessWidget {
  const BarChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 50000,
          barGroups: [
            makeGroupData(0, 30000, 20000, context),
            makeGroupData(1, 40000, 15000, context),
            makeGroupData(2, 35000, 25000, context),
            makeGroupData(3, 45000, 30000, context),
            makeGroupData(4, 20000, 10000, context),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 10000 == 0) {
                    return Text('${value ~/ 1000}k');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                  if (value.toInt() < months.length) {
                    return Text(months[value.toInt()]);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: const Color(0xff37434d), width: 1),
              bottom: BorderSide(color: const Color(0xff37434d), width: 1),
              right: BorderSide.none,
              top: BorderSide.none,
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
          ),
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double income,
    double expense,
    BuildContext context,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: income,
          color: context.primaryColor,
          width: 10,
          borderRadius: BorderRadius.circular(0),
        ),
        BarChartRodData(
          toY: expense,
          color: Colors.indigo,
          width: 10,
          borderRadius: BorderRadius.circular(0),
        ),
      ],
      barsSpace: 0,
    );
  }
}
