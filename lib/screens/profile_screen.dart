import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _pastDestinations = <TextEditingController>[];
  final _bucketListDestinations = <TextEditingController>[];
  final _bucketListThrills = <TextEditingController>[];
  final _travelDates = <TextEditingController>[];

  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _addField(_pastDestinations);
    _addField(_bucketListDestinations);
    _addField(_bucketListThrills);
    _addField(_travelDates);
    _loadUserData();
  }

  void _addField(List<TextEditingController> list, {String value = ''}) {
    final controller = TextEditingController(text: value);
    setState(() {
      list.add(controller);
    });
  }

  void _removeField(List<TextEditingController> list, int index) {
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  List<String> _getFieldValues(List<TextEditingController> controllers) {
    return controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
  }

  void _setFieldValues(List<TextEditingController> controllers, List<dynamic>? values) {
    if (values != null) {
      for (int i = 0; i < values.length; i++) {
        if (i >= controllers.length) {
          _addField(controllers, value: values[i]);
        } else {
          controllers[i].text = values[i];
        }
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _ageController.text = data?['age']?.toString() ?? '';
          _genderController.text = data?['gender'] ?? '';
          _setFieldValues(_pastDestinations, data?['pastDestinations']);
          _setFieldValues(_bucketListDestinations, data?['bucketListDestinations']);
          _setFieldValues(_bucketListThrills, data?['bucketListThrills']);
          _setFieldValues(_travelDates, data?['travelDates']);
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _statusMessage = '';
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _genderController.text.trim(),
        'pastDestinations': _getFieldValues(_pastDestinations),
        'bucketListDestinations': _getFieldValues(_bucketListDestinations),
        'bucketListThrills': _getFieldValues(_bucketListThrills),
        'travelDates': _getFieldValues(_travelDates),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _statusMessage = 'Profile saved successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving profile: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildDynamicFields(String label, List<TextEditingController> controllers,
      {bool isDate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(controllers.length, (index) {
          final controller = controllers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: isDate,
                    onTap: isDate
                        ? () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              controller.text = DateFormat('yyyy-MM-dd').format(picked);
                            }
                          }
                        : null,
                    decoration: InputDecoration(
                      labelText: isDate ? 'Select a date' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeField(controllers, index),
                ),
              ],
            ),
          );
        }),
        TextButton(
          onPressed: () => _addField(controllers),
          child: const Text('+ Add another'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _genderController,
                    decoration: const InputDecoration(labelText: 'Sex'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDynamicFields('Favorite past destination(s)', _pastDestinations),
            _buildDynamicFields('Bucket-list destinations', _bucketListDestinations),
            _buildDynamicFields('Bucket-list thrills (e.g. Skydiving)', _bucketListThrills),
            _buildDynamicFields('Dates wanting to travel', _travelDates, isDate: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveUserData,
              child: _isSaving
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Save Profile'),
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('success') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            const Divider(),
            Center(
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
