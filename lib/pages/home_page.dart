import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar.dart';
import 'calendar_page/calendar_page.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Calendar> _calendars = [];
  Calendar? _selectedCalendar;

  @override
  void initState() {
    super.initState();
    _loadCalendars().then((_) async {
      if (_calendars.isEmpty) {
        await _setDefaultCalendars();
      } else {
        await _ensureDefaultTriplet();
      }
    });
  }

  Future<void> _loadCalendars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('calendars');
      if (jsonString != null) {
        try {
          final List<dynamic> list = json.decode(jsonString);
          final calendars = list.map((item) => Calendar.fromJson(item)).toList();
          final savedId = await _loadSelectedCalendarId();
          if (!mounted) return;
          setState(() {
            _calendars = calendars;
            if (savedId != null) {
              final match = _calendars.where((c) => c.id == savedId).toList();
              if (match.isNotEmpty) {
                _selectedCalendar = match.first;
              } else {
                _selectedCalendar = _calendars.isNotEmpty
                    ? _calendars.first
                    : Calendar(id: 'everyday_lilly', name: 'Everyday Lilly', year: 2025);
              }
            } else {
              _selectedCalendar = _calendars.isNotEmpty
                  ? _calendars.first
                  : Calendar(id: 'everyday_lilly', name: 'Everyday Lilly', year: 2025);
            }
          });
          await _ensureDefaultTriplet();
        } catch (_) {
          await _setDefaultCalendars();
        }
      } else {
        await _setDefaultCalendars();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load calendars.');
      await _setDefaultCalendars();
    }
  }

  Future<void> _setDefaultCalendars() async {
    final defaultCalendars = [
      Calendar(id: 'everyday_lilly', name: 'Everyday Lilly', year: 2025),
      Calendar(id: 'everyday_dandelion', name: 'Everyday Dandelion', year: 2025),
      Calendar(id: 'everyday_me', name: 'Everyday Me', year: 2025),
    ];
    if (!mounted) return;
    setState(() {
      _calendars = defaultCalendars;
      _selectedCalendar = _calendars.first;
    });
    await _saveCalendars();
    await _saveSelectedCalendarId(_selectedCalendar!.id);
  }

  Future<void> _ensureDefaultTriplet() async {
    final defaultCalendarNames = {'Everyday Lilly', 'Everyday Dandelion', 'Everyday Me'};
    final defaultCalendars = {
      'Everyday Lilly': Calendar(id: 'everyday_lilly', name: 'Everyday Lilly', year: 2025),
      'Everyday Dandelion': Calendar(id: 'everyday_dandelion', name: 'Everyday Dandelion', year: 2025),
      'Everyday Me': Calendar(id: 'everyday_me', name: 'Everyday Me', year: 2025),
    };
    bool updated = false;
    if (!mounted) return;
    for (var name in defaultCalendarNames) {
      if (!_calendars.any((c) => c.name == name) && !_calendars.any((c) => c.id == defaultCalendars[name]!.id)) {
        _calendars.add(defaultCalendars[name]!);
        updated = true;
      }
    }
    if (updated) {
      setState(() {
        _calendars = List.from(_calendars);
        if (_selectedCalendar == null || !_calendars.contains(_selectedCalendar)) {
          _selectedCalendar = _calendars.first;
        }
      });
      await _saveCalendars();
      await _saveSelectedCalendarId(_selectedCalendar!.id);
    }
  }

  Future<void> _saveCalendars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _calendars.map((c) => c.toJson()).toList();
      await prefs.setString('calendars', json.encode(data));
    } catch (e) {
      _showErrorSnackBar('Failed to save calendars.');
    }
  }

  Future<void> _saveSelectedCalendarId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_calendar_id', id);
    } catch (e) {
      _showErrorSnackBar('Failed to save selected calendar.');
    }
  }

  Future<void> _removeSelectedCalendarId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_calendar_id');
    } catch (e) {
      _showErrorSnackBar('Failed to remove selected calendar.');
    }
  }

  Future<String?> _loadSelectedCalendarId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_calendar_id');
    } catch (e) {
      _showErrorSnackBar('Failed to load selected calendar.');
      return null;
    }
  }

  void _selectCalendar(Calendar calendar) {
    if (!mounted) return;
    setState(() {
      _selectedCalendar = calendar;
    });
    _saveSelectedCalendarId(calendar.id);
    Navigator.of(context).pop();
  }

  Future<void> _addCalendar() async {
    String _slugify(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Calendar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Calendar Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final id = '${_slugify(result)}_${DateTime.now().millisecondsSinceEpoch}';
      final newCalendar = Calendar(id: id, name: result, year: DateTime.now().year);
      if (!mounted) return;
      setState(() {
        _calendars.add(newCalendar);
        _selectedCalendar = newCalendar;
      });
      await _saveCalendars();
      await _saveSelectedCalendarId(newCalendar.id);
    }
  }

  Future<void> _renameCalendar(Calendar calendar) async {
    final nameController = TextEditingController(text: calendar.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Calendar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Calendar Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop(newName);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        final index = _calendars.indexWhere((c) => c.id == calendar.id);
        if (index != -1) {
          _calendars[index] = Calendar(id: calendar.id, name: result, year: calendar.year);
          if (_selectedCalendar?.id == calendar.id) {
            _selectedCalendar = _calendars[index];
          }
        }
      });
      await _saveCalendars();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCalendar == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final defaultCalendarNames = {'Everyday Lilly', 'Everyday Dandelion', 'Everyday Me'};
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F3),
      appBar: AppBar(
        title: Text(
          _selectedCalendar!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFDF9F3),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade100,
              ),
              child: Center(
                child: Text(
                  'Your Calendars',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _calendars.length,
                itemBuilder: (context, index) {
                  final calendar = _calendars[index];
                  final isDefault = defaultCalendarNames.contains(calendar.name);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                      leading: const Icon(Icons.calendar_month, color: Colors.green),
                      title: Text(
                        calendar.name,
                        style: TextStyle(
                          fontWeight: calendar.id == _selectedCalendar!.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: calendar.id == _selectedCalendar!.id
                              ? Colors.green.shade800
                              : Colors.black87,
                        ),
                      ),
                      selected: calendar.id == _selectedCalendar!.id,
                      onTap: () => _selectCalendar(calendar),
                      trailing: isDefault
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    await _renameCalendar(calendar);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text('Delete Calendar'),
                                        content: Text('Are you sure you want to delete ${calendar.name}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      if (!mounted) return;
                                      setState(() {
                                        _calendars.remove(calendar);
                                        if (_selectedCalendar == calendar) {
                                          _selectedCalendar = _calendars.isNotEmpty ? _calendars.first : null;
                                        }
                                      });
                                      await _saveCalendars();
                                      if (_calendars.isEmpty) {
                                        await _removeSelectedCalendarId();
                                      } else if (_selectedCalendar != null) {
                                        await _saveSelectedCalendarId(_selectedCalendar!.id);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _addCalendar,
              ),
            ),
          ],
        ),
      ),
      body: CalendarPage(
        key: ValueKey(_selectedCalendar!.id),
        calendar: _selectedCalendar!,
      ),
    );
  }
}