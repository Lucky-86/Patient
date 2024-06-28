import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ProfileScreen extends StatefulWidget {
  late final String path;
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

  Future<Map<String, dynamic>> loadProfile(path) async {
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
            ),
          );
        }
      } else {
        fields.add(
          ListTile(
            title: Text(element['path']),
          ),
        );
      }
    }

    return fields;
  }

  @override
  void initState() {
    super.initState();
    patientProfile = loadProfile(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Viewer'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: patientProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView(
              children: _buildFormFields(snapshot.data!['snapshot']['element']),
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
}
