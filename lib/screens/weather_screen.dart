import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  final String? token;
  const WeatherScreen({super.key, required this.token});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _weather;
  bool _loading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initTokenAndFetch();
  }

  Future<void> _initTokenAndFetch() async {
    String? token = widget.token;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
    }
    if (!mounted) return;
    setState(() {
      _token = token;
    });
    if (_token != null && _token!.isNotEmpty) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/weather?city=São Paulo'),
        headers: {
          'Authorization': 'Bearer ${_token ?? ''}',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _weather = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao buscar clima.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro de conexão.';
        _loading = false;
      });
    }
  }

  void _navigateTo(String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(
      context,
      route,
      arguments: {'token': _token},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clima - São Paulo')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Projetos'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/projects');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Clima'),
              selected: ModalRoute.of(context)?.settings.name == '/weather',
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/weather');
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _weather == null
                  ? const Center(child: Text('Nenhum dado de clima.'))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Cidade: ${_weather?['city'] ?? 'São Paulo'}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text('Temperatura: ${_weather?['temperature'] ?? '-'}°C'),
                          Text('Descrição: ${_weather?['description'] ?? '-'}'),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchWeather,
                            child: const Text('Atualizar'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
