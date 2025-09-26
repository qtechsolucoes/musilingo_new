// lib/features/onboarding/presentation/view/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/main_navigation_screen.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  final User user;
  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  String? _selectedAvatarUrl;
  bool _isLoading = false;

  final List<String> _avatars = [
    'https://i.pravatar.cc/150?img=1',
    'https://i.pravatar.cc/150?img=2',
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=4',
    'https://i.pravatar.cc/150?img=5',
    'https://i.pravatar.cc/150?img=6',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=8',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.userMetadata?['full_name'] ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    SfxService.instance.playClick();
    setState(() => _isLoading = true);
    final userSession = context.read<UserSession>();
    final updates = <String, dynamic>{};
    final userMetadata = <String, dynamic>{};

    if (_nameController.text.isNotEmpty) {
      updates['full_name'] = _nameController.text;
      userMetadata['full_name'] = _nameController.text;
    }

    if (_selectedAvatarUrl != null) {
      updates['avatar_url'] = _selectedAvatarUrl;
      userMetadata['avatar_url'] = _selectedAvatarUrl;
    }

    try {
      if (updates.isNotEmpty) {
        await supabase
            .from('profiles')
            .update(updates)
            .eq('id', widget.user.id);
      }
      if (userMetadata.isNotEmpty) {
        await supabase.auth.updateUser(UserAttributes(data: userMetadata));
      }

      await userSession.initializeSession();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Tratar erro
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildWelcomePage();
                    if (index == 1) return _buildNamePage();
                    return _buildAvatarPage();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const WormEffect(
                    dotColor: AppColors.card,
                    activeDotColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 100, color: AppColors.accent),
          const SizedBox(height: 24),
          const Text(
            'Boas-vindas ao Musilingo!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vamos preparar seu perfil para começar a jornada musical.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              SfxService.instance.playClick();
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('Começar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Como podemos te chamar?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              hintText: 'Digite seu nome ou apelido',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    // ignore: deprecated_member_use
                    BorderSide(color: AppColors.accent.withOpacity(0.5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              SfxService.instance.playClick();
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 50)),
            child:
                const Text('Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Escolha seu avatar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatarUrl = _avatars[index];
                final isSelected = _selectedAvatarUrl == avatarUrl;
                return GestureDetector(
                  onTap: () {
                    SfxService.instance.playClick();
                    setState(() {
                      _selectedAvatarUrl = avatarUrl;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.accent, width: 4)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: AppColors.accent.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _finishOnboarding,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 50)),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Concluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
