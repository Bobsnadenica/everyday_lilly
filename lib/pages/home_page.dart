import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Calendar> _calendars = [];
  Calendar? _selectedCalendar;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('calendars');
    if (jsonString != null) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        final calendars = list.map((item) => Calendar.fromJson(item)).toList();
        final savedId = await _loadSelectedCalendarId();
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
      } catch (_) {
        _setDefaultCalendars();
      }
    } else {
      _setDefaultCalendars();
    }
  }

  void _setDefaultCalendars() {
    setState(() {
      _calendars = [
        Calendar(id: 'everyday_lilly', name: 'Everyday Lilly', year: 2025),
        Calendar(id: 'everyday_dandelion', name: 'Everyday Dandelion', year: 2025),
      ];
      _selectedCalendar = _calendars.first;
    });
    _saveCalendars();
    _saveSelectedCalendarId(_selectedCalendar!.id);
  }

  Future<void> _saveCalendars() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _calendars.map((c) => c.toJson()).toList();
    await prefs.setString('calendars', json.encode(data));
  }

  Future<void> _saveSelectedCalendarId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_calendar_id', id);
  }

  Future<String?> _loadSelectedCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_calendar_id');
  }

  void _selectCalendar(Calendar calendar) {
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
      setState(() {
        _calendars.add(newCalendar);
        _selectedCalendar = newCalendar;
      });
      await _saveCalendars();
      await _saveSelectedCalendarId(newCalendar.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCalendar == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
            Expanded(
              child: ListView.builder(
                itemCount: _calendars.length,
                itemBuilder: (context, index) {
                  final calendar = _calendars[index];
                  return ListTile(
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
                    trailing: (calendar.name == 'Everyday Lilly' || calendar.name == 'Everyday Dandelion')
                        ? null
                        : IconButton(
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
                                setState(() {
                                  _calendars.remove(calendar);
                                  if (_selectedCalendar == calendar) {
                                    _selectedCalendar = _calendars.isNotEmpty ? _calendars.first : null;
                                  }
                                });
                                await _saveCalendars();
                                if (_selectedCalendar != null) {
                                  await _saveSelectedCalendarId(_selectedCalendar!.id);
                                }
                              }
                            },
                          ),
                  );
                },
              ),
            ),
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