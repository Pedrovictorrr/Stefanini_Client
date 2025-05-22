import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html; // Para acessar geolocalização no navegador
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
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    _initTokenAndLocation();
  }

  Future<void> _initTokenAndLocation() async {
    String? token = widget.token;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
    }
    if (!mounted) return;
    setState(() {
      _token = token;
    });
    _getLocation();
  }

  void _getLocation() {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (html.window.navigator.geolocation != null) {
      html.window.navigator.geolocation.getCurrentPosition().then((pos) {
        if (!mounted) return;
        setState(() {
          _lat = pos.coords?.latitude != null ? (pos.coords!.latitude as num).toDouble() : null;
          _lon = pos.coords?.longitude != null ? (pos.coords!.longitude as num).toDouble() : null;
        });
        if (_token != null && _lat != null && _lon != null) {
          _fetchWeather();
        }
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          _error = 'Não foi possível obter localização.';
          _loading = false;
        });
      });
    } else {
      setState(() {
        _error = 'Geolocalização não suportada.';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getWeather(
        _token ?? '',
        lat: _lat!,
        lon: _lon!,
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weather = {
            'city': data['location']?['name'] ?? '-',
            'region': data['location']?['region'] ?? '-',
            'country': data['location']?['country'] ?? '-',
            'localtime': data['location']?['localtime'] ?? '-',
            'temperature': data['current']?['temp_c']?.toString() ?? '-',
            'feelslike': data['current']?['feelslike_c']?.toString() ?? '-',
            'humidity': data['current']?['humidity']?.toString() ?? '-',
            'wind_kph': data['current']?['wind_kph']?.toString() ?? '-',
            'wind_dir': data['current']?['wind_dir'] ?? '-',
            'pressure_mb': data['current']?['pressure_mb']?.toString() ?? '-',
            'description': data['current']?['condition']?['text'] ?? '-',
            'icon': data['current']?['condition']?['icon'],
          };
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
    final Color mainGray = Colors.grey.shade800;
    final Color lightGray = Colors.grey.shade200;
    final Color borderGray = Colors.grey.shade400;

    return Scaffold(
      appBar: AppBar(
        title: Text('Clima - ${_weather?['city'] ?? 'Local'}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightGray,
        foregroundColor: mainGray,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            color: lightGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _weather == null
                          ? const Center(child: Text('Nenhum dado de clima.'))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _weather?['icon'] != null
                                    ? Image.network(
                                        'https:${_weather!['icon']}',
                                        width: 80,
                                        height: 80,
                                      )
                                    : Icon(
                                        Icons.cloud_outlined,
                                        color: Colors.blue[400],
                                        size: 80,
                                      ),
                                const SizedBox(height: 16),
                                Text(
                                  _weather?['city'] ?? '-',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: mainGray,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${_weather?['region'] ?? '-'}, ${_weather?['country'] ?? '-'}',
                                  style: TextStyle(
                                    color: mainGray.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Local: ${_weather?['localtime'] ?? '-'}',
                                  style: TextStyle(
                                    color: borderGray,
                                    fontSize: 14,
                                  ),
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
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.device_thermostat, color: Colors.red[400], size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sensação: ${_weather?['feelslike'] ?? '-'}°C',
                                      style: const TextStyle(fontSize: 16),
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
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(Icons.water_drop, color: Colors.blue[300], size: 22),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_weather?['humidity'] ?? '-'}%',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Umidade', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(Icons.air, color: Colors.green[400], size: 22),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_weather?['wind_kph'] ?? '-'} km/h',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('${_weather?['wind_dir'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(Icons.speed, color: Colors.grey[600], size: 22),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_weather?['pressure_mb'] ?? '-'} mb',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Pressão', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _lat != null && _lon != null ? _fetchWeather : null,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Atualizar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mainGray,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      textStyle: const TextStyle(fontSize: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ),
      ),
    );
  }
}
