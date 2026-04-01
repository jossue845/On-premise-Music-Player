import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchResultText = "Enter a search term";
  String _selectedFilter = "All"; // Default filter
  
  // filter options
  final List<String> _filters = ["All", "Songs", "Artists", "Albums", "Playlists"];

  void _performSearch() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _searchResultText = "Please type something to search.";
      } else {
        _searchResultText = "Searching for '${_searchController.text}' in $_selectedFilter";
      }
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // 3. Polished Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'What can I search?...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none, // Removes the harsh black line
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (bool selected) {
                          setState(() {
                            // Update the selected filter when tapped
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              
              Center(
                child: ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  _searchResultText,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}