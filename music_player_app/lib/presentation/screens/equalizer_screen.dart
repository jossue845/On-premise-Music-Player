import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_app/utils/global_player.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  AndroidEqualizerParameters? _eqParams;
  List<double> _bandValues = [];
  bool _isEqEnabled = false;
  double _preampValue = 1.0; 

  @override
  void initState() {
    super.initState();
    // Grab the current player volume to use as our Preamp baseline
    _preampValue = globalAudioPlayer.volume;
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      // Query the Android device for its specific hardware bands
      final params = await globalEqualizer.parameters;
      if (mounted) {
        setState(() {
          _eqParams = params;
          _isEqEnabled = globalEqualizer.enabled;
          // Map the current hardware gains to our local UI state
          _bandValues = params.bands.map((b) => b.gain).toList();
        });
      }
    } catch (e) {
      debugPrint("Failed to initialize Equalizer: $e");
    }
  }

  Future<void> _toggleEqualizer() async {
    final newState = !_isEqEnabled;
    await globalEqualizer.setEnabled(newState);
    setState(() => _isEqEnabled = newState);
  }

  // Converts native Hertz (e.g., 16000.0) into readable labels (e.g., 16k)
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
        title: const Text('Equalizer', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              
              // --- TOP EFFECTS MENU ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildEffectToggle('Limiter', false, null),
                    _buildEffectToggle('Equalizer', _isEqEnabled, _toggleEqualizer),
                    _buildEffectToggle('Pitch', false, null),
                    _buildEffectToggle('Reverb', false, null),
                    _buildEffectToggle('Chorus', false, null),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // --- SLIDER RACK ---
              Expanded(
                child: _eqParams == null
                    ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Master Preamp Slider
                          _buildVerticalSlider(
                            label: 'PRE',
                            value: _preampValue,
                            min: 0.0,
                            max: 2.0, // 200% volume boost
                            topLabel: '+100%',
                            bottomLabel: '0%',
                            activeColor: Colors.greenAccent,
                            onChanged: (val) {
                              setState(() => _preampValue = val);
                              globalAudioPlayer.setVolume(val); // Controls actual audio output
                            },
                          ),
                          
                          // Visual Divider
                          Container(
                            width: 1, 
                            color: Colors.grey.shade700, 
                            margin: const EdgeInsets.symmetric(horizontal: 10)
                          ),
                          
                          // Dynamic Hardware EQ Band Sliders
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
                                // Update UI instantly for smooth dragging
                                setState(() => _bandValues[index] = val);
                                // Send value to audio engine asynchronously
                                band.setGain(val); 
                              },
                            );
                          }),
                        ],
                      ),
              ),
              
              const SizedBox(height: 30),
              
              // --- BOTTOM CONTROLS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Reset Preamp and all EQ bands to zero natively
                      setState(() {
                        _preampValue = 1.0;
                        globalAudioPlayer.setVolume(1.0);
                        
                        if (_eqParams != null) {
                          for (int i = 0; i < _bandValues.length; i++) {
                            _bandValues[i] = 0.0;
                            _eqParams!.bands[i].setGain(0.0);
                          }
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)
                    ),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preset feature coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Preset'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectToggle(String title, bool isActive, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isActive ? Colors.orangeAccent : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
            ],
          ),
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
}