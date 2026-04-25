import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/components/player_settings.dart';
import 'package:music_player_app/presentation/screens/home_screen.dart'; 


class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  void _backScreen (BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Crucial for neumorphism to blend
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => _backScreen(context), icon: const Icon(Icons.arrow_back)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                ],
              ),
              
              const SizedBox(height: 20),

              PlayerSettings(
                child: Column(
                  children: [
                    // Album artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 300, // Placeholder height for your image
                        width: double.infinity,
                        color: Colors.grey.shade400, // Placeholder color
                        // child: Image.asset("your_image_path.png", fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Song, Artist, and favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'So Sick',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            Text(
                              'Neyo',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                            ),
                          ],
                        ),
                        // Change for icon
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. PROGRESS BAR & TIMESTAMPS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('0:00', style: TextStyle(color: Colors.grey.shade600)),
                  const Icon(Icons.shuffle, color: Colors.grey),
                  const Icon(Icons.repeat, color: Colors.grey),
                  Text('4:27', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              Slider(
                min: 0,
                max: 100,
                value: 30, // Example value
                activeColor: Colors.green, 
                inactiveColor: Colors.grey.shade300,
                onChanged: (value) {},
              ),

              Row(
                children: [
                  // skip previous
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: const PlayerSettings(
                        child: Icon(Icons.skip_previous),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // play pause
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {},
                      child: const PlayerSettings(
                        child: Icon(Icons.play_arrow),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // skip forward
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: const PlayerSettings(
                        child: Icon(Icons.skip_next),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ), 
    );
  }
}