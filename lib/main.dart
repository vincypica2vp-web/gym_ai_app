import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GymAIApp());
}

class GymAIApp extends StatelessWidget {
  const GymAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym AI Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _daysPerWeek = 3;
  
  final Map<String, bool> _equipment = {
    'Manubri': true,
    'Bilanciere': false,
    'Cavi / Corde': false,
    'Macchinari guidati': true,
    'Corpo libero': true,
  };

  bool _isLoading = false;

  Future<void> _generateWorkout() async {
    final weight = _weightController.text;
    final height = _heightController.text;

    if (weight.isEmpty || height.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore inserisci peso e altezza!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final selectedEquipment = _equipment.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');

    try {
      const apiKey = 'TUA_API_KEY_QUI';
      
      final prompt = '''
Sei un personal trainer professionista. Crea una scheda di allenamento settimanale personalizzata basata su questi dati:
- Peso: $weight kg
- Altezza: $height cm
- Giorni di allenamento a settimana: ${_daysPerWeek.toInt()}
- Attrezzatura disponibile: $selectedEquipment

Restituisci la scheda suddivisa per i giorni di allenamento, indicando per ogni esercizio le serie, le ripetizioni e i recuperi consigliati. Usa una formattazione pulita e leggibile.
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final workoutResult = data['choices'][0]['message']['content'];

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutResultScreen(workoutPlan: workoutResult),
          ),
        );
      } else {
        throw Exception('Errore nella risposta dell\'IA');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutResultScreen(
            workoutPlan: 'ATTENZIONE: Inserisci una chiave API valida nel codice per ricevere la risposta dall\'IA.\n\nEsempio di scheda generata per ${_daysPerWeek.toInt()} giorni:\n- Giorno 1: Petto e Tricipiti\n- Giorno 2: Dorsali e Bicipiti\n- Giorno 3: Gambe e Spalle',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura il tuo Allenamento IA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I tuoi dati biometrici',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Altezza (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giorni di allenamento a settimana',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _daysPerWeek,
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_daysPerWeek.toInt()} giorni',
              onChanged: (value) {
                setState(() {
                  _daysPerWeek = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Attrezzatura disponibile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ..._equipment.keys.map((String key) {
              return CheckboxListTile(
                title: Text(key),
                value: _equipment[key],
                onChanged: (bool? value) {
                  setState(() {
                    _equipment[key] = value ?? false;
                  });
                },
              );
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _generateWorkout,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Genera Scheda con IA',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutResultScreen extends StatelessWidget {
  final String workoutPlan;

  const WorkoutResultScreen({super.key, required this.workoutPlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('La tua Scheda Personalizzata'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ecco il tuo programma:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),
              Text(
                workoutPlan,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}