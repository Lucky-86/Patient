import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class GridScreen extends StatefulWidget {
  @override
  _GridScreenState createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  List<String> jsonFileNames = [];
  List<String> options = [
    'Resource profile',
    'Datatype profile',
    'Extension definition',
    'Derived profile',
    'Logical model',
  ];

  String? selectedOption = 'Resource profile';

  @override
  void initState() {
    super.initState();
    _loadJsonFileNames();
  }

  Future<void> _loadJsonFileNames() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final jsonFiles = manifestMap.keys
        .where((String key) => key.contains('assets/json/'))
        .toList();

    setState(() {
      jsonFileNames = jsonFiles.map((file) => file.split('/').last).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JSON Files Grid'),
      ),
      body: Row(
        children: [
          // Left side: Radio buttons
          Container(
            width: 200,
            color: Colors.grey[200],
            child: ListView(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          // Right side: GridView
          Expanded(
            child: jsonFileNames.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // Number of columns in the grid
                      crossAxisSpacing: 8.0, // Spacing between columns
                      mainAxisSpacing: 8.0, // Spacing between rows
                    ),
                    itemCount: jsonFileNames.length,
                    itemBuilder: (context, index) {
                      String fileNameWithoutExtension =
                          jsonFileNames[index].split('.').first;
                      return GestureDetector(
                        onTap: () {
                          // Handle tap on the grid item (file name)
                          print('Tapped ${jsonFileNames[index]}');
                        },
                        child: Card(
                          elevation: 2.0,
                          child: Stack(
                            children: [
                              // Fire icon as background
                              Positioned.fill(
                                child: Opacity(
                                  opacity:
                                      0.1, // Adjust opacity to make it look like a wallpaper
                                  child: Icon(
                                    Icons.whatshot,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              // File name
                              Center(
                                child: Text(
                                  fileNameWithoutExtension,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
