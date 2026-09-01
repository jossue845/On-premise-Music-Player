import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart'; 
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  final DatabaseService? testDatabaseService;

  const EqualizerScreen({super.key, this.testDatabaseService});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  late DatabaseService _databaseService;

  AndroidEqualizerParameters? _eqParams;
  List<double> _bandValues = [];
  double _preampValue = 1.0; 
  List<Map<String, dynamic>> _presets = []; 

  String _activeMenu = 'Equalizer';
  double _pitchValue = 1.0; 

  @override
  void initState() {
    super.initState();
    _databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _preampValue = ref.read(audioPlayerProvider).volume;
    _initEqualizer();
    _loadPresets();
  }

  Future<void> _initEqualizer() async {
    try {
      final equalizer = ref.read(equalizerProvider);
      if (!equalizer.enabled) {
        await equalizer.setEnabled(true);
      }

      final params = await equalizer.parameters;
      if (mounted) {
        setState(() {
          _eqParams = params;
          if (params != null) {
            _bandValues = params.bands.map((b) => b.gain).toList();
          } else {
             // Safe fallback for testing when native bands are unavailable
            _bandValues = List.filled(5, 0.0);
          }
        });
      }
    } catch (e) {
      debugPrint("Failed to initialize Equalizer: $e");
      // Fallback state for tests to prevent null access errors on slider render
      if (mounted) {
        setState(() => _bandValues = List.filled(5, 0.0));
      }
    }
  }

  Future<void> _loadPresets() async {
    try {
      if (!_databaseService.isOpen()) await _databaseService.open();
      
      final result = await _databaseService.getValue('eq_presets');
      if (result.isSuccess()) {
        final jsonString = result.getOrThrow();
        if (jsonString.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(jsonString);
          if (mounted) {
            setState(() {
              _presets = List<Map<String, dynamic>>.from(decoded);
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _savePresetsToDB() async {
    try {
      if (!_databaseService.isOpen()) await _databaseService.open();
      final jsonString = jsonEncode(_presets);
      await _databaseService.insertKVPair('eq_presets', jsonString);
    } catch (e) {
      debugPrint("Failed to save presets: $e");
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _preampValue = preset['preamp'] ?? 1.0;
      ref.read(audioPlayerProvider).setVolume(_preampValue);

      if (_eqParams != null) {
        final List<dynamic> savedBands = preset['bands'] ?? [];
        for (int i = 0; i < _bandValues.length && i < savedBands.length; i++) {
          _bandValues[i] = savedBands[i];
          _eqParams!.bands[i].setGain(savedBands[i]);
        }
      }
    });
  }

  void _showPresetsSheet() {
    final TextEditingController presetNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.blueGrey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Equalizer Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: presetNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'New preset name...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save, color: Colors.orangeAccent),
                        tooltip: 'Save current configuration',
                        onPressed: () {
                          final name = presetNameController.text.trim();
                          if (name.isNotEmpty) {
                            bool isDuplicate = false;
                            String duplicateMessage = '';

                            for (var preset in _presets) {
                              final String savedName = preset['name'] ?? '';
                              final double savedPreamp = (preset['preamp'] as num?)?.toDouble() ?? 1.0;
                              final List<double> savedBands = (preset['bands'] as List<dynamic>?)
                                      ?.map((e) => (e as num).toDouble())
                                      .toList() ?? [];

                              if (savedName.toLowerCase() == name.toLowerCase()) {
                                isDuplicate = true;
                                duplicateMessage = 'A preset named "$name" already exists.';
                                break;
                              }

                              if ((savedPreamp - _preampValue).abs() > 0.01) continue;
                              if (savedBands.length != _bandValues.length) continue;
                              
                              bool bandsMatch = true;
                              for (int i = 0; i < savedBands.length; i++) {
                                if ((savedBands[i] - _bandValues[i]).abs() > 0.01) {
                                  bandsMatch = false;
                                  break;
                                }
                              }

                              if (bandsMatch) {
                                isDuplicate = true;
                                duplicateMessage = 'This exact configuration is already saved as "$savedName".';
                                break;
                              }
                            }

                            if (isDuplicate) {
                              FocusScope.of(context).unfocus(); 
                              
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    backgroundColor: Colors.blueGrey.shade800,
                                    title: const Text('Duplicate Preset', style: TextStyle(color: Colors.white)),
                                    content: Text(
                                      duplicateMessage,
                                      style: TextStyle(color: Colors.grey.shade300),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('OK', style: TextStyle(color: Colors.orangeAccent)),
                                      ),
                                    ],
                                  );
                                }
                              );
                              return; 
                            }

                            final newPreset = {
                              'name': name,
                              'preamp': _preampValue,
                              'bands': List<double>.from(_bandValues),
                            };
                            
                            setState(() => _presets.add(newPreset));
                            setSheetState(() {}); 
                            _savePresetsToDB();
                            
                            presetNameController.clear();
                            FocusScope.of(context).unfocus(); 
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_presets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No presets saved yet.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _presets.length,
                        itemBuilder: (context, index) {
                          final preset = _presets[index];
                          return ListTile(
                            title: Text(preset['name'], style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              _applyPreset(preset);
                              Navigator.pop(context);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                setState(() => _presets.removeAt(index));
                                setSheetState(() {}); 
                                _savePresetsToDB();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  String _formatFrequency(double freq) {
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(freq % 1000 == 0 ? 0 : 1)}k';
    }
    return freq.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Audio Effects', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuTab('Equalizer'),
                  const SizedBox(width: 20),
                  _buildMenuTab('Pitch'),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Expanded(
                child: _buildActiveEffectControl(),
              ),
              
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _resetCurrentEffect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)
                    ),
                    child: const Text('Reset Current'),
                  ),
                  
                  if (_activeMenu == 'Equalizer')
                    ElevatedButton.icon(
                      onPressed: _showPresetsSheet,
                      icon: const Icon(Icons.list, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Presets'),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveEffectControl() {
    if (_activeMenu == 'Equalizer') {
      if (_eqParams == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVerticalSlider(
            label: 'PRE',
            value: _preampValue,
            min: 0.0,
            max: 2.0, 
            topLabel: '+100%',
            bottomLabel: '0%',
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() => _preampValue = val);
              ref.read(audioPlayerProvider).setVolume(val); 
            },
          ),
          
          Container(
            width: 1, 
            color: Colors.grey.shade700, 
            margin: const EdgeInsets.symmetric(horizontal: 10)
          ),
          
          ...List.generate(_eqParams!.bands.length, (index) {
            final band = _eqParams!.bands[index];
            final maxDb = _eqParams!.maxDecibels;
            final minDb = _eqParams!.minDecibels;

            return _buildVerticalSlider(
              label: _formatFrequency(band.centerFrequency),
              value: _bandValues[index],
              min: minDb,
              max: maxDb,
              topLabel: '+${maxDb.round()}',
              bottomLabel: '${minDb.round()}',
              activeColor: Colors.orangeAccent,
              onChanged: (val) {
                setState(() => _bandValues[index] = val);
                band.setGain(val); 
              },
            );
          }),
        ],
      );
    } 
    else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.speed, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 30),
          Text('Pitch: ${_pitchValue.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Slider(
            min: 0.5,
            max: 2.0, 
            value: _pitchValue,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey.shade800,
            onChanged: (val) {
              setState(() => _pitchValue = val);
              ref.read(audioPlayerProvider).setPitch(val); 
            },
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deeper', style: TextStyle(color: Colors.grey)),
                Text('Chipmunk', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      );
    } 
  }

  Widget _buildMenuTab(String title) {
    final isActive = _activeMenu == title;
    return InkWell(
      onTap: () => setState(() => _activeMenu = title),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isActive ? Colors.orangeAccent : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String topLabel,
    required String bottomLabel,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(topLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(height: 8),
        
        Expanded(
          child: RotatedBox(
            quarterTurns: 3, 
            child: Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              activeColor: activeColor,
              inactiveColor: Colors.grey.shade800,
              thumbColor: Colors.white,
              onChanged: onChanged,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        Text(bottomLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _resetCurrentEffect() {
    setState(() {
      if (_activeMenu == 'Equalizer') {
        _preampValue = 1.0;
        ref.read(audioPlayerProvider).setVolume(1.0);
        if (_eqParams != null) {
          for (int i = 0; i < _bandValues.length; i++) {
            _bandValues[i] = 0.0;
            _eqParams!.bands[i].setGain(0.0);
          }
        }
      } else if (_activeMenu == 'Pitch') {
        _pitchValue = 1.0;
        ref.read(audioPlayerProvider).setPitch(1.0);
      }
    });
  }
}