import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'strings.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const _authRedirectUrl = 'com.nightgoat.hungrynatsu://auth-callback/';
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        if (auth.currentUser?.isAnonymous == true) {
          await auth.updateUser(
            UserAttributes(email: _email.text.trim(), password: _password.text),
            emailRedirectTo: _authRedirectUrl,
          );
          if (mounted) {
            setState(() => _message = S.of(context).checkEmail);
          }
        } else {
          final response = await auth.signUp(
            email: _email.text.trim(),
            password: _password.text,
            emailRedirectTo: _authRedirectUrl,
          );
          if (mounted && response.session == null) {
            setState(() => _message = S.of(context).checkEmail);
          }
        }
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = S.of(context).error(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hungry Natsu')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/natsu_icon.png',
                        width: 108,
                        height: 108,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _register ? s.register : s.signIn,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: s.email),
                    validator: (value) =>
                        value != null &&
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value.trim())
                        ? null
                        : s.invalidEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(labelText: s.password),
                    validator: (value) => value != null && value.length >= 6
                        ? null
                        : s.shortPassword,
                  ),
                  const SizedBox(height: 20),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy ? s.saving : (_register ? s.register : s.signIn),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _message = null;
                          }),
                    child: Text(_register ? s.haveAccount : s.createAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
