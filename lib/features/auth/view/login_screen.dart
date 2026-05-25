import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: 'aarav@wtf.fit');
  final _password = TextEditingController(text: '••••••••');
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      Validators.ensureEmail(_email.text);
      final auth = ref.read(authServiceProvider);
      await auth.signInTrainer(email: _email.text);
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/home');
    } on ValidationError catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, message: e.message);
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: "Couldn't sign in. Please try again.",
        error: e,
        stackTrace: st,
        tag: LogTag.auth,
        logMessage: 'sign-in failed',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: WtfWordmark(
                  height: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome back, coach',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to continue training your members.',
                style: TextStyle(color: AppColors.subtle, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'Sign in', loading: _busy, onPressed: _submit),
              const Spacer(),
              const Center(
                child: Text('Mock auth — any password works.',
                    style: TextStyle(fontSize: 11, color: AppColors.subtle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
