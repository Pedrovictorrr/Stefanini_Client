import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';


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
      final response = await ApiService.createProject(_token ?? '', data);
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
      arguments: {'token': _token}, // Garante que o token é passado em todas as rotas
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainGray = Colors.grey.shade800;
    final Color lightGray = Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightGray,
        foregroundColor: mainGray,
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
                _navigateTo('/projects'); // token passado via _navigateTo
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Clima'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo('/weather'); // token passado via _navigateTo
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400), // aumentado de 1000 para 1400
          child: Card(
            elevation: 8,
            color: lightGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        final isMedium = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
                        final isSmall = constraints.maxWidth <= 600;

                        // Ajuste de colunas e larguras conforme o tamanho da tela
                        List<DataColumn> columns;
                        if (isSmall) {
                          columns = [
                            const DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Nome', textAlign: TextAlign.left),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 80,
                                child: Text('Status', textAlign: TextAlign.center),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 80,
                                child: Text('Ações', textAlign: TextAlign.center),
                              ),
                            ),
                          ];
                        } else if (isMedium) {
                          columns = [
                            const DataColumn(
                              label: SizedBox(
                                width: 140,
                                child: Text('Nome', textAlign: TextAlign.left),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Data', textAlign: TextAlign.center),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text('Status', textAlign: TextAlign.center),
                              ),
                            ),
                            const DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text('Ações', textAlign: TextAlign.center),
                              ),
                            ),
                          ];
                        } else {
                          columns = const [
                            DataColumn(
                              label: SizedBox(
                                width: 160,
                                child: Text('Nome', textAlign: TextAlign.left),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 220,
                                child: Text('Descrição', textAlign: TextAlign.left),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Data de Início', textAlign: TextAlign.center),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Status', textAlign: TextAlign.center),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Ações', textAlign: TextAlign.center),
                              ),
                            ),
                          ];
                        }

                        // Ajuste do padding horizontal
                        final double maxTableWidth = isWide
                            ? 1400 // aumentado de 1200 para 1400
                            : isMedium
                                ? 900 // aumentado de 800 para 900
                                : constraints.maxWidth - 16;
                        final double horizontalPadding = ((constraints.maxWidth - maxTableWidth) / 2).clamp(8.0, double.infinity);

                        return _projects.isEmpty
                            ? const Center(child: Text('Nenhum projeto encontrado.'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: isWide
                                              ? 1400 // aumentado de 1200 para 1400
                                              : isMedium
                                                  ? 900 // aumentado de 800 para 900
                                                  : constraints.maxWidth - 16,
                                          maxWidth: maxTableWidth,
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            cardColor: Colors.white,
                                            dividerColor: Colors.grey.shade300,
                                            dataTableTheme: DataTableThemeData(
                                              headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                                              headingTextStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                fontSize: 16,
                                              ),
                                              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                                                (Set<MaterialState> states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return Colors.blue.shade100;
                                                  }
                                                  return null;
                                                },
                                              ),
                                              dataTextStyle: const TextStyle(fontSize: 15),
                                              horizontalMargin: isSmall ? 8 : 16,
                                              columnSpacing: isSmall ? 12 : 32,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: DataTable(
                                              showBottomBorder: true,
                                              dataRowMinHeight: isSmall ? 40 : 48,
                                              dataRowMaxHeight: isSmall ? 48 : 60,
                                              columns: columns,
                                              rows: List<DataRow>.generate(
                                                _projects.length,
                                                (index) {
                                                  final project = _projects[index];
                                                  final isEven = index % 2 == 0;
                                                  // Linhas adaptadas conforme o tamanho da tela
                                                  List<DataCell> cells;
                                                  if (isSmall) {
                                                    cells = [
                                                      DataCell(
                                                        Text(
                                                          project['nome'] ?? 'Sem nome',
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Center(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: _getStatusColor(project['status']),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              project['status'] ?? '',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                              tooltip: 'Editar',
                                                              onPressed: () => _editProjectDialog(project),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                              tooltip: 'Deletar',
                                                              onPressed: () => _deleteProject(project['id']),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ];
                                                  } else if (isMedium) {
                                                    cells = [
                                                      DataCell(
                                                        Text(
                                                          project['nome'] ?? 'Sem nome',
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Center(
                                                          child: Text(
                                                            project['data_inicio'] ?? '',
                                                            style: const TextStyle(fontSize: 13),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Center(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: _getStatusColor(project['status']),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              project['status'] ?? '',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                              tooltip: 'Editar',
                                                              onPressed: () => _editProjectDialog(project),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                              tooltip: 'Deletar',
                                                              onPressed: () => _deleteProject(project['id']),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ];
                                                  } else {
                                                    cells = [
                                                      DataCell(
                                                        Text(
                                                          project['nome'] ?? 'Sem nome',
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          project['descricao'] ?? '',
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Center(
                                                          child: Text(
                                                            project['data_inicio'] ?? '',
                                                            style: const TextStyle(fontSize: 14),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Center(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: _getStatusColor(project['status']),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              project['status'] ?? '',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                                              tooltip: 'Editar',
                                                              onPressed: () => _editProjectDialog(project),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red),
                                                              tooltip: 'Deletar',
                                                              onPressed: () => _deleteProject(project['id']),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ];
                                                  }
                                                  return DataRow(
                                                    color: MaterialStateProperty.all(
                                                      isEven ? Colors.grey.shade50 : Colors.white,
                                                    ),
                                                    cells: cells,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                      },
                    ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProjectDialog,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Projeto'),
        backgroundColor: Colors.blue, // cor melhorada para azul destacado
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

// Adicione este método utilitário dentro do _ProjectListScreenState:
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Ativo':
        return Colors.green.shade400;
      case 'Inativo':
        return Colors.grey.shade500;
      case 'Concluído':
        return Colors.blue.shade400;
      case 'Em andamento':
        return Colors.orange.shade400;
      default:
        return Colors.blueGrey.shade300;
    }
  }
}
