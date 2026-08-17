import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player_app/data/services/database_service.dart';

class ListeningHabitsScreen extends StatefulWidget {
  const ListeningHabitsScreen({super.key});

  @override
  State<ListeningHabitsScreen> createState() => _ListeningHabitsScreenState();
}

class _ListeningHabitsScreenState extends State<ListeningHabitsScreen> {
  bool _isLoading = true;
  final Map<String, int> _heatmapData = {};

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    final db = DatabaseService(databaseFactory: databaseFactory);
    if (!db.isOpen()) await db.open();

    final result = await db.getHeatmapData();
    
    if (result.isSuccess()) {
      final data = result.getOrThrow();
      
      for (var row in data) {
        final int sqliteDay = row['day_index'] as int;
        final int hour = row['hour_index'] as int;
        
        // Convert SQLite day (0 = Sun, 1 = Mon) to standard (0 = Mon, 6 = Sun)
        final int day = sqliteDay == 0 ? 6 : sqliteDay - 1;
        
        _heatmapData['$day-$hour'] = row['play_count'] as int;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Habits'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Y-Axis: Hours
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24), // Offset for the Day labels row
                        ...List.generate(24, (hour) {
                          // Only show labels every 4 hours to keep it clean
                          final bool showLabel = hour % 4 == 0;
                          final String label = hour == 0 ? '12 AM' : (hour < 12 ? '$hour AM' : (hour == 12 ? '12 PM' : '${hour - 12} PM'));
                          
                          return Container(
                            height: 18,
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
                    const SizedBox(width: 8),
                    
                    // X-Axis & Grid: Days and Heatmap Cells
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (dayIndex) {
                          return Column(
                            children: [
                              // Day Label
                              Container(
                                height: 20,
                                alignment: Alignment.center,
                                child: Text(
                                  dayLabels[dayIndex], 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // 24 Hour Cells for this day
                              ...List.generate(24, (hourIndex) {
                                final count = _heatmapData['$dayIndex-$hourIndex'] ?? 0;
                                
                                // Estimate intensity: assume ~3.5 mins per track
                                // 60 mins = 1.0 opacity
                                double intensity = (count * 3.5) / 60.0;
                                intensity = intensity.clamp(0.0, 1.0);
                                
                                // Give a slight baseline opacity so 1-track hours are still visible
                                if (count > 0 && intensity < 0.2) intensity = 0.2;

                                return Container(
                                  height: 18,
                                  width: 18,
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  decoration: BoxDecoration(
                                    color: count == 0 
                                        ? const Color(0xFF1F2E54) // Empty slot color
                                        : Theme.of(context).primaryColor.withOpacity(intensity),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}