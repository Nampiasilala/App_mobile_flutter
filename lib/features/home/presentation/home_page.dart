import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // from-blue-50
              Color(0xFFEDE9FE), // to-purple-50
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // HEADER (sticky)
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.transparent),
                ),
              ),
              titleSpacing: 12,
              title: Row(
                children: [
                  const _Logo(size: 40),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
                  const Spacer(), // Pousse l'IconButton à droite
    
    IconButton(
      onPressed: () => context.go('/calculate'),
      icon: Icon(
        Icons.calculate_outlined,
        color: Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Color(0xFF2563EB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(8),
      ),
    ),
                ],
              ),
            ),

            // HERO
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const _Logo(size: 120),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: const [
                        Text(
                          'Dimensionnez votre ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        _GradientText(
                          'installation solaire',
                          style: TextStyle(
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Calculez facilement la puissance, le nombre de panneaux et batteries nécessaires pour votre installation photovoltaïque autonome. ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                    const Text(
                      'Gratuit et sans inscription.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Aucune inscription requise',
                              style: TextStyle(color: Color(0xFF4B5563)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // STATS pleine largeur
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _StatCard(
                              value: '100+',
                              label: 'Calculs effectués',
                              icon: Icons.calculate,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: _StatCard(
                              value: '95%',
                              label: 'Testeurs satisfaits',
                              icon: Icons.star_rate,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: _StatCard(
                              value: '20+',
                              label: 'Équipements référencés',
                              icon: Icons.bolt,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FEATURES
            SliverToBoxAdapter(
              child: _Section(
                title: 'Pourquoi choisir notre calculateur ?',
                subtitle:
                    'Une solution complète et professionnelle pour dimensionner votre installation solaire',
                child: _ResponsiveGrid(
                  columnsForWidth: (w) => w >= 1000
                      ? 3
                      : w >= 650
                      ? 2
                      : 1,
                  children: const [
                    _FeatureCard(
                      icon: Icons.bolt_outlined,
                      title: 'Calcul précis',
                      description:
                          'Algorithme professionnel prenant en compte tous les paramètres : consommation, autonomie, irradiation solaire locale.',
                      bgStart: Color(0xFFDBEAFE), // blue-100
                      bgEnd: Color(0xFFDBEAFE),
                      iconColor: Color(0xFF2563EB),
                    ),
                    _FeatureCard(
                      icon: Icons.public_outlined,
                      title: 'Données locales',
                      description:
                          'Irradiation solaire automatique basée sur votre localisation grâce aux données satellite NASA.',
                      bgStart: Color(0xFFD1FAE5), // green-100
                      bgEnd: Color(0xFFD1FAE5),
                      iconColor: Color(0xFF16A34A),
                    ),
                    _FeatureCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Rapport PDF',
                      description:
                          'Téléchargez un rapport détaillé avec tous les calculs, équipements recommandés et coûts estimés.',
                      bgStart: Color(0xFFEDE9FE), // purple-100
                      bgEnd: Color(0xFFEDE9FE),
                      iconColor: Color(0xFF7C3AED),
                    ),
                  ],
                ),
              ),
            ),

            // HOW IT WORKS (steps)
            SliverToBoxAdapter(
              child: _Section(
                title: 'Comment ça marche ?',
                subtitle: 'Obtenez votre dimensionnement en 4 étapes simples',
                child: _ResponsiveGrid(
                  columnsForWidth: (w) => w >= 1200
                      ? 4
                      : w >= 900
                      ? 3
                      : w >= 600
                      ? 2
                      : 1,
                  children: const [
                    _StepCard(
                      step: '1',
                      title: 'Renseignez vos besoins',
                      description:
                          'Indiquez votre consommation journalière et vos contraintes d\'installation',
                    ),
                    _StepCard(
                      step: '2',
                      title: 'Précisez votre localisation',
                      description:
                          'L\'irradiation solaire sera calculée automatiquement pour votre région',
                    ),
                    _StepCard(
                      step: '3',
                      title: 'Obtenez vos résultats',
                      description:
                          'Dimensions, équipements recommandés et coûts estimés instantanément',
                    ),
                    _StepCard(
                      step: '4',
                      title: 'Téléchargez le rapport',
                      description:
                          'Rapport PDF complet pour votre installateur ou votre projet',
                    ),
                  ],
                ),
              ),
            ),

            // CTA SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Prêt à calculer votre installation ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Notre calculateur vous donnera une estimation complète en quelques minutes. Commencez dès maintenant, c’est gratuit et sans engagement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _LightButton.icon(
                            onPressed: () => context.go('/calculate'),
                            label: 'Lancer le calculateur',
                            icon: Icons.calculate_outlined,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Résultats instantanés',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: _ResponsiveGrid(
                  columnsForWidth: (w) => w >= 900 ? 3 : 1,
                  crossAxisSpacing: 20,
                  children: [
                    // Col 1
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Logo(size: 36),
                        const SizedBox(height: 10),
                        Text(
                          '© $nowYear Calculateur Solaire.\nTous droits réservés.',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Col 2
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FooterLink(
                          label: 'Calculateur',
                          onTap: () => context.go('/calculate'),
                        ),
                        _FooterLink(
                          label: 'Espace admin',
                          onTap: () => context.go('/admin-login'),
                          icon: Icons.shield_outlined,
                        ),
                      ],
                    ),
                    // Col 3
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FooterLink(
                          label: 'nampiasilala@gmail.com',
                          icon: Icons.mail_outline,
                          onTap: () => _launchUrl(
                            Uri.parse('mailto:nampiasilala@gmail.com'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _SocialIcon(
                              tooltip: 'Facebook',
                              icon: Icons.public, // placeholder
                              onTap: () => _launchUrl(
                                Uri.parse('https://facebook.com/'),
                              ),
                            ),
                            _SocialIcon(
                              tooltip: 'Twitter/X',
                              icon: Icons.travel_explore, // placeholder
                              onTap: () =>
                                  _launchUrl(Uri.parse('https://twitter.com/')),
                            ),
                            _SocialIcon(
                              tooltip: 'Instagram',
                              icon: Icons.camera_alt_outlined, // placeholder
                              onTap: () => _launchUrl(
                                Uri.parse('https://instagram.com/'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UTILITAIRES UI ---------------------------- */

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
      shaderCallback: (bounds) =>
          gradient.createShader(Offset.zero & bounds.size),
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
            color: const Color(0xFF2563EB).withValues(alpha: .25),
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

class _LightButton extends StatelessWidget {
  const _LightButton.icon({
    required this.onPressed,
    required this.label,
    required this.icon,
  });
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 14,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    required this.columnsForWidth,
    this.crossAxisSpacing,
    this.gap = 16.0, // Correction: Initialisation de la variable 'gap'
  });

  final List<Widget> children;
  final int Function(double width) columnsForWidth;
  final double gap;
  final double? crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = columnsForWidth(c.maxWidth).clamp(1, 6);
        if (cols == 1) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: gap),
              ],
            ],
          );
        }
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: crossAxisSpacing ?? gap,
          mainAxisSpacing: gap,
          childAspectRatio: 1.2,
          children: children,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF2563EB)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF374151), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });
  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 58,
          width: 58,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
            ),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF4B5563)),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
        ],
        Text(label, style: const TextStyle(color: Color(0xFF4B5563))),
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: w,
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

Future<void> _launchUrl(Uri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // ignore: avoid_print
    print('Impossible d’ouvrir: $uri');
  }
}
