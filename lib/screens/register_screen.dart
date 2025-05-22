import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.register({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmController.text,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['message'] ?? 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connecting to server.';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar-se'),
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
                    Text(
                      'Criar Conta',
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        prefixIcon: Icon(Icons.person, color: mainGray),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: mainGray),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordConfirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: mainGray),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: mainGray),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value != _passwordController.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _register,
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
                              child: const Text('Registrar'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
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
                          'Voltar ao Login',
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
