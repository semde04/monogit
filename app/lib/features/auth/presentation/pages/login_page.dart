import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';

import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
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
                const SizedBox(height: 36),
                Text(
                  'Content de vous revoir',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Connectez-vous pour retrouver ce qui compte.'),
                const SizedBox(height: 30),
                Form(
                  key: _form,
                  child: Column(
                    children: [
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
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          errorText: _validationError(context, 'password'),
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
                        validator: (v) => v == null || v.isEmpty
                            ? 'Entrez votre mot de passe.'
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
                                    AuthLoginRequested(
                                      _email.text,
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
                            : const Text('Se connecter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Créer un compte'),
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

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
      width: 58,
      height: 58,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.search, color: Colors.white, size: 32),
      ),
      const SizedBox(width: 12),
      Text(
        'LostFound',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontSize: 29, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    ),
  );
}
