import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'successScreen.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value, 0),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // form + shake
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();

  // controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // ui state
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // validation flags (for bounce)
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  // avatar
  final List<String> _avatarEmojis = ['🦋', '🐢', '🐻', '🐱', '🦒'];
  int? _selectedAvatarIndex;
  double _passwordStrength = 0.0; // 0.0 - 1.0
  final List<String> _earnedBadges = [];

  double _lastMilestoneShown = 0.0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);

    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _dobController.addListener(() => setState(() {}));
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _updateStrength() {
    final p = _passwordController.text;
    double score = 0;

    if (p.isEmpty) score = 0;
    else {
      // length
      if (p.length >= 6) score += 0.25;
      if (p.length >= 10) score += 0.15;

      // character classes
      final hasUpper = p.contains(RegExp(r'[A-Z]'));
      final hasLower = p.contains(RegExp(r'[a-z]'));
      final hasDigit = p.contains(RegExp(r'[0-9]'));
      final hasSymbol = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));

      int kinds = 0;
      if (hasUpper) kinds++;
      if (hasLower) kinds++;
      if (hasDigit) kinds++;
      if (hasSymbol) kinds++;

      score += (kinds * 0.15); 
    }

    if (score > 1.0) score = 1.0;
    setState(() {
      _passwordStrength = score;
    });
  }

  Color _strengthColor(double v) {
    if (v < 0.34) return Colors.red;
    if (v < 0.67) return Colors.orange;
    return Colors.green;
  }

  String _strengthLabel(double v) {
    if (v < 0.34) return 'Weak';
    if (v < 0.67) return 'Medium';
    return 'Strong';
  }

  double _progress() {
    int done = 0;
    if (_nameController.text.trim().isNotEmpty) done++;
    if (_emailController.text.trim().isNotEmpty) done++;
    if (_dobController.text.trim().isNotEmpty) done++;
    if (_passwordController.text.trim().isNotEmpty) done++;
    if (_selectedAvatarIndex != null) done++;
    return done / 5.0;
  }

  String _milestoneMessage(double p) {
    if (p >= 1.0) return 'Ready for adventure!';
    if (p >= 0.75) return 'Almost done...';
    if (p >= 0.50) return 'Halfway there!';
    if (p >= 0.25) return 'Great start.';
    return '';
  }

  void _maybeShowMilestoneSnack(double p) {

    double milestone;
    if (p >= 1.0 && _lastMilestoneShown < 1.0) milestone = 1.0;
    else if (p >= 0.75 && _lastMilestoneShown < 0.75) milestone = 0.75;
    else if (p >= 0.50 && _lastMilestoneShown < 0.50) milestone = 0.50;
    else if (p >= 0.25 && _lastMilestoneShown < 0.25) milestone = 0.25;
    else return;

    _lastMilestoneShown = milestone;
    final msg = _milestoneMessage(milestone);
    if (msg.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_){
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(msg),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 900),
                ),
             );
        }
    });

  }
    
  
  void _submitForm() {
    // update badges before validation to keep logic in one place
    _earnedBadges.clear();

    // profile completer: all fields + avatar
    final allFilled = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _dobController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _selectedAvatarIndex != null;

    if (allFilled) {
      _earnedBadges.add('profile completer');
    }

    // strong password
    if (_passwordStrength >= 0.8) {
      _earnedBadges.add('strong password master!');
    }

    // early bird
    if (DateTime.now().hour < 12) {
      _earnedBadges.add('the early bird gets the worm');
    }

    if (_formKey.currentState!.validate() && allFilled) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              userName: _nameController.text,
              avatarEmoji: _selectedAvatarIndex != null
                  ? _avatarEmojis[_selectedAvatarIndex!]
                  : null,
              badges: List<String>.from(_earnedBadges),
            ),
          ),
        );
      });
    } else {
      // shake if invalid
      _shakeKey.currentState?.shake();
      // also nudge progress milestone check so user sees message
      _maybeShowMilestoneSnack(_progress());
    }
  }

// user interface stuff
  @override
  Widget build(BuildContext context) {
    final p = _progress();
    _maybeShowMilestoneSnack(p);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ShakeWidget(
          key: _shakeKey,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.blue[800]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Complete your profile.',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProgressTracker(progress: p, label: _milestoneMessage(p)),
                  const SizedBox(height: 24),

                  _AvatarPicker(
                    emojis: _avatarEmojis,
                    selectedIndex: _selectedAvatarIndex,
                    onSelected: (idx) {
                      setState(() => _selectedAvatarIndex = idx);
                    },
                  ),
                  const SizedBox(height: 24),

                  // name (bouncy)
                  _buildBouncyField(
                    label: 'Adventure Name',
                    controller: _nameController,
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'What should we call you?';
                      }
                      return null;
                    },
                    onValidChange: (isValid) =>
                        setState(() => _isNameValid = isValid),
                    isValid: _isNameValid,
                  ),
                  const SizedBox(height: 16),

                  // email (bouncy)
                  _buildBouncyField(
                    label: 'Email Address',
                    controller: _emailController,
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'We need your email for adventure updates!';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Come on now! That doesn\'t look like a valid email';
                      }
                      return null;
                    },
                    onValidChange: (isValid) =>
                        setState(() => _isEmailValid = isValid),
                    isValid: _isEmailValid,
                  ),
                  const SizedBox(height: 16),

                  // dob
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: _selectDate,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'When did your adventure begin?';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // password (bouncy) + strength meter
                  _buildBouncyField(
                    label: 'Secret Password',
                    controller: _passwordController,
                    icon: Icons.lock,
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Every adventurer needs a secret password!';
                      }
                      if (value.length < 6) {
                        return 'You can do better than that! At least 6 characters';
                      }
                      return null;
                    },
                    onValidChange: (isValid) =>
                        setState(() => _isPasswordValid = isValid),
                    isValid: _isPasswordValid,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // strength bar + label
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: _passwordStrength,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _strengthColor(_passwordStrength),
                            ),
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _strengthLabel(_passwordStrength),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _strengthColor(_passwordStrength),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // submit
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isLoading ? 60 : double.infinity,
                    height: 60,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              elevation: 5,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Start My Adventure',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.rocket_launch,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBouncyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    required void Function(bool) onValidChange,
    required bool isValid,
  }) {
    return AnimatedScale(
      scale: isValid ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (value) {
          final valid = validator(value) == null;
          onValidChange(valid);
          if (valid) HapticFeedback.lightImpact();
          setState(() {}); // ensure progress tracker updates live
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          suffixIcon: isValid
              ? const Icon(Icons.check_circle, color: Colors.green)
              : suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }
}

// to pick avatar
class _AvatarPicker extends StatelessWidget {
  final List<String> emojis;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _AvatarPicker({
    required this.emojis,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Avatar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: emojis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final isSelected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    emojis[i],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProgressTracker extends StatefulWidget {
  final double progress; 
  final String label;

  const ProgressTracker({super.key, required this.progress, required this.label});

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.progress,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant ProgressTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ctrl.animateTo(widget.progress);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => LinearProgressIndicator(
              minHeight: 12,
              value: _anim.value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _barColor(_anim.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.label.isEmpty ? ' ' : widget.label,
            key: ValueKey(widget.label),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Color _barColor(double v) {
    if (v < 0.25) return Colors.red;
    if (v < 0.5) return Colors.orange;
    if (v < 0.75) return Colors.amber;
    return Colors.green;
  }
}
