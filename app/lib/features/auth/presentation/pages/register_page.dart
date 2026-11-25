import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';

import '../bloc/auth_bloc.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _matricule = TextEditingController(),
      _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _matricule.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandMark(),
                const SizedBox(height: 32),
                Text(
                  'Rejoignez LostFound',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un objet retrouvé peut changer la journée de quelqu’un.',
                ),
                const SizedBox(height: 30),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _validationError(context, 'name'),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Entrez votre nom.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Adresse e-mail',
                          prefixIcon: const Icon(Icons.mail_outline),
                          errorText: _validationError(context, 'email'),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Entrez une adresse e-mail valide.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _matricule,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Matricule étudiant',
                          hintText: 'Ex. 2025-12345',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          errorText: _validationError(context, 'matricule'),
                        ),
                        validator: (value) => value == null || value.trim().length < 3
                            ? 'Entrez votre matricule étudiant.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: _validationError(context, 'password'),
                          helperText: '12 caractères minimum',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 12
                            ? 'Utilisez au moins 12 caractères.'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.failure != null &&
                          (state.failure is! ValidationFailure ||
                              (state.failure as ValidationFailure)
                                  .fields
                                  .isEmpty))
                        AuthError(message: state.failure!.message),
                      FilledButton(
                        onPressed: state.loading
                            ? null
                            : () {
                                if (_form.currentState!.validate()) {
                                  context.read<AuthBloc>().add(
                                    AuthRegisterRequested(
                                      _name.text,
                                      _email.text,
                                      _matricule.text,
                                      _password.text,
                                    ),
                                  );
                                }
                              },
                        child: state.loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Créer mon compte'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('J’ai déjà un compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String? _validationError(BuildContext context, String field) {
  final failure = context.watch<AuthBloc>().state.failure;
  return failure is ValidationFailure ? failure.fields[field] : null;
}
