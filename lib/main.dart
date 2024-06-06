import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(PokedexApp());
}

class PokedexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          title: 'Pokedex',
          theme: ThemeData(
            primarySwatch: Colors.red,
            fontFamily: 'Vatena',
          ),
          home: PokedexHomePage(),
        );
      },
    );
  }
}

class PokedexHomePage extends StatefulWidget {
  @override
  _PokedexHomePageState createState() => _PokedexHomePageState();
}

class _PokedexHomePageState extends State<PokedexHomePage> {
  List<dynamic> _pokemonTypes = [];
  List<dynamic> _pokemonList = [];
  List<dynamic> _filteredPokemonList = [];
  Map<String, dynamic>? _selectedPokemon;
  bool _isLoading = true;
  bool _isLoadingDetails = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchPokemonTypes();
  }

  Future<void> _fetchPokemonTypes() async {
    try {
      final response =
          await http.get(Uri.parse('https://pokeapi.co/api/v2/type'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonTypes = data['results'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load Pokémon types');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load Pokémon types');
    }
  }

  Future<void> _fetchPokemonsByType(String typeUrl) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(typeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonList = data['pokemon'];
          _filteredPokemonList = _pokemonList;
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load Pokémon list');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load Pokémon list');
    }
  }

  Future<void> _fetchPokemonDetails(String url) async {
    setState(() {
      _isLoadingDetails = true;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedPokemon = data;
          _isLoadingDetails = false;
        });
      } else {
        _showErrorSnackBar('Failed to load Pokémon details');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load Pokémon details');
    }
  }

  void _filterPokemonList(String query) {
    setState(() {
      _filteredPokemonList = _pokemonList
          .where((pokemon) =>
              pokemon['pokemon']['name'].toString().contains(query))
          .toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pokedex',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SearchBar(onSearch: _filterPokemonList),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : TypeList(
                            types: _pokemonTypes,
                            selectedType: _selectedType,
                            onTypeSelected: (type) {
                              setState(() {
                                _selectedType = type;
                              });
                              _fetchPokemonsByType(type);
                            },
                          ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : PokemonList(
                            pokemonList: _filteredPokemonList,
                            onPokemonSelected: _fetchPokemonDetails,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}

class TypeList extends StatelessWidget {
  final List<dynamic> types;
  final String? selectedType;
  final Function(String) onTypeSelected;

  const TypeList(
      {required this.types,
      required this.selectedType,
      required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index]['name'];
        final isSelected = selectedType == types[index]['url'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ElevatedButton(
            onPressed: () => onTypeSelected(types[index]['url']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: isSelected ? 16.h : 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 15.0,
              textStyle: TextStyle(
                fontSize: isSelected ? 20.sp : 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class PokemonList extends StatelessWidget {
  final List<dynamic> pokemonList;
  final Function(String) onPokemonSelected;

  PokemonList({required this.pokemonList, required this.onPokemonSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        return PokemonCard(
          pokemon: pokemonList[index]['pokemon'],
          onPokemonSelected: onPokemonSelected,
        );
      },
    );
  }
}

class PokemonCard extends StatefulWidget {
  final dynamic pokemon;
  final Function(String) onPokemonSelected;

  PokemonCard({required this.pokemon, required this.onPokemonSelected});

  @override
  _PokemonCardState createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  bool _isExpanded = false;
  bool _isLoadingDetails = false;
  Map<String, dynamic>? _pokemonDetails;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _pokemonDetails == null) {
      widget.onPokemonSelected(widget.pokemon['url']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(
                widget.pokemon['name'].toString().toUpperCase(),
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (_isExpanded) _buildExpandedDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    if (_isLoadingDetails) {
      return Center(child: CircularProgressIndicator());
    } else if (_pokemonDetails == null) {
      return Center(child: Text('No details available'));
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              _pokemonDetails?['sprites']['front_default'] ?? '',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 16),
            Text(
              _pokemonDetails?['name']?.toString().toUpperCase() ?? '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(_pokemonDetails?['flavor_text_entries']
                    ?.firstWhere((entry) => entry['language']['name'] == 'en')['flavor_text'] ??
                'No description available'),
            SizedBox(height: 16),
            Text(
              'Types:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: (_pokemonDetails?['types'] as List<dynamic>? ?? [])
                  .map<Widget>((typeInfo) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          _getTypeEmoji(typeInfo['type']['name']),
                          style: TextStyle(fontSize: 24),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'grass':
        return '🌿';
      case 'fire':
        return '🔥';
      case 'water':
        return '💧';
      case 'bug':
        return '🐛';
      case 'normal':
        return '⭐';
      case 'poison':
        return '☠️';
      case 'electric':
        return '⚡';
      case 'ground':
        return '🌍';
      case 'fairy':
        return '🧚';
      case 'fighting':
        return '🥊';
      case 'psychic':
        return '🔮';
      case 'rock':
        return '🪨';
      case 'ghost':
        return '👻';
      case 'ice':
        return '❄️';
      case 'dragon':
        return '🐉';
      case 'dark':
        return '🌑';
      case 'steel':
        return '🔩';
      case 'flying':
        return '🦅';
      default:
        return '❓';
    }
  }
}
