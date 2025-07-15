import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sqlite_auth_app/SQLite/store_data.dart';

class FullDataPage extends StatefulWidget {
  const FullDataPage({super.key});

  @override
  State<FullDataPage> createState() => _FullDataPageState();
}

class _FullDataPageState extends State<FullDataPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _readings = [];
  final int _pageSize = 20;

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  String _selectedDevice = 'STM1'; // ✅ default device

  @override
  void initState() {
    super.initState();
    _loadNextPage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _loadNextPage();
      }
    });
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoading = true);

    final dbService = DatabaseService();
    final newData = await dbService.getReadingsByPage(
      page: _currentPage,
      pageSize: _pageSize,
      device: _selectedDevice,
    );

    setState(() {
      _readings.addAll(newData);
      _isLoading = false;
      _hasMore = newData.length == _pageSize;
      _currentPage++;
    });
  }

  void _reloadData() {
    setState(() {
      _readings.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    _loadNextPage();
  }

  Map<String, List<Map<String, dynamic>>> _groupReadingsByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var reading in _readings) {
      final fullTimestamp = reading['timestamp'] ?? '';
      final dateOnly = fullTimestamp.split(' ').first;

      grouped.putIfAbsent(dateOnly, () => []).add(reading);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    final String timestamp = reading['timestamp'] ?? '';
    final rawJson = reading['json_data'] ?? '{}';
    Map<String, dynamic> parsedJson = {};

    try {
      parsedJson = json.decode(rawJson);
    } catch (_) {
      parsedJson = {'raw': rawJson};
    }

    final Color color = _selectedDevice == 'STM1' ? Colors.green : Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("⏰ Time: ${timestamp.split(' ').last}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("💻 Device: $_selectedDevice", style: TextStyle(color: color)),
          const SizedBox(height: 4),
          const Text("📦", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...parsedJson.entries.map((entry) {
            return Text("${entry.key}: ${entry.value}");
          }),
          if (parsedJson.isEmpty)
            const Text("No data",
                style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupReadingsByDate();

    return Scaffold(
      appBar: AppBar(
        title: Text("📄 Page: $_currentPage ($_selectedDevice)"),
        actions: [
          DropdownButton<String>(
            value: _selectedDevice,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDevice = value;
                });
                _reloadData();
              }
            },
            items: const [
              DropdownMenuItem(value: 'STM1', child: Text('STM1')),
              DropdownMenuItem(value: 'STM2', child: Text('STM2')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export $_selectedDevice to CSV',
            onPressed: () async {
              final dbService = DatabaseService();
              final path = await dbService.exportToCSV(_selectedDevice);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Exported to: $path')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete $_selectedDevice Readings",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Are you sure?"),
                  content: Text(
                      "This will permanently delete all $_selectedDevice data."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Delete All"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final dbService = DatabaseService();
                if (_selectedDevice == 'STM1') {
                  await dbService.clearAllReadingsSTM1();
                } else {
                  await dbService.clearAllReadingsSTM2();
                }

                _reloadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ $_selectedDevice data deleted")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.amber.withOpacity(0.2),
            padding: const EdgeInsets.all(8),
            child: const Text(
              "📦 These are stored readings. STM32 connection is not required.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                for (var entry in groupedData.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      "📅 ${entry.key}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  ...entry.value.map(_buildReadingCard).toList(),
                ],
                if (_hasMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
