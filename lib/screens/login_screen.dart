import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Ensure plugins are initialized before calling SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(
          context,
          '/projects',
          arguments: {'token': token},
        );
      }
    } catch (e) {
      // Optionally handle or log the error
      // print('SharedPreferences not available: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token); // salva o token
          Navigator.pushReplacementNamed(
            context,
            '/projects',
            arguments: {'token': token},
          );
        } else {
          setState(() {
            _error = 'Token não encontrado na resposta.';
          });
        }
      } else {
        String message = 'Login failed. Check your credentials.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'];
          }
        } catch (_) {}
        setState(() {
          _error = message;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainGray = Colors.grey.shade800;
    final Color lightGray = Colors.grey.shade200;
    final Color borderGray = Colors.grey.shade400;
    final Color textGray = Colors.grey.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightGray,
        foregroundColor: mainGray,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            color: lightGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        height: 72,
                        child: Image.asset(
                          'logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 48, color: Colors.red),
                        ),
                      ),
                    ),
                    Text(
                      'Bem-vindo!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: mainGray,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        prefixIcon: Icon(Icons.email, color: mainGray),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: mainGray),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        prefixIcon: Icon(Icons.lock, color: mainGray),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: mainGray),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainGray,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Login'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: mainGray,
                          side: BorderSide(color: borderGray, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Registrar-se',
                          style: TextStyle(color: mainGray),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
