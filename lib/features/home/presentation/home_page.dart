import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        titleSpacing: 12,
        title: Row(
          children: [
            const _Logo(size: 36),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculateur Solaire',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dimensionnement photovoltaïque',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Calculer',
              onPressed: () => context.go('/calculate'),
              icon: const Icon(Icons.calculate_outlined, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 4 ),
            IconButton(
              tooltip: 'Espace admin',
              onPressed: () => context.go('/admin-login'),
              icon: const Icon(Icons.shield_outlined, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                padding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFEDE9FE), // purple-50
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // const SizedBox(height: 8),
                const _Logo(size: 96),
                const SizedBox(height: 12),
                // Titre principal
                Wrap(
                  alignment: WrapAlignment.center,
                  children: const [
                    Text(
                      'Dimensionnez votre ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    _GradientText(
                      'installation solaire',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Calculez facilement la puissance, le nombre de panneaux et batteries nécessaires pour votre installation. ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const Text(
                  'Gratuit et sans inscription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                // CTA + badge
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _GradientButton.icon(
                      onPressed: () => context.go('/calculate'),
                      label: 'Commencer le calcul',
                      icon: Icons.calculate_outlined,
                      big: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF16A34A)],
                      ),
                    ),
                    // Badge "Aucune inscription requise"
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 18, color: Color(0xFF16A34A)),
                        SizedBox(width: 6),
                        Text('Aucune inscription requise', style: TextStyle(color: Color(0xFF4B5563))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- COMPOSANTS LÉGERS ---------------------------- */

class _Logo extends StatelessWidget {
  const _Logo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .2),
      child: Image.asset(
        'assets/logo.png',
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          height: size,
          width: size,
          alignment: Alignment.center,
          color: Colors.white,
          child: const Icon(
            Icons.solar_power,
            size: 28,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style, required this.gradient});
  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton.icon({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.big = false,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
    ),
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool big;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final padding = big
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: big ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
