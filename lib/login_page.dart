import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'state/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});
  final AuthCubit auth;
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

  Future<void> _login() async {
    if (widget.auth.state.status == AuthStatus.loading ||
        !_form.currentState!.validate()) {
      return;
    }
    await widget.auth.login(_email.text, _password.text);
    if (mounted) _password.clear();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    bloc: widget.auth,
    builder: (context, state) {
      final busy = state.status == AuthStatus.loading;
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE7EBF2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFE7EFFC),
                          child: Icon(
                            Icons.business_center_rounded,
                            color: Color(0xFF315C9B),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ورود به مدیریت کارکنان',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'برای ادامه وارد حساب کاربری خود شوید.',
                          style: TextStyle(color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 28),
                        if (state.message != null) ...[
                          Text(
                            state.message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _email,
                          enabled: !busy,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'ایمیل',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'ایمیل معتبر وارد کنید.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !busy,
                          textDirection: TextDirection.ltr,
                          obscureText: _obscure,
                          enableSuggestions: false,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'رمز عبور',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'نمایش رمز عبور'
                                  : 'پنهان کردن رمز عبور',
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'رمز عبور را وارد کنید.'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: busy ? null : _login,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('ورود'),
                            ),
                          ),
                        ),
                        if (state.status == AuthStatus.error)
                          TextButton(
                            onPressed: widget.auth.repository.logoutPending
                                ? widget.auth.logout
                                : widget.auth.restore,
                            child: Text(
                              widget.auth.repository.logoutPending
                                  ? 'تلاش دوباره برای خروج'
                                  : 'تلاش دوباره برای بازیابی نشست',
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
    },
  );
}
