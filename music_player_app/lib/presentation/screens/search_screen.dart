import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget{
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController search_text = TextEditingController();
  String searching_word = "";
  void search(){
    setState(() {
      searching_word = "Searching " + search_text.text;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              Text(searching_word),
              TextField(
                controller: search_text,
              ),
              ElevatedButton(onPressed: search, child: Text('Search'))
            ],
          ),
        ),
      ),
    );
  }
}
