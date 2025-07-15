import 'package:flutter/material.dart';
import 'package:flutter_sqlite_auth_app/Views/emg_curve.dart';
import 'package:flutter_sqlite_auth_app/Views/signal_curve.dart';
import 'package:flutter_sqlite_auth_app/provider/stm32_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stmProvider = Provider.of<STM32Provider>(context);

    Map<String, dynamic> parsedSTM2 = {};
    try {
      parsedSTM2 = jsonDecode(stmProvider.latestDataSTM2);
    } catch (_) {}

    final emgData = [
      {
        "Parameter": "EMG 1",
        "Value": stmProvider.emg1History.isEmpty
            ? "0"
            : stmProvider.emg1History.last.toString()
      },
      {
        "Parameter": "EMG 2",
        "Value": stmProvider.emg2History.isEmpty
            ? "0"
            : stmProvider.emg2History.last.toString()
      },
      {
        "Parameter": "EMG 3",
        "Value": stmProvider.emg3History.isEmpty
            ? "0"
            : stmProvider.emg3History.last.toString()
      },
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.show_chart),
          tooltip: 'Show EMG Curve',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EmgChartPage()),
            );
          },
        ),
        automaticallyImplyLeading: false,
        title: const Text('Monitoring Data'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Show Signal Curve',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SignalCurvePage()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Half - EMG Table (STM1)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildEmgTable(emgData),
            ),
          ),

          // Right Half - STM2 Data Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildJsonTable(parsedSTM2),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmgTable(List<Map<String, dynamic>> emgData) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            color: Colors.blue,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "EMG Data",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text('Parameter')),
              DataColumn(label: Text('Value')),
            ],
            rows: emgData
                .map(
                  (data) => DataRow(
                    cells: [
                      DataCell(Text(data['Parameter'].toString())),
                      DataCell(Text(data['Value'].toString())),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget buildJsonTable(Map<String, dynamic> stmsData) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            color: Colors.green,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Signal Data",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: stmsData.isEmpty
                ? const Center(child: Text("Waiting for STM32 Data..."))
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Parameter')),
                        DataColumn(label: Text('Value')),
                      ],
                      rows: stmsData.entries
                          .map(
                            (entry) => DataRow(
                              cells: [
                                DataCell(Text(entry.key)),
                                DataCell(Text(entry.value.toString())),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
