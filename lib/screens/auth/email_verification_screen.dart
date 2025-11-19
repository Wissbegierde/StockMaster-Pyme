import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../home/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isResending = false;
  DateTime? _lastResendAttempt;
  static const Duration _resendCooldown = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkVerificationStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkVerificationStatus() async {
    // Verificar cada 3 segundos si el correo fue verificado
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isVerified = await authProvider.isEmailVerified();
        if (isVerified && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleResendEmail() async {
    // Verificar cooldown
    if (_lastResendAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastResendAttempt!);
      if (timeSinceLastAttempt < _resendCooldown) {
        final remainingMinutes = (_resendCooldown.inSeconds - timeSinceLastAttempt.inSeconds) ~/ 60;
        final remainingSeconds = (_resendCooldown.inSeconds - timeSinceLastAttempt.inSeconds) % 60;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor espera ${remainingMinutes}m ${remainingSeconds}s antes de reenviar el correo.',
            ),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() {
      _isResending = true;
      _lastResendAttempt = DateTime.now();
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.sendEmailVerification();

      if (mounted) {
        setState(() => _isResending = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Correo de verificación reenviado. Revisa tu bandeja de entrada y spam.'
                  : authProvider.errorMessage ?? 'Error al reenviar correo',
            ),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        
        final errorMessage = authProvider.errorMessage ?? 'Error al reenviar correo: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _isResending,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48, // Restar padding
                    ),
                    child: IntrinsicHeight(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            _buildIcon(),
                            const SizedBox(height: 32),
                            _buildTitle(),
                            const SizedBox(height: 16),
                            _buildMessage(),
                            const SizedBox(height: 32),
                            _buildResendButton(),
                            const SizedBox(height: 24),
                            _buildSkipButton(),
                            const Spacer(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        FontAwesomeIcons.envelope,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Verifica tu correo',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Hemos enviado un correo de verificación a:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.circleInfo,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Haz clic en el enlace del correo para verificar tu cuenta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'La verificación se realizará automáticamente cuando hagas clic en el enlace.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Si no encuentras el correo, revisa tu carpeta de spam.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildResendButton() {
    final canResend = _lastResendAttempt == null || 
        DateTime.now().difference(_lastResendAttempt!) >= _resendCooldown;
    
    return Column(
      children: [
        TextButton.icon(
          onPressed: (_isResending || !canResend) ? null : _handleResendEmail,
          icon: const Icon(FontAwesomeIcons.arrowRotateRight),
          label: const Text('Reenviar correo de verificación'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        if (!canResend && _lastResendAttempt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Espera antes de reenviar (protección anti-spam)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      child: Text(
        'Continuar sin verificar (por ahora)',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

