import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/web/sidebar_menu.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _alertNotifications = true;
  bool _dailyReport = true;
  bool _weeklyReport = true;
  String _alertThreshold = 'alto';
  String _language = 'pt_BR';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedIndex: 5,
            onItemSelected: (index) {
              final routes = [
                AppRoutes.webDashboard,
                AppRoutes.webTeam,
                AppRoutes.webReports,
                AppRoutes.webAlerts,
                AppRoutes.webHeatmap,
                AppRoutes.webSettings,
              ];
              if (index != 5) {
                Navigator.pushReplacementNamed(context, routes[index]);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Organization
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.business,
                                            color: AppTheme.primaryBlue),
                                        SizedBox(width: 12),
                                        Text(
                                          'Organizacao',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildInfoRow(
                                        context, 'Nome', 'Empresa Comercio LTDA'),
                                    _buildInfoRow(
                                        context, 'Plano', 'Profissional'),
                                    _buildInfoRow(context, 'Funcionarios',
                                        '150 ativos'),
                                    _buildInfoRow(
                                        context, 'Administrador',
                                        authProvider.user?.nome ?? ''),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Appearance
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.palette,
                                            color: AppTheme.primaryBlue),
                                        SizedBox(width: 12),
                                        Text(
                                          'Aparencia',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      title: const Text('Modo Escuro'),
                                      subtitle: const Text(
                                          'Altera o tema visual do painel'),
                                      value: themeProvider.isDarkMode,
                                      onChanged: (_) =>
                                          themeProvider.toggleTheme(),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: const Text('Idioma'),
                                      subtitle: Text(
                                        _language == 'pt_BR'
                                            ? 'Portugues (Brasil)'
                                            : 'Ingles',
                                      ),
                                      trailing: DropdownButton<String>(
                                        value: _language,
                                        underline:
                                            const SizedBox.shrink(),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'pt_BR',
                                            child: Text(
                                                'Portugues (Brasil)'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'en',
                                            child: Text('English'),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                            () => _language = v!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Notifications
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.notifications,
                                            color: AppTheme.primaryBlue),
                                        SizedBox(width: 12),
                                        Text(
                                          'Notificacoes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      title:
                                          const Text('Notificacoes por e-mail'),
                                      subtitle: const Text(
                                          'Receber resumos por e-mail'),
                                      value: _emailNotifications,
                                      onChanged: (v) => setState(
                                          () => _emailNotifications = v),
                                    ),
                                    const Divider(),
                                    SwitchListTile(
                                      title:
                                          const Text('Alertas de risco'),
                                      subtitle: const Text(
                                          'Ser notificado quando um funcionario atinge nivel de risco alto'),
                                      value: _alertNotifications,
                                      onChanged: (v) => setState(
                                          () => _alertNotifications = v),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: const Text(
                                          'Limite de alerta'),
                                      subtitle: const Text(
                                          'Nivel minimo para gerar alerta'),
                                      trailing:
                                          DropdownButton<String>(
                                        value: _alertThreshold,
                                        underline:
                                            const SizedBox.shrink(),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'moderado',
                                            child: Text('Moderado'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'alto',
                                            child: Text('Alto'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'critico',
                                            child: Text('Critico'),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                            () => _alertThreshold =
                                                v!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Reports
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.summarize,
                                            color: AppTheme.primaryBlue),
                                        SizedBox(width: 12),
                                        Text(
                                          'Relatorios Automaticos',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      title: const Text(
                                          'Relatorio diario'),
                                      subtitle: const Text(
                                          'Resumo diario enviado as 18h'),
                                      value: _dailyReport,
                                      onChanged: (v) => setState(
                                          () => _dailyReport = v),
                                    ),
                                    const Divider(),
                                    SwitchListTile(
                                      title: const Text(
                                          'Relatorio semanal'),
                                      subtitle: const Text(
                                          'Resumo semanal enviado as sextas-feiras'),
                                      value: _weeklyReport,
                                      onChanged: (v) => setState(
                                          () => _weeklyReport = v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User management
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.manage_accounts,
                                            color: AppTheme.primaryBlue),
                                        SizedBox(width: 12),
                                        Text(
                                          'Gestao de Usuarios',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ListTile(
                                      leading: const Icon(
                                          Icons.person_add),
                                      title: const Text(
                                          'Adicionar funcionario'),
                                      subtitle: const Text(
                                          'Cadastrar novo membro na equipe'),
                                      trailing: const Icon(
                                          Icons.chevron_right),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Funcionalidade de cadastro em desenvolvimento'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading:
                                          const Icon(Icons.groups),
                                      title: const Text(
                                          'Gerenciar equipes'),
                                      subtitle: const Text(
                                          'Configurar setores e lideres'),
                                      trailing: const Icon(
                                          Icons.chevron_right),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Funcionalidade de gestao em desenvolvimento'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Configuracoes salvas com sucesso'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.save),
                                label: const Text(
                                    'Salvar Configuracoes'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Configuracoes',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
