import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';

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
      final response = await ApiService.getWeather(_token ?? '', 'São Paulo');
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
      appBar: AppBar(
        title: const Text('Clima - São Paulo'),
        centerTitle: true,
        elevation: 0,
      ),
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
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_outlined,
                                  color: Colors.blue[400],
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _weather?['city'] ?? 'São Paulo',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.thermostat, color: Colors.orange[700], size: 32),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_weather?['temperature'] ?? '-'}°C',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud, color: Colors.blue[700], size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      _weather?['description'] ?? '-',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                // Espaço extra para o botão não sobrepor conteúdo
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _fetchWeather,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Atualizar'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  textStyle: const TextStyle(fontSize: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
