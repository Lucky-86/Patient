import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ProfileScreen extends StatefulWidget {
  final String path;
  ProfileScreen({required this.path});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> patientProfile;
  final List<String> complexDataTypes = [
    'Address',
    'Age',
    'Annotation',
    'Attachment',
    'CodeableConcept',
    'Coding',
    'ContactPoint',
    'Count',
    'Distance',
    'Duration',
    'HumanName',
    'Identifier',
    'Money',
    'Period',
    'Quantity',
    'Range',
    'Ratio',
    'SampledData',
    'Signature',
    'Timing',
    'Meta',
    'Dosage',
    'MarketingStatus',
    'RelatedArtifact',
    'UsageContext',
    'DataRequirement',
    'ParameterDefinition',
    'TriggerDefinition',
    'Expression',
    'ExtendedContactDetail',
    'CodeableReference',
    'ProductShelfLife',
    'SubstanceAmount',
    'ElementDefinition',
    'DataType',
    'BackboneElement',
    'Reference',
    'Narrative',
    'Extension',
    'QuantityComparator',
    'Attachment',
    'MoneyQuantity'
  ];

  Map<String, dynamic>? selectedElement;
  final ValueNotifier<String?> minErrorTextNotifier = ValueNotifier(null);
  final ValueNotifier<String?> maxErrorTextNotifier = ValueNotifier(null);

  Future<Map<String, dynamic>> loadProfile(String path) async {
    String jsonString = await rootBundle.loadString(path);
    return json.decode(jsonString);
  }

  Future<Map<String, dynamic>> _fetchStructureDefinition(
      String typeCode) async {
    String jsonString =
        await rootBundle.loadString('assets/$typeCode.profile.json');
    return json.decode(jsonString);
  }

  bool _isComplexType(String typeCode) {
    return complexDataTypes.contains(typeCode);
  }

  List<Widget> _buildFormFields(List<dynamic> elements) {
    List<Widget> fields = [];

    for (var element in elements.skip(1)) {
      if (element['type'] != null && element['type'][0]['code'] != null) {
        String typeCode = element['type'][0]['code'];

        if (_isComplexType(typeCode)) {
          fields.add(
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchStructureDefinition(typeCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return IconButton(
                    icon: Icon(Icons.refresh, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _fetchStructureDefinition(typeCode);
                      });
                    },
                  );
                } else if (snapshot.hasData) {
                  return ExpansionTile(
                    title: Text(
                      element['path'].split('.')[1],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    children:
                        _buildFormFields(snapshot.data!['snapshot']['element']),
                  );
                } else {
                  return ListTile(
                    title: Text(
                      element['path'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
              },
            ),
          );
        } else {
          fields.add(
            ListTile(
              title: Text(element['path'].split('.')[1]),
              onTap: () {
                setState(() {
                  selectedElement = element;
                });
              },
              selected: selectedElement == element,
              selectedTileColor: Colors.grey[300],
            ),
          );
        }
      } else {
        fields.add(
          ListTile(
            title: Text(element['path']),
            onTap: () {
              setState(() {
                selectedElement = element;
              });
            },
            selected: selectedElement == element,
            selectedTileColor: Colors.grey[300],
          ),
        );
      }
    }

    return fields;
  }

  Widget _buildElementProperties(Map<String, dynamic>? element) {
    if (element == null) {
      return Center(child: Text('Select an element to view properties'));
    }

    List<String>? conditions = element['condition']?.cast<String>();

    TextEditingController minController =
        TextEditingController(text: element['min'].toString());
    TextEditingController maxController =
        TextEditingController(text: element['max'].toString());

    void validateMin() {
      int baseMin = element['base']['min'] ?? 0;
      String baseMax = element['base']['max'] ?? '0';

      int? minValue = int.tryParse(minController.text);

      if (minValue != null) {
        if (baseMax == '*') {
          if (minValue < baseMin) {
            minErrorTextNotifier.value =
                'The minimum cardinality cannot be less than the base profile\'s minimum cardinality or greater than the base profile\'s maximum cardinality';
          } else {
            minErrorTextNotifier.value = null;
          }
        } else if (minValue < baseMin || minValue > int.parse(baseMax)) {
          minErrorTextNotifier.value =
              'The minimum cardinality cannot be less than the base profile\'s minimum cardinality or greater than the base profile\'s maximum cardinality';
        } else {
          minErrorTextNotifier.value = null;
        }
      } else {
        minErrorTextNotifier.value = 'Enter a valid number';
      }
    }

    void validateMax() {
      int baseMin = element['base']['min'] ?? 0;
      String baseMax = element['base']['max'] ?? '0';

      int? maxValue;

      if (maxController.text != '*') {
        maxValue = int.tryParse(maxController.text);

        if (maxValue != null) {
          if (baseMax == '*') {
            if (maxValue < baseMin) {
              maxErrorTextNotifier.value =
                  'The maximum cardinality cannot be less than the base profile\'s minimum cardinality';
            } else {
              maxErrorTextNotifier.value = null;
            }
          } else {
            if (maxValue < baseMin || maxValue > int.parse(baseMax)) {
              maxErrorTextNotifier.value =
                  'The maximum cardinality cannot be less than the base profile\'s minimum cardinality or greater than the base profile\'s maximum cardinality';
            } else {
              maxErrorTextNotifier.value = null;
            }
          }
        } else {
          maxErrorTextNotifier.value = 'Enter a valid number';
        }
      } else {
        maxErrorTextNotifier.value = null;
      }
    }

    minController.addListener(validateMin);
    maxController.addListener(validateMax);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: TextEditingController(text: element['id']),
            decoration: InputDecoration(
              labelText: 'Element ID',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
          SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: element['short'] ?? 'N/A'),
            decoration: InputDecoration(
              labelText: 'Short Description',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          SizedBox(height: 16),
          TextField(
            controller:
                TextEditingController(text: element['definition'] ?? 'N/A'),
            decoration: InputDecoration(
              labelText: 'Definition',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          SizedBox(height: 16),
          ExpansionTile(
            title: Text('Type'),
            children: [
              for (var type in element['type'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(type['code'], style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text('Cardinality'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text('Minimum:'),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0 || 1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          ValueListenableBuilder<String?>(
                            valueListenable: minErrorTextNotifier,
                            builder: (context, errorText, child) {
                              return errorText != null
                                  ? Text(errorText,
                                      style: TextStyle(color: Colors.red))
                                  : Container();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text('Maximum:'),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: maxController,
                            decoration: InputDecoration(
                              hintText: '0 || 1 || *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          ValueListenableBuilder<String?>(
                            valueListenable: maxErrorTextNotifier,
                            builder: (context, errorText, child) {
                              return errorText != null
                                  ? Text(errorText,
                                      style: TextStyle(color: Colors.red))
                                  : Container();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text('Attributes'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox('Is Summary', element['isSummary'] ?? false,
                        (value) {
                      setState(() {
                        element['isSummary'] = value;
                      });
                    }),
                    _buildCheckbox(
                        'Is Modifier', element['isModifier'] ?? false, (value) {
                      setState(() {
                        element['isModifier'] = value;
                      });
                    }),
                    _buildCheckbox(
                        'Must Support', element['mustSupport'] ?? false,
                        (value) {
                      setState(() {
                        element['mustSupport'] = value;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (element.containsKey('constraint'))
            ExpansionTile(
              title: Text('Constraints'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var constraint in element['constraint'])
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue: constraint['key'],
                              decoration: InputDecoration(
                                  labelText: 'Key',
                                  border: OutlineInputBorder()),
                              readOnly: true,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: constraint['severity'],
                              decoration: InputDecoration(
                                  labelText: 'Severity',
                                  border: OutlineInputBorder()),
                              readOnly: true,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: constraint['human'],
                              decoration: InputDecoration(
                                  labelText: 'Human',
                                  border: OutlineInputBorder()),
                              readOnly: true,
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: constraint['expression'],
                              decoration: InputDecoration(
                                  labelText: 'Expression',
                                  border: OutlineInputBorder()),
                              readOnly: true,
                            ),
                            if (constraint.containsKey('xpath'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextFormField(
                                  initialValue: constraint['xpath'],
                                  decoration: InputDecoration(
                                      labelText: 'Xpath',
                                      border: OutlineInputBorder()),
                                  readOnly: true,
                                ),
                              ),
                            SizedBox(height: 8),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: 8),
          conditions != null
              ? ExpansionTile(
                  title: Text('Conditions'),
                  children: conditions.map((condition) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Text(condition, style: TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    patientProfile = loadProfile(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    String profileName = widget.path
        .split('/')
        .last
        .split('.')
        .first; // Extract profile name from file path
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Profile on ${profileName[0].toUpperCase()}${profileName.substring(1)}'), // Capitalize first letter
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Define your button actions here
                        },
                        child: Row(
                          children: [
                            Icon(Icons.star),
                            SizedBox(width: 5),
                            Text('Extend'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Define your button actions here
                        },
                        child: Row(
                          children: [
                            Icon(Icons.cut),
                            SizedBox(width: 5),
                            Text('Slice'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Define your button actions here
                        },
                        child: Row(
                          children: [
                            Icon(Icons.add_circle),
                            SizedBox(width: 5),
                            Text('Add Slice'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Define your button actions here
                        },
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 5),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: patientProfile,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        return ListView(
                          children: _buildFormFields(
                              snapshot.data!['snapshot']['element']),
                        );
                      } else {
                        return Center(child: Text('No data found'));
                      }
                    },
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Element Properties',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                            child: _buildElementProperties(selectedElement)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
