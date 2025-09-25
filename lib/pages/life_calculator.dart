

import 'package:flutter/material.dart';

class LifeCalculatorPage extends StatefulWidget {
  const LifeCalculatorPage({Key? key}) : super(key: key);

  @override
  State<LifeCalculatorPage> createState() => _LifeCalculatorPageState();
}

class _LifeCalculatorPageState extends State<LifeCalculatorPage> {
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  String _selectedType = 'Human';
  double? _remainingPercent;
  double? _remainingYears;

  final Map<String, int> _lifespans = {
    // Humans
    'Human': 80,

    // Pets
    'Dog (Small Breed)': 15,
    'Dog (Large Breed)': 10,
    'Cat': 16,
    'Rabbit': 9,
    'Hamster': 3,
    'Parrot': 60,
    'Goldfish': 10,

    // Farm Animals
    'Horse': 30,
    'Cow': 20,
    'Pig': 15,
    'Chicken': 10,
    'Goat': 15,
    'Sheep': 12,

    // Wild Animals
    'Elephant': 70,
    'Lion': 14,
    'Tiger': 15,
    'Bear': 25,
    'Wolf': 13,
    'Deer': 20,
    'Giraffe': 25,
    'Gorilla': 35,
    'Turtle': 100,
    'Blue Whale': 80,
    'Eagle': 28,
    'Penguin': 20,

    // Plants
    'Flower Plant': 3,
    'Shrub': 10,
    'Bamboo': 20,
    'Fruit Tree': 25,
    'Oak Tree': 300,
    'Pine Tree': 500,
    'Cherry Blossom Tree': 40,
    'Cactus': 150,

    // Man-made Objects
    'Building': 100,
    'Car': 15,
    'Bridge': 75,
    'Ship': 30,
    'Airplane': 30,
    'Road': 50,

    // Natural Landforms
    'River': 1000,
    'Mountain': 1000000,
    'Island': 5000000,

    // Cosmic Objects
    'Planet': 4500000000,
    'Star': 10000000000,
    'Galaxy': 100000000000,
    'Universe': 13800000000,
  };

  void _calculateLife() {
    final years = int.tryParse(_yearController.text) ?? 0;
    final months = int.tryParse(_monthController.text) ?? 0;
    final days = int.tryParse(_dayController.text) ?? 0;

    if (years < 0 || months < 0 || days < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter non-negative values')),
      );
      return;
    }
    if (months > 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Months should be between 0 and 11')),
      );
      return;
    }
    if (days > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Days should be between 0 and 30')),
      );
      return;
    }

    final totalAge = years + (months / 12.0) + (days / 365.0);
    final avgLife = _lifespans[_selectedType] ?? 80;
    final remaining = (avgLife - totalAge).clamp(0, avgLife);
    setState(() {
      _remainingYears = remaining;
      _remainingPercent = remaining / avgLife;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Expectancy Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              items: _lifespans.keys
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _monthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Months',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _dayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateLife,
              child: const Text('Calculate'),
            ),
            const SizedBox(height: 32),
            if (_remainingYears != null && _remainingPercent != null) ...[
              Text(
                '${_remainingYears!.toStringAsFixed(2)} years remaining',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _remainingPercent,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_remainingPercent! * 100).toStringAsFixed(1)}% of lifespan remaining',
                style: const TextStyle(fontSize: 16),
              ),
            ]
          ],
        ),
      ),
    );
  }
}