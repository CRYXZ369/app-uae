import 'package:material_ui/material_ui.dart';

import '../domain/auth_session.dart';

enum LoginStatus {
  authenticated,
  invalidCredentials,
  unavailable,
  sessionStorageFailure,
}

class LoginResult {
  const LoginResult._(this.status, {this.session});

  const LoginResult.authenticated(AuthSession session)
    : this._(LoginStatus.authenticated, session: session);

  const LoginResult.invalidCredentials()
    : this._(LoginStatus.invalidCredentials);

  const LoginResult.unavailable() : this._(LoginStatus.unavailable);

  const LoginResult.sessionStorageFailure()
    : this._(LoginStatus.sessionStorageFailure);

  final LoginStatus status;
  final AuthSession? session;
}

typedef LoginHandler = Future<LoginResult> Function(
  String email,
  String password,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onLogin,
    this.showEphemeralSessionNotice = false,
    super.key,
  });

  final LoginHandler onLogin;
  final bool showEphemeralSessionNotice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    late final LoginResult result;
    try {
      result = await widget.onLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } finally {
      if (mounted) {
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
      }
    }

    if (!mounted) {
      return;
    }

    switch (result.status) {
      case LoginStatus.authenticated:
        return;
      case LoginStatus.invalidCredentials:
        setState(
          () => _errorMessage = 'El correo o la contraseña son incorrectos.',
        );
      case LoginStatus.unavailable:
        setState(
          () => _errorMessage =
              'No se pudo conectar al servicio de inicio de sesión.',
        );
      case LoginStatus.sessionStorageFailure:
        setState(
          () => _errorMessage = 'No se pudo guardar la sesión de forma segura.',
        );
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Ingresa tu correo institucional.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Ingresa un correo con formato válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    return null;
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xfff3f7fc),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 3,
                shadowColor: const Color(0xff214b78).withValues(alpha: .09),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(color: Color(0xffe8eef6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xffedf3fc),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                size: 31,
                                color: Color(0xff214b78),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'UNIVERSIDAD ALBERT EINSTEIN',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xff315d96),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'App Unificada UAE',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: const Color(0xff1e3553),
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Tu espacio académico digital',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xff70819a)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Bienvenido de vuelta',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: const Color(0xff1e3553),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ingresa tus datos para continuar',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xff70819a)),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo institucional',
                              hintText: 'nombre@institucion.edu',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: _validateEmail,
                            onChanged: (_) => _clearError(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _isPasswordObscured,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _isPasswordObscured
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _isPasswordObscured =
                                            !_isPasswordObscured,
                                      ),
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                            onChanged: (_) => _clearError(),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colors.onErrorContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: colors.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: const Color(0xff214b78),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Iniciando sesión...'),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Iniciar sesión'),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                          ),
                          if (widget.showEphemeralSessionNotice) ...[
                            const SizedBox(height: 16),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 17,
                                  color: Color(0xff70819a),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Demo en red local: la sesión solo permanece mientras esta pestaña esté abierta.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff70819a),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
