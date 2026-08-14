import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../managers/vault_manager.dart';
import '../managers/auth_manager.dart';
import '../managers/terminal_session_manager.dart';
import '../models/folder.dart';
import '../models/server.dart';
import '../models/credential.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/create_server_dialog.dart';
import '../widgets/create_credential_dialog.dart';
import '../widgets/terminal_tab.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // We use this to toggle between showing the Servers tree and Credentials list in the sidebar.
  int _selectedIndex = 0; // 0 for Servers, 1 for Credentials
  final Set<String> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaultManager>().loadData();
    });
  }

  Future<void> _showCreateFolderDialog(BuildContext context, {String? parentFolderId}) async {
    final Folder? newFolder = await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(parentFolderId: parentFolderId),
    );

    if (newFolder != null && context.mounted) {
      context.read<VaultManager>().addFolder(newFolder);
    }
  }

  Future<void> _showCreateServerDialog(BuildContext context, {String? folderId}) async {
    final vaultManager = context.read<VaultManager>();
    final Server? newServer = await showDialog(
      context: context,
      builder: (context) => CreateServerDialog(
        folders: vaultManager.folders,
        credentials: vaultManager.credentials,
        initialFolderId: folderId,
      ),
    );

    if (newServer != null && context.mounted) {
      context.read<VaultManager>().addServer(newServer);
    }
  }

  Future<void> _showEditServerDialog(BuildContext context, Server server) async {
    final vaultManager = context.read<VaultManager>();
    final Server? updatedServer = await showDialog(
      context: context,
      builder: (context) => CreateServerDialog(
        folders: vaultManager.folders,
        credentials: vaultManager.credentials,
        serverToEdit: server,
      ),
    );

    if (updatedServer != null && context.mounted) {
      context.read<VaultManager>().updateServer(updatedServer);
    }
  }

  Future<void> _showCreateCredentialDialog(BuildContext context) async {
    final String? authType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Credential Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Basic (SSH Password)'),
                onTap: () => Navigator.of(context).pop('password'),
              ),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Private Key'),
                onTap: () => Navigator.of(context).pop('key'),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Basic (Web)'),
                onTap: () => Navigator.of(context).pop('web_basic'),
              ),
            ],
          ),
        );
      },
    );

    if (authType == null || !context.mounted) return;

    final Credential? newCredential = await showDialog(
      context: context,
      builder: (context) => CreateCredentialDialog(initialAuthType: authType),
    );

    if (newCredential != null && context.mounted) {
      context.read<VaultManager>().addCredential(newCredential);
    }
  }

  Future<void> _showEditCredentialDialog(BuildContext context, Credential credential) async {
    final Credential? updatedCredential = await showDialog(
      context: context,
      builder: (context) => CreateCredentialDialog(credentialToEdit: credential),
    );

    if (updatedCredential != null && context.mounted) {
      context.read<VaultManager>().updateCredential(updatedCredential);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String itemName, String itemType) async {
    final controller = TextEditingController();
    bool isConfirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Delete $itemType'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This action cannot be undone.', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Text('To confirm deletion, type exactly: "$itemName"'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Item name',
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: controller.text == itemName
                      ? () {
                          isConfirmed = true;
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    return isConfirmed;
  }

  Future<void> _showCredentialDetailsDialog(BuildContext context, Credential credential) async {
    bool obscureSecret = true;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Credential: ${credential.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCopyableField('Username', credential.username, false, () {
                    Clipboard.setData(ClipboardData(text: credential.username));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username copied')));
                  }),
                  const SizedBox(height: 16),
                  _buildCopyableField('Secret / Password', credential.secretPayload, obscureSecret, () {
                    Clipboard.setData(ClipboardData(text: credential.secretPayload));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret copied')));
                  }, onToggleObscure: () {
                    setState(() {
                      obscureSecret = !obscureSecret;
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCopyableField(String label, String value, bool obscureText, VoidCallback onCopy, {VoidCallback? onToggleObscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  obscureText ? '••••••••••••' : value,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            if (onToggleObscure != null)
              IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggleObscure,
              ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: 'Copy',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultManager = context.watch<VaultManager>();
    final sessionManager = context.watch<TerminalSessionManager>();

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset('Icono.png', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Colors.black)),
                ),
              ),
            ),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.computer_outlined),
                selectedIcon: Icon(Icons.computer),
                label: Text('Clusters'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key),
                label: Text('Vault'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lock_outline),
                        tooltip: 'Lock Vault / Change DB',
                        onPressed: () {
                          context.read<AuthManager>().lock();
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '© 2026',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Contextual Sidebar
          if (_selectedIndex == 1 || _selectedIndex == 2)
            Container(
              width: 280,
              color: Theme.of(context).colorScheme.surface,
              child: _selectedIndex == 1
                  ? _buildTreeSidebar(vaultManager, sessionManager)
                  : _buildCredentialsList(vaultManager),
            ),
          if (_selectedIndex == 1 || _selectedIndex == 2)
            const VerticalDivider(width: 1, thickness: 1),
          // Main Content Area
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _buildMainContent(vaultManager, sessionManager),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(VaultManager vaultManager, TerminalSessionManager sessionManager) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview(vaultManager);
      case 3:
        return const SettingsScreen();
      default:
        return _buildMainArea(sessionManager);
    }
  }

  Widget _buildDashboardOverview(VaultManager vaultManager) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Space',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Clusters', vaultManager.servers.length.toString(), Icons.computer, 0.7),
              const SizedBox(width: 24),
              _buildStatCard('Credentials', vaultManager.credentials.length.toString(), Icons.vpn_key, 0.4),
              const SizedBox(width: 24),
              _buildStatCard('Folders', vaultManager.folders.length.toString(), Icons.folder, 0.9),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'Recent Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(child: Text('Cluster Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(child: Text('Folder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vaultManager.servers.isEmpty ? 1 : vaultManager.servers.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        if (vaultManager.servers.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No clusters configured yet.', style: TextStyle(color: Colors.white54)),
                          );
                        }
                        final server = vaultManager.servers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(server.name, style: const TextStyle(color: Colors.white))),
                              Expanded(child: Text('${server.host}:${server.port}', style: const TextStyle(color: Colors.white70))),
                              Expanded(child: Text(
                                server.folderId != null 
                                  ? (vaultManager.folders.where((f) => f.id == server.folderId).firstOrNull?.name ?? 'Root') 
                                  : 'Root', 
                                style: const TextStyle(color: Colors.white70)
                              )),
                              const Expanded(child: Text('Ready', style: TextStyle(color: Colors.greenAccent))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, double progress) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(String title, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onAdd,
            tooltip: 'Add',
          ),
        ],
      ),
    );
  }

  Widget _buildTreeSidebar(VaultManager vaultManager, TerminalSessionManager sessionManager) {
    if (vaultManager.isLoading) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CLUSTERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.create_new_folder, size: 16),
                    onPressed: () => _showCreateFolderDialog(context),
                    tooltip: 'Add Root Folder',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _showCreateServerDialog(context),
                    tooltip: 'Add Server',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: _buildFolderNodes(null, vaultManager, sessionManager, 0),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFolderNodes(String? parentId, VaultManager vaultManager, TerminalSessionManager sessionManager, int depth) {
    final nodes = <Widget>[];

    final childFolders = vaultManager.folders.where((f) => f.parentFolderId == parentId).toList();
    final childServers = vaultManager.servers.where((s) => s.folderId == parentId).toList();

    for (final folder in childFolders) {
      nodes.add(
        ExpansionTile(
          key: PageStorageKey<String>(folder.id),
          initiallyExpanded: _expandedFolders.contains(folder.id),
          onExpansionChanged: (expanded) {
            if (expanded) {
              _expandedFolders.add(folder.id);
            } else {
              _expandedFolders.remove(folder.id);
            }
          },
          tilePadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 8.0),
          leading: const Icon(Icons.folder, size: 18),
          title: Text(folder.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 16),
                onPressed: () => _showCreateFolderDialog(context, parentFolderId: folder.id),
                tooltip: 'Add Sub-Folder',
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => _showCreateServerDialog(context, folderId: folder.id),
                tooltip: 'Add Server',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: () async {
                  if (await _confirmDelete(context, folder.name, 'Folder')) {
                    vaultManager.deleteFolder(folder.id);
                  }
                },
                tooltip: 'Delete Folder',
              ),
            ],
          ),
          children: _buildFolderNodes(folder.id, vaultManager, sessionManager, depth + 1),
        ),
      );
    }

    if (parentId == null && childServers.isNotEmpty && childFolders.isNotEmpty) {
      nodes.add(const Divider());
      nodes.add(
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text('ROOT SERVERS', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    for (final server in childServers) {
      nodes.add(_buildServerTile(server, vaultManager, sessionManager, depth));
    }

    return nodes;
  }

  Widget _buildServerTile(Server server, VaultManager vaultManager, TerminalSessionManager sessionManager, int depth) {
    final credential = vaultManager.credentials.where((c) => c.id == server.credentialId).firstOrNull;
    
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 8.0),
      leading: const Icon(Icons.computer, size: 18),
      title: Text(server.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text('${server.host}:${server.port}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () => _showEditServerDialog(context, server),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            onPressed: () async {
              if (await _confirmDelete(context, server.name, 'Server')) {
                vaultManager.deleteServer(server.id);
              }
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      onTap: () {
        sessionManager.openSession(server, credential);
      },
    );
  }

  Widget _buildCredentialsList(VaultManager vaultManager) {
    if (vaultManager.isLoading) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }
    return Column(
      children: [
        _buildSidebarHeader('CREDENTIALS', () => _showCreateCredentialDialog(context)),
        if (vaultManager.credentials.isEmpty)
           const Padding(padding: EdgeInsets.all(16), child: Text('No credentials found.', style: TextStyle(color: Colors.grey))),
        ...vaultManager.credentials.map((cred) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 8),
            leading: const Icon(Icons.vpn_key, size: 16),
            title: Text(cred.name, style: const TextStyle(fontSize: 13)),
            onTap: () => _showCredentialDetailsDialog(context, cred),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 14), onPressed: () => _showEditCredentialDialog(context, cred)),
                IconButton(icon: const Icon(Icons.delete, size: 14), onPressed: () async {
                  if (await _confirmDelete(context, cred.name, 'Credential')) vaultManager.deleteCredential(cred.id);
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainArea(TerminalSessionManager sessionManager) {
    if (sessionManager.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terminal, size: 64, color: Theme.of(context).primaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No active SSH sessions.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a cluster from the sidebar to connect.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sessionManager.sessions.length,
            itemBuilder: (context, index) {
              final session = sessionManager.sessions[index];
              final isActive = index == sessionManager.activeTabIndex;
              
              return GestureDetector(
                onTap: () => sessionManager.setActiveTab(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? Theme.of(context).colorScheme.surface : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        session.isConnected ? Icons.terminal : Icons.warning_amber,
                        size: 16,
                        color: session.isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(session.server.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => sessionManager.closeSession(session.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Active Terminal Content
        Expanded(
          child: TerminalTab(
            key: ValueKey(sessionManager.sessions[sessionManager.activeTabIndex].id),
            session: sessionManager.sessions[sessionManager.activeTabIndex],
          ),
        ),
      ],
    );
  }
}
