import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_group.dart';
import '../viewmodels/travel_group_viewmodel.dart';
import 'travel_group_detail_screen.dart';
import '../widgets/app_drawer.dart'; // Replace custom_bottom_nav import

class TravelGroupsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function toggleTheme;

  const TravelGroupsScreen({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<TravelGroupsScreen> createState() => _TravelGroupsScreenState();
}

class _TravelGroupsScreenState extends State<TravelGroupsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser le ViewModel
    Future.microtask(() {
      Provider.of<TravelGroupViewModel>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  // Afficher le dialogue pour créer un nouveau groupe
  void _showCreateGroupDialog() {
    _groupNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Créer un nouveau groupe'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _groupNameController,
            decoration: InputDecoration(
              labelText: 'Nom du groupe',
              hintText: 'Ex: Voyage à Paris',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom pour le groupe';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _createNewGroup();
                Navigator.pop(context);
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }

  // Créer un nouveau groupe
  void _createNewGroup() {
    final viewModel = Provider.of<TravelGroupViewModel>(context, listen: false);
    
    final newGroup = TravelGroup(
      name: _groupNameController.text,
      members: [], // Groupe vide initialement
    );
    
    viewModel.addGroup(newGroup);
  }

  // Naviguer vers l'écran de détail d'un groupe
  void _navigateToGroupDetail(String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelGroupDetailScreen(
          groupId: groupId,
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groupes de voyage'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/travel-groups'),
      body: Consumer<TravelGroupViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                viewModel.errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          if (viewModel.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun groupe de voyage',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: Icon(Icons.add),
                    label: Text('Créer un groupe'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: viewModel.groups.length,
            itemBuilder: (context, index) {
              final group = viewModel.groups[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(group.name[0].toUpperCase()),
                    backgroundColor: Colors.blue,
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créé le ${DateFormat('dd/MM/yyyy').format(group.createdAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${group.members.length} membre${group.members.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Confirmer la suppression du groupe
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Supprimer le groupe'),
                          content: Text('Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                viewModel.deleteGroup(group.id);
                                Navigator.pop(context);
                              },
                              child: Text('Supprimer'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () => _navigateToGroupDetail(group.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: Icon(Icons.add),
        tooltip: 'Créer un groupe',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}