import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectListScreen extends StatefulWidget {
  final String? token;
  const ProjectListScreen({super.key, required this.token});

  static Route routeFromArgs(RouteSettings settings) {
    final args = settings.arguments as Map?;
    final token = args != null && args['token'] != null ? args['token'] as String : null;
    return MaterialPageRoute(
      builder: (_) => ProjectListScreen(token: token),
      settings: settings,
    );
  }

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<dynamic> _projects = [];
  bool _loading = true;
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
      _fetchProjects();
    }
  }

  Future<void> _fetchProjects() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/v1/projetos'),
      headers: {
        'Authorization': 'Bearer ${_token ?? ''}',
      },
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        _projects = json.decode(response.body);
        _loading = false;
      });
    } else {
      setState(() {
        _projects = [];
        _loading = false;
      });
    }
  }

  Future<void> _deleteProject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar este projeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await http.delete(
      Uri.parse('http://localhost:8000/api/v1/projetos/$id'),
      headers: {
        'Authorization': 'Bearer ${_token ?? ''}',
      },
    );
    if (!mounted) return;
    _fetchProjects();
  }

  Future<void> _addProjectDialog() async {
    final _formKey = GlobalKey<FormState>();
    String nome = '';
    String descricao = '';
    String dataInicio = '';
    String status = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Projeto'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nome'),
                    onSaved: (v) => nome = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    onSaved: (v) => descricao = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Data de Início (YYYY-MM-DD)'),
                    onSaved: (v) => dataInicio = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe a data' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Status'),
                    onSaved: (v) => status = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe o status' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  await _createProject({
                    'nome': nome,
                    'descricao': descricao,
                    'data_inicio': dataInicio,
                    'status': status,
                  });
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projeto criado com sucesso!')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProject(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('http://localhost:8000/api/v1/projetos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      },
      body: json.encode(data),
    );
    if (!mounted) return;
    _fetchProjects();
  }

  Future<void> _editProjectDialog(Map<String, dynamic> project) async {
    final _formKey = GlobalKey<FormState>();
    String nome = project['nome'] ?? '';
    String descricao = project['descricao'] ?? '';
    String dataInicio = project['data_inicio'] ?? '';
    String status = project['status'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Projeto'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    onSaved: (v) => nome = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  ),
                  TextFormField(
                    initialValue: descricao,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    onSaved: (v) => descricao = v ?? '',
                  ),
                  TextFormField(
                    initialValue: dataInicio,
                    decoration: const InputDecoration(labelText: 'Data de Início (YYYY-MM-DD)'),
                    onSaved: (v) => dataInicio = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe a data' : null,
                  ),
                  TextFormField(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    onSaved: (v) => status = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe o status' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  await _updateProject(project['id'], {
                    'nome': nome,
                    'descricao': descricao,
                    'data_inicio': dataInicio,
                    'status': status,
                  });
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projeto editado com sucesso!')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProject(int id, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('http://localhost:8000/api/v1/projetos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      },
      body: json.encode(data),
    );
    if (!mounted) return;
    _fetchProjects();
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
        title: const Text('Projetos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
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
              selected: ModalRoute.of(context)?.settings.name == '/projects',
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/projects');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Clima'),
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
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  title: Text(project['nome'] ?? 'Sem nome'),
                  subtitle: Text(project['descricao'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editProjectDialog(project),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteProject(project['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
