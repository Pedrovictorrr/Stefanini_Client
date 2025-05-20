import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_constants.dart';
import '../services/api_service.dart';


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

  static const List<String> _statusOptions = ['Ativo', 'Inativo', 'Concluído', 'Em andamento'];

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
    try {
      final response = await ApiService.getProjects(_token ?? '');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar projetos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projects = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao buscar projetos.')),
      );
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
    try {
      await ApiService.deleteProject(_token ?? '', id);
      if (!mounted) return;
      _fetchProjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao deletar projeto.')),
      );
    }
  }

  Future<void> _addProjectDialog() async {
    final _formKey = GlobalKey<FormState>();
    String nome = '';
    String descricao = '';
    String dataInicio = '';
    String status = '';
    final TextEditingController dataInicioController = TextEditingController();

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
                    controller: dataInicioController,
                    decoration: const InputDecoration(labelText: 'Data de Início'),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dataInicioController.text = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      }
                    },
                    onSaved: (v) => dataInicio = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe a data' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Status'),
                    value: _statusOptions.contains(status) && status.isNotEmpty ? status : null,
                    items: _statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      status = v ?? '';
                    },
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
    try {
      await ApiService.createProject(_token ?? '', data);
      if (!mounted) return;
      _fetchProjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao criar projeto.')),
      );
    }
  }

  Future<void> _editProjectDialog(Map<String, dynamic> project) async {
    final _formKey = GlobalKey<FormState>();
    String nome = project['nome'] ?? '';
    String descricao = project['descricao'] ?? '';
    String dataInicio = project['data_inicio'] ?? '';
    String status = project['status'] ?? '';
    final TextEditingController dataInicioController = TextEditingController(text: dataInicio);

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
                    controller: dataInicioController,
                    decoration: const InputDecoration(labelText: 'Data de Início'),
                    readOnly: true,
                    onTap: () async {
                      final initialDate = dataInicioController.text.isNotEmpty
                          ? DateTime.tryParse(dataInicioController.text) ?? DateTime.now()
                          : DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dataInicioController.text = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      }
                    },
                    onSaved: (v) => dataInicio = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Informe a data' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Status'),
                    value: _statusOptions.contains(status) && status.isNotEmpty ? status : null,
                    items: _statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      status = v ?? '';
                    },
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
    try {
      await ApiService.updateProject(_token ?? '', id, data);
      if (!mounted) return;
      _fetchProjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão ao atualizar projeto.')),
      );
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
        title: const Text('Projetos'),
        centerTitle: true,
        elevation: 0,
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
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: _projects.isEmpty
                  ? const Center(child: Text('Nenhum projeto encontrado.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? 2 : 1,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: _projects.length,
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            project['nome'] ?? 'Sem nome',
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            project['descricao'] ?? '',
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                              const SizedBox(width: 4),
                                              Text(
                                                project['data_inicio'] ?? '',
                                                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.flag, size: 16, color: Colors.blueGrey),
                                              const SizedBox(width: 4),
                                              Text(
                                                project['status'] ?? '',
                                                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editProjectDialog(project),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteProject(project['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProjectDialog,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Projeto'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
