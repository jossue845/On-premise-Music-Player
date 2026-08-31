import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player_app/data/services/database_service.dart';

class ListeningHabitsScreen extends StatefulWidget {
  final DatabaseService? testDatabaseService; 

  const ListeningHabitsScreen({super.key, this.testDatabaseService});
  @override
  State<ListeningHabitsScreen> createState() => _ListeningHabitsScreenState();
}

class _ListeningHabitsScreenState extends State<ListeningHabitsScreen> {
  late DatabaseService _databaseService;
  bool _isLoading = true;
  final Map<String, int> _heatmapData = {};
  
  String _topDay = 'Loading...';
  String _peakTime = 'Loading...';
  String _formattedTime = '0m 0s';

  @override
  void initState() {
    super.initState();
    _databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = _databaseService;
    if (!db.isOpen()) await db.open();

    // 1. Fetch Heatmap Grid Data
    final heatmapResult = await db.getHeatmapData();
    if (heatmapResult.isSuccess()) {
      final data = heatmapResult.getOrThrow();
      for (var row in data) {
        final int sqliteDay = row['day_index'] as int;
        final int hour = row['hour_index'] as int;
        final int day = sqliteDay == 0 ? 6 : sqliteDay - 1;
        _heatmapData['$day-$hour'] = row['play_count'] as int;
      }
    }

    // 2. Fetch Peak Time & Top Day
    final habitsResult = await db.getListeningHabits();
    if (habitsResult.isSuccess()) {
      final data = habitsResult.getOrThrow();
      _topDay = data['topDay'] ?? 'Not enough data';
      _peakTime = data['peakTime'] ?? 'Not enough data';
    } else {
      _topDay = 'Not enough data';
      _peakTime = 'Not enough data';
    }

    // 3. Fetch Lifetime Total Time
    final timeResult = await db.getValue('total_time_listened');
    if (timeResult.isSuccess()) {
      final seconds = int.tryParse(timeResult.getOrThrow()) ?? 0;
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (hours > 0) {
        _formattedTime = '${hours}h ${minutes}m';
      } else {
        _formattedTime = '${minutes}m ${seconds % 60}s';
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                value, 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    // --- FIX: Detect screen orientation ---
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Habits'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Align(
            // --- FIX: Center in portrait, top-left in landscape ---
            alignment: isPortrait ? Alignment.topCenter : Alignment.topLeft,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // --- FIX: Align children dynamically ---
                crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Y-Axis: Hours
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24), 
                                  ...List.generate(24, (hour) {
                                    final bool showLabel = hour % 4 == 0;
                                    final String label = hour == 0 ? '12 AM' : (hour < 12 ? '$hour AM' : (hour == 12 ? '12 PM' : '${hour - 12} PM'));
                                    
                                    return Container(
                                      height: 20,
                                      margin: const EdgeInsets.only(bottom: 4.0),
                                      alignment: Alignment.centerRight,
                                      width: 45,
                                      child: Text(
                                        showLabel ? label : '',
                                        style: const TextStyle(fontSize: 10, color: Colors.white60),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(width: 12),
                              
                              // X-Axis & Grid: Days and Heatmap Cells
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(7, (dayIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 20,
                                          alignment: Alignment.center,
                                          child: Text(
                                            dayLabels[dayIndex], 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        
                                        ...List.generate(24, (hourIndex) {
                                          final count = _heatmapData['$dayIndex-$hourIndex'] ?? 0;
                                          
                                          double intensity = (count * 3.5) / 60.0;
                                          intensity = intensity.clamp(0.0, 1.0);
                                          
                                          if (count > 0 && intensity < 0.2) intensity = 0.2;

                                          return Container(
                                            height: 20,
                                            width: 22,
                                            margin: const EdgeInsets.only(bottom: 4.0),
                                            decoration: BoxDecoration(
                                              color: count == 0 
                                                  ? const Color(0xFF1F2E54) 
                                                  : Theme.of(context).primaryColor.withOpacity(intensity),
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Summary Statistics Section
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      // --- FIX: Align summary text dynamically ---
                      crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        const Text('Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16.0,
                          runSpacing: 16.0,
                          // --- FIX: Center the wrapped cards in portrait mode ---
                          alignment: isPortrait ? WrapAlignment.center : WrapAlignment.start,
                          children: [
                            _buildStatCard(context, 'Peak Time', _peakTime, Icons.access_time),
                            _buildStatCard(context, 'Top Day', _topDay, Icons.calendar_today),
                            _buildStatCard(context, 'Lifetime', _formattedTime, Icons.timer),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
    );
  }
}