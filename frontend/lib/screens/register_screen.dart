import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_button.dart';

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
  final _cargoController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      nome: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      cargo: _cargoController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      if (kIsWeb || (user != null && user.isLider)) {
        Navigator.pushReplacementNamed(context, AppRoutes.webDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mobileHome);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Erro ao criar conta'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.secondaryTeal, Color(0xFF00897B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 420 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        child: const Icon(
                          Icons.person_add_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: const Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'Preencha seus dados para se cadastrar',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                CustomTextField(
                                  label: 'Nome completo',
                                  hint: 'Seu nome',
                                  controller: _nameController,
                                  prefixIcon: Icons.person_outline,
                                  validator: Validators.validateName,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'E-mail',
                                  hint: 'seu@email.com',
                                  controller: _emailController,
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Cargo',
                                  hint: 'Ex: Vendedor, Caixa, Gerente',
                                  controller: _cargoController,
                                  prefixIcon: Icons.work_outline,
                                  validator: Validators.validateCargo,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Senha',
                                  hint: 'Minimo 6 caracteres',
                                  controller: _passwordController,
                                  prefixIcon: Icons.lock_outlined,
                                  obscureText: true,
                                  validator: Validators.validatePassword,
                                ),
                                const SizedBox(height: 28),
                                CustomButton(
                                  text: 'Cadastrar',
                                  onPressed: _register,
                                  isLoading: authProvider.isLoading,
                                  icon: Icons.person_add_rounded,
                                  color: AppTheme.secondaryTeal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Ja tem conta? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Entrar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
