import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Name pending'),
        ),
        body: const Center(
          child: Text('Dashboard goes here'),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artist'),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Folders'),
          ],
        ),
      ),
    ),
  );
}
