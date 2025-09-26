// FASE 4.2: AnimatedScoreWidget - Widget para mostrar criação de partitura em tempo real
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/ai_realtime_score_service.dart';

/// Widget que mostra a criação de partitura em tempo real de forma animada
class AnimatedScoreWidget extends StatefulWidget {
  final String prompt;
  final VoidCallback? onCompleted;
  final Function(String error)? onError;
  final EdgeInsets padding;
  final double height;

  const AnimatedScoreWidget({
    super.key,
    required this.prompt,
    this.onCompleted,
    this.onError,
    this.padding = const EdgeInsets.all(16.0),
    this.height = 300.0,
  });

  @override
  State<AnimatedScoreWidget> createState() => _AnimatedScoreWidgetState();
}

class _AnimatedScoreWidgetState extends State<AnimatedScoreWidget>
    with TickerProviderStateMixin {

  // Controladores de animação
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animações
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Estado
  ScoreGenerationProgress? _currentProgress;
  String? _currentSVG;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startGeneration();
  }

  void _setupAnimations() {
    // Controlador de progresso (linear)
    _progressController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Controlador de fade para transições suaves
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Controlador de pulse para indicar atividade
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startGeneration() async {
    setState(() => _isGenerating = true);

    // Iniciar animações
    _progressController.reset();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    // Escutar o progresso da geração
    AIRealtimeScoreService.instance.progressStream.listen(
      _handleProgress,
      onError: _handleError,
    );

    // Iniciar geração
    try {
      final musicXML = await AIRealtimeScoreService.instance.generateRealtimeScore(widget.prompt);

      if (musicXML == null) {
        _handleError('Falha ao gerar partitura');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleProgress(ScoreGenerationProgress progress) {
    setState(() {
      _currentProgress = progress;
    });

    // Atualizar animação de progresso
    _progressController.animateTo(progress.progress);

    // Se há um novo SVG, fazer fade in
    if (progress.currentSVG != null && progress.currentSVG != _currentSVG) {
      setState(() {
        _currentSVG = progress.currentSVG;
      });
      _fadeController.reset();
      _fadeController.forward();
    }

    // Parar animações quando completado
    if (progress.state == ScoreGenerationState.completed) {
      _pulseController.stop();
      widget.onCompleted?.call();
      setState(() => _isGenerating = false);
    }

    // Tratar erros
    if (progress.state == ScoreGenerationState.error) {
      _pulseController.stop();
      widget.onError?.call(progress.errorMessage ?? 'Erro desconhecido');
      setState(() => _isGenerating = false);
    }
  }

  void _handleError(String error) {
    _pulseController.stop();
    widget.onError?.call(error);
    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com progresso
          _buildProgressHeader(),
          const SizedBox(height: 16),

          // Área da partitura
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: _buildScoreArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _currentProgress;
    if (progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status atual
        Row(
          children: [
            _buildStatusIcon(progress.state),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.currentStep,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(progress.progress * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Barra de progresso animada
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress.state),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ScoreGenerationState state) {
    switch (state) {
      case ScoreGenerationState.idle:
        return const Icon(Icons.music_note_outlined, color: Colors.grey);
      case ScoreGenerationState.generating:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.auto_awesome, color: Colors.blue),
            );
          },
        );
      case ScoreGenerationState.rendering:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.brush, color: Colors.orange),
            );
          },
        );
      case ScoreGenerationState.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ScoreGenerationState.error:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  Color _getProgressColor(ScoreGenerationState state) {
    switch (state) {
      case ScoreGenerationState.idle:
        return Colors.grey;
      case ScoreGenerationState.generating:
        return Colors.blue;
      case ScoreGenerationState.rendering:
        return Colors.orange;
      case ScoreGenerationState.completed:
        return Colors.green;
      case ScoreGenerationState.error:
        return Colors.red;
    }
  }

  Widget _buildScoreArea() {
    if (_currentSVG == null) {
      return _buildPlaceholder();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.5,
            maxScale: 3.0,
            child: SvgPicture.string(
              _currentSVG!,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => _buildPlaceholder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isGenerating ? _pulseAnimation.value : 1.0,
                child: Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isGenerating
              ? 'Criando sua partitura...'
              : 'Partitura será exibida aqui',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}