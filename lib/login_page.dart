import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isAuthenticating = false;
  bool _showPasswordForm = false;
  bool _obscurePassword = true;
  String _statusMessage = 'Initializing authentication...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBiometrics();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeBiometrics() async {
    try {
      if (!mounted) return;
      
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!mounted) return;

      if (!isAvailable || !isDeviceSupported) {
        setState(() {
          _statusMessage = 'Biometric authentication not available';
          _showPasswordForm = true;
        });
        return;
      }

      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();

      if (!mounted) return;

      if (availableBiometrics.contains(BiometricType.face)) {
        setState(() {
          _statusMessage = 'Face ID ready - tap to authenticate';
        });
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        setState(() {
          _statusMessage = 'Touch ID ready - tap to authenticate';
        });
      } else {
        setState(() {
          _statusMessage = 'No biometric authentication available';
          _showPasswordForm = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Authentication setup failed - using password login';
          _showPasswordForm = true;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating with biometrics...';
    });

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _isAuthenticating = false;
      });

      if (authenticated) {
        _navigateToHome();
      } else {
        setState(() {
          _statusMessage = 'Authentication cancelled';
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'Authentication error: ${e.message ?? 'Unknown error'}';
        });
      }
    }
  }

  Future<void> _authenticateWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Verifying credentials...';
    });

    // Simulate network delay for authentication
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    
    if (_validateCredentials(username, password)) {
      _navigateToHome();
    } else {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Invalid username or password';
      });
    }
  }

  bool _validateCredentials(String username, String password) {
    const demoCredentials = {
      'admin': 'password123',
      'user': 'user123',
      'demo': 'demo123',
    };
    return demoCredentials[username.toLowerCase()] == password;
  }

  void _toggleAuthenticationMode() {
    setState(() {
      _showPasswordForm = !_showPasswordForm;
      _statusMessage = _showPasswordForm 
          ? 'Enter your credentials below'
          : 'Face ID ready - tap to authenticate';
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile 401k Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       kToolbarHeight - 48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAppIcon(),
              const SizedBox(height: 32),
              _buildWelcomeText(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 32),
              if (_showPasswordForm) 
                _buildPasswordForm()
              else 
                _buildBiometricButton(),
              const SizedBox(height: 24),
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Icon(
        Icons.security,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to continue to your account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (_isAuthenticating)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _showPasswordForm ? Icons.password : Icons.face,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticateWithPassword,
              icon: _isAuthenticating 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isAuthenticating ? 'Signing In...' : 'Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDemoCredentials(),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isAuthenticating ? null : _authenticateWithBiometrics,
        icon: _isAuthenticating 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.fingerprint),
        label: Text(_isAuthenticating ? 'Authenticating...' : 'Authenticate'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo Credentials:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'admin/password123 • user/user123 • demo/demo123',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton.icon(
      onPressed: _isAuthenticating ? null : _toggleAuthenticationMode,
      icon: Icon(_showPasswordForm ? Icons.fingerprint : Icons.password),
      label: Text(
        _showPasswordForm 
            ? 'Use Biometric Authentication' 
            : 'Use Password Instead',
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile 401k Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Authentication Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Welcome to your secure Mobile 401k application',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
