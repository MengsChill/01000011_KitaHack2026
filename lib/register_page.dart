import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late ScrollController _scrollController;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double _headerOpacity = 1.0;

  bool _hasLength = false;
  bool _hasUpper = false;
  bool _hasSpecial = false;
  bool _hasMix = false;
  bool _passwordsMatch = true;
  bool _isCaregiver = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _headerOpacity = (1.0 - (_scrollController.offset / 80)).clamp(
          0.0,
          1.0,
        );
      });
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPassword(String password) {
    setState(() {
      _hasLength = password.length >= 8;
      _hasUpper = password.contains(RegExp(r'[A-Z]'));
      _hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _hasMix =
          password.contains(RegExp(r'[a-zA-Z]')) &&
          password.contains(RegExp(r'[0-9]'));
    });
  }

  void _checkMatch(String confirmPass) {
    setState(() {
      _passwordsMatch = _passwordController.text == confirmPass;
    });
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName("${_firstNameController.text.trim()} ${_lastNameController.text.trim()}");

        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'name': "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
          'role': _isCaregiver ? 'caregiver' : 'blind_user',
          'linked_accounts': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        
        // Navigate based on role
        if (_isCaregiver) {
          Navigator.pushReplacementNamed(context, '/caregiver_home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Registration failed";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF0F172A);
    const Color primaryAccent = Color(0xFFF570B2);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IgnorePointer(
          ignoring: _headerOpacity == 0,
          child: Opacity(
            opacity: _headerOpacity,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 50),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryDark, primaryAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Join the Pole Network.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedInput(
                              _firstNameController,
                              "First Name",
                              false,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildAnimatedInput(
                              _lastNameController,
                              "Last Name",
                              false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildAnimatedInput(
                        _emailController,
                        "Email Address",
                        false,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),

                      _buildAnimatedInput(
                        _passwordController,
                        "Password",
                        true,
                        isVisible: _isPasswordVisible,
                        onVisibilityToggle: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        onChanged: _checkPassword,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          top: 15,
                          bottom: 20,
                          left: 5,
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _buildChip(_hasLength, "8+ Chars"),
                            _buildChip(_hasUpper, "Uppercase"),
                            _buildChip(_hasSpecial, "Symbol"),
                            _buildChip(_hasMix, "Num/Alpha"),
                          ],
                        ),
                      ),

                      _buildAnimatedInput(
                        _confirmPasswordController,
                        "Confirm Password",
                        true,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () => setState(
                          () => _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                        ),
                        onChanged: _checkMatch,
                        isError: !_passwordsMatch,
                      ),
                      if (!_passwordsMatch)
                        const Padding(
                          padding: EdgeInsets.only(top: 5, left: 5),
                          child: Text(
                            "Passwords do not match",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "I am a Caregiver",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Switch(
                              value: _isCaregiver,
                              onChanged: (val) {
                                setState(() {
                                  _isCaregiver = val;
                                });
                              },
                              activeThumbColor: primaryAccent,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient:
                              (_hasLength &&
                                  _hasUpper &&
                                  _hasSpecial &&
                                  _hasMix &&
                                  _passwordsMatch)
                              ? const LinearGradient(
                                  colors: [
                                  const Color(0xFFF570B2),
                                  const Color(0xFFFF99CC),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:
                              (_hasLength &&
                                  _hasUpper &&
                                  _hasSpecial &&
                                  _hasMix &&
                                  _passwordsMatch)
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF570B2,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap:
                                (_hasLength &&
                                    _hasUpper &&
                                    _hasSpecial &&
                                    _hasMix &&
                                    _passwordsMatch &&
                                    !_isLoading)
                                ? _register
                                : null,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "REGISTER",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInput(
    TextEditingController controller,
    String label,
    bool isPassword, {
    bool? isVisible,
    VoidCallback? onVisibilityToggle,
    Function(String)? onChanged,
    IconData? icon,
    bool isError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && (isVisible == false),
        onChanged: onChanged,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFFF570B2), size: 20)
              : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible! ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[400],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(bool valid, String text) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: valid ? const Color(0xFF10B981) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? Icons.check : Icons.circle,
            size: 10,
            color: valid ? const Color(0xFF047857) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: valid ? const Color(0xFF047857) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
