import 'package:flutter/material.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  // 1. Frequency band labels (Hz/kHz)
  final List<String> _bands = ['32', '125', '500', '2k', '8k', '16k'];
  
  // 2. State to hold the current value of each slider (-12.0 to 12.0)
  final List<double> _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  // 3. State for the master preamp
  double _preampValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900, // A sleek, dark studio background
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
                    _buildEffectToggle('Limiter', false),
                    _buildEffectToggle('Equalizer', true),
                    _buildEffectToggle('Pitch', false),
                    _buildEffectToggle('Reverb', false),
                    _buildEffectToggle('Chorus', false),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // --- SLIDER RACK ---
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Master Preamp Slider
                    _buildVerticalSlider(
                      label: 'PRE',
                      value: _preampValue,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => setState(() => _preampValue = val),
                    ),
                    
                    // Visual Divider
                    Container(
                      width: 1, 
                      color: Colors.grey.shade700, 
                      margin: const EdgeInsets.symmetric(horizontal: 10)
                    ),
                    
                    // Generate all EQ Band Sliders dynamically
                    ...List.generate(_bands.length, (index) {
                      return _buildVerticalSlider(
                        label: _bands[index],
                        value: _bandValues[index],
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) => setState(() => _bandValues[index] = val),
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
                      // Reset all sliders to zero
                      setState(() {
                        _bandValues.fillRange(0, _bandValues.length, 0.0);
                        _preampValue = 0.0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)
                    ),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
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

  // Helper method to build the top radio toggles
  Widget _buildEffectToggle(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
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
    );
  }

  // Helper method to build the vertical sliders
  Widget _buildVerticalSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        // Top label (+12 dB)
        Text('+12', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(height: 8),
        
        // The actual vertical slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3, // This rotates a normal horizontal slider perfectly vertical
            child: Slider(
              min: -12.0,
              max: 12.0,
              value: value,
              activeColor: activeColor,
              inactiveColor: Colors.grey.shade800,
              thumbColor: Colors.white,
              onChanged: onChanged,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        // Bottom label (-12 dB)
        Text('-12', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(height: 12),
        // Frequency Label
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}