import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:map_launcher/map_launcher.dart';

import '../models/course_model_complete.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  final List<String> enrolledChildren;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.enrolledChildren = const [],
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  // Bascule entre le layout "image plein écran + carte flottante" (mobile)
  // et le layout "panneau image fixe + colonne détails" (desktop / web large).
  static const double _desktopBreakpoint = 900;
  // Au-delà de cette largeur en layout mobile, on centre le contenu
  // (tablette portrait) plutôt que de l'étirer bord à bord.
  static const double _tabletBreakpoint = 600;

  late CourseModel _course;
  String? _creatorName;
  String? _coachName;
  bool _isLoadingCreator = true;
  bool _isLoadingCoach = false;

  // --- Carrousel ---
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isCarouselPaused = false;
  // true pendant un swipe manuel : on suspend l'auto-scroll pour ne pas
  // entrer en conflit avec le geste de l'utilisateur. Pas besoin de
  // setState ici : aucune valeur d'UI ne dépend de ce flag.
  bool _isUserInteracting = false;
  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _loadCreatorInfo();
    _startAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEnrollmentData();
    });
  }

  @override
  void dispose() {
    _stopAutoScroll();
    // CarouselController étend ScrollController : doit être disposé
    // explicitement, sinon fuite mémoire (listeners de ScrollPosition).
    _carouselController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    if (_course.images.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isCarouselPaused || _isUserInteracting || !mounted) return;
      final nextPage = (_currentPage + 1) % _course.images.length;
      // animateToItem (Flutter >= 3.32) navigue par index et calcule
      // lui-même l'offset réel en fonction de itemExtent/flexWeights.
      // L'ancien code utilisait animateTo(nextPage.toDouble()), qui
      // scrolle vers un offset EN PIXELS (donc 1.0, 2.0 px...) : c'était
      // la cause du défilement automatique invisible.
      _carouselController.animateToItem(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _toggleCarouselPause() {
    setState(() => _isCarouselPaused = !_isCarouselPaused);
    if (_isCarouselPaused) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  Future<void> _loadCreatorInfo() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData(_course.createdBy);
      if (mounted) {
        setState(() {
          _creatorName = userData?['name'] ?? 'Créateur inconnu';
          _isLoadingCreator = false;
        });
      }

      if (_course.coachId != null &&
          _course.coachId!.isNotEmpty &&
          _course.coachId != _course.createdBy) {
        _loadCoachInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatorName = 'Erreur chargement';
          _isLoadingCreator = false;
        });
      }
    }
  }

  Future<void> _loadCoachInfo() async {
    if (mounted) setState(() => _isLoadingCoach = true);
    try {
      final authService = AuthService();
      final userData = await authService.getUserData(_course.coachId!);
      if (mounted) {
        setState(() {
          _coachName = userData?['name'];
          _isLoadingCoach = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCoach = false);
    }
  }

  Future<void> _loadEnrollmentData() async {
    final authProvider = context.read<AuthProviderV2>();
    final userId = authProvider.userData?['id'];
    if (userId != null && authProvider.userRole == 'parent') {
      final childProvider = context.read<ChildEnrollmentProvider>();
      await Future.wait([
        childProvider.loadChildren(userId),
        childProvider.loadEnrollments(userId),
      ]);
    }
  }

  String _getDayName(int? day) {
    switch (day) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Non défini';
    }
  }

  void _handleEnrollment() {
    final authProvider = context.read<AuthProviderV2>();
    final userId = authProvider.userData?['id'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour vous inscrire')),
      );
      return;
    }

    if (authProvider.userRole != 'parent') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seuls les parents peuvent inscrire des enfants')),
      );
      return;
    }

    if (!_course.hasAvailableSpots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce cours est complet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnrollmentBottomSheet(
        course: _course,
        parentId: userId,
      ),
    );
  }

  void _shareCourse() {
    Share.share(
      'Découvrez le cours "${_course.title}" sur CRECHE !\n\n'
          '${_course.description}\n\n'
          'Lieu : ${_course.location.address}\n'
          'Tarif : ${_course.price?.toStringAsFixed(0)} ${_course.metadata?['currency'] ?? "DA"}',
    );
  }

  // ---------------------------------------------------------------------
  // BUILD — un seul LayoutBuilder racine qui choisit la composition
  // entière du Scaffold selon l'espace réellement disponible (et non la
  // taille physique de l'écran, ce qui compte sur le web / desktop
  // redimensionnable ou en split-view).
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _desktopBreakpoint;
        return isWide
            ? _buildWideLayout(context, constraints)
            : _buildNarrowLayout(context, constraints);
      },
    );
  }

  // --- Layout ≥ 900px : panneau image fixe + colonne détails ---
  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final cs = Theme.of(context).colorScheme;
    final hasImages = _course.images.isNotEmpty;
    final panelWidth = (constraints.maxWidth * 0.42).clamp(420.0, 580.0);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: panelWidth,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImages
                        ? _buildCarouselStack(showDotIndicators: false)
                        : Image.asset('assets/images/meditation_bg.jpg', fit: BoxFit.cover),
                    if (hasImages) _heroGradientOverlay(),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _circularButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _circularButton(icon: Icons.share, onTap: _shareCourse),
                    ),
                    if (hasImages && _course.images.length > 1)
                      Positioned(left: 20, right: 20, bottom: 20, child: _buildThumbnailsRow()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
                    child: _buildDetailsContent(
                      context,
                      onImageBackground: false,
                      showThumbnailsInline: false,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Layout < 900px : hero image plein écran + carte flottante ---
  Widget _buildNarrowLayout(BuildContext context, BoxConstraints constraints) {
    final hasImages = _course.images.isNotEmpty;
    final heroHeight = (constraints.maxHeight * 0.4).clamp(220.0, 380.0);
    final isTabletPortrait = constraints.maxWidth >= _tabletBreakpoint;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _circularButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: _circularButton(icon: Icons.share, onTap: _shareCourse),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: hasImages
                ? _buildCarouselStack()
                : Image.asset('assets/images/meditation_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(child: _heroGradientOverlay()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTabletPortrait ? 640 : double.infinity),
                  child: Column(
                    children: [
                      SizedBox(height: hasImages ? heroHeight : heroHeight * 0.6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: GlassCard(
                          color: Colors.black45,
                          padding: const EdgeInsets.all(24),
                          child: _buildDetailsContent(
                            context,
                            onImageBackground: true,
                            showThumbnailsInline: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Carrousel — partagé entre les deux layouts.
  // ---------------------------------------------------------------------
  Widget _buildCarouselStack({bool showDotIndicators = true}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Détecte un drag manuel pour suspendre l'auto-scroll le temps
        // du geste, et le reprendre dès qu'il se termine.
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification && notification.dragDetails != null) {
              _isUserInteracting = true;
            } else if (notification is ScrollEndNotification) {
              _isUserInteracting = false;
            }
            return false;
          },
          child: CarouselView(
            controller: _carouselController,
            onIndexChanged: (index) => setState(() => _currentPage = index),
            itemSnapping: true,
            itemExtent: double.infinity,
            shrinkExtent: 0.0,
            padding: EdgeInsets.zero,
            children: _course.images.map((image) {
              return CachedNetworkImage(
                imageUrl: image.supabaseUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/meditation_bg.jpg',
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
        ),
        // Tap pour mettre en pause/reprendre — la CarouselView gère déjà
        // le drag (seul onTap est intercepté ici, le pan continue de
        // remonter vers le Scrollable du carrousel).
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleCarouselPause,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        if (showDotIndicators && _course.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _course.images.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        if (_isCarouselPaused && _course.images.length > 1)
          Positioned(top: 16, right: 16, child: _pauseIndicator()),
      ],
    );
  }

  Widget _buildThumbnailsRow() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _course.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          final image = _course.images[index];
          return GestureDetector(
            onTap: () {
              _carouselController.animateToItem(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CachedNetworkImage(
                  imageUrl: image.supabaseUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pauseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_outline, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Pause',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _circularButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _heroGradientOverlay() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Contenu détails — partagé entre les deux layouts. `onImageBackground`
  // bascule les couleurs de texte (blanc sur photo / onSurface M3 sur
  // panneau clair) pour rester lisible et cohérent Material 3 des deux
  // côtés du point de rupture.
  // ---------------------------------------------------------------------
  Widget _buildDetailsContent(
      BuildContext context, {
        required bool onImageBackground,
        required bool showThumbnailsInline,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color titleColor = onImageBackground ? Colors.white : cs.onSurface;
    final Color bodyColor = onImageBackground ? Colors.white70 : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showThumbnailsInline && _course.images.length > 1) ...[
          _buildThumbnailsRow(),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBadge(_course.category.displayName, color: bodyColor),
            if (_course.minAge != null)
              _buildBadge(
                '${_course.minAge}${_course.maxAge != null ? "-${_course.maxAge}" : "+"} ans',
                color: Colors.blueAccent,
              ),
            _buildBadge(
              '${_course.currentStudents}/${_course.maxStudents} inscrits',
              color: _course.availableSpots < 5 ? Colors.orange : Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _course.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.business_outlined, size: 16, color: bodyColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _isLoadingCreator ? 'Chargement...' : 'Organisé par : $_creatorName',
                style: theme.textTheme.bodySmall?.copyWith(color: bodyColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (_course.coachId != null && (_isLoadingCoach || _coachName != null)) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: bodyColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isLoadingCoach ? 'Chargement coach...' : 'Coach : $_coachName',
                  style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildLocationRow(bodyColor),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.rocket_launch_outlined,
          'Début de session : ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_course.seasonStartDate)}',
          bodyColor,
          textColor: Colors.orangeAccent,
          isBold: true,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calendar_month_outlined,
          'Période : Du ${DateFormat('dd/MM').format(_course.seasonStartDate)} au ${DateFormat('dd/MM').format(_course.seasonEndDate)}',
          bodyColor,
        ),
        if (_course.hasWeeklySchedule) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time_outlined,
            '${_getDayName(_course.dayOfWeek)} : ${_course.startTime?.format(context)} - ${_course.endTime?.format(context)}',
            bodyColor,
          ),
        ],
        if (_course.roomId != null && _course.roomId!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(Icons.meeting_room_outlined, 'Salle : ${_course.roomId}', bodyColor),
        ],
        const SizedBox(height: 24),
        Text('Description', style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ReadMoreText(
          _course.description,
          trimLines: 3,
          colorClickableText: Colors.blueAccent,
          trimMode: TrimMode.Line,
          trimCollapsedText: '... Voir plus',
          trimExpandedText: ' Voir moins',
          style: TextStyle(color: onImageBackground ? Colors.white : cs.onSurface, fontSize: 14),
          moreStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          lessStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        if (_course.tags.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _course.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: onImageBackground ? Colors.white10 : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: onImageBackground ? Colors.white24 : cs.outlineVariant),
                ),
                child: Text('#$tag', style: TextStyle(color: bodyColor, fontSize: 10)),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        if (widget.enrolledChildren.isNotEmpty) ...[
          Text('Inscriptions actives :', style: TextStyle(color: bodyColor, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.enrolledChildren.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChildChip(
                name: widget.enrolledChildren[index],
                primary: cs.inversePrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tarif', style: TextStyle(fontSize: 12, color: bodyColor)),
                  Text(
                    '${_course.price?.toStringAsFixed(0) ?? "0"} ${_course.metadata?['currency'] ?? "DA"} / ${_course.pricingType.displayName.toLowerCase()}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: titleColor),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _handleEnrollment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: cs.primary,
              ),
              child: const Text("S'inscrire", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color, {Color? textColor, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor ?? color,
              fontWeight: isBold ? FontWeight.bold : null,
            )
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(Color color) {
    final fullLocation = [
      _course.location.address,
      _course.location.city,
      _course.location.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(fullLocation, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ),
        IconButton(
          onPressed: _openInMaps,
          icon: const Icon(Icons.map_outlined, size: 20, color: Colors.blueAccent),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _openInMaps() async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (!mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune application de cartes installée sur cet appareil')),
        );
        return;
      }

      if (availableMaps.length == 1) {
        await availableMaps.first.showMarker(
          coords: Coords(_course.location.latitude, _course.location.longitude),
          title: _course.title,
          description: _course.location.address,
        );
        return;
      }

      // Plusieurs apps disponibles : on laisse l'utilisateur choisir
      // plutôt que de prendre .first arbitrairement (pattern recommandé
      // par map_launcher). Pas d'icône SVG ici pour ne pas introduire de
      // dépendance flutter_svg non déclarée dans le pubspec ; remplace
      // l'Icon par SvgPicture.asset(map.icon, ...) si tu ajoutes ce
      // package et veux les logos natifs de chaque app.
      await showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableMaps.map((map) {
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(map.mapName),
                onTap: () {
                  Navigator.pop(sheetContext);
                  map.showMarker(
                    coords: Coords(_course.location.latitude, _course.location.longitude),
                    title: _course.title,
                    description: _course.location.address,
                  );
                },
              );
            }).toList(),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir l'application de cartes")),
        );
      }
    }
  }

  Widget _buildBadge(String text, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EnrollmentBottomSheet extends StatefulWidget {
  final CourseModel course;
  final String parentId;

  const _EnrollmentBottomSheet({
    required this.course,
    required this.parentId,
  });

  @override
  State<_EnrollmentBottomSheet> createState() => _EnrollmentBottomSheetState();
}

class _EnrollmentBottomSheetState extends State<_EnrollmentBottomSheet> {
  final List<String> _selectedChildIds = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final children = childProvider.children;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sur desktop/web large, on évite que la feuille modale ne
        // s'étire bord à bord : on la centre avec une largeur max.
        final isWide = constraints.maxWidth >= 700;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Inscription au cours',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.course.title,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sélectionnez les enfants à inscrire :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('Aucun enfant enregistré.'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Ajouter un enfant dans votre profil'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: children.length,
                        itemBuilder: (context, index) {
                          final child = children[index];
                          final isEnrolled = childProvider.isChildEnrolledInCourse(child.id, widget.course.id);
                          final isSelected = _selectedChildIds.contains(child.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: isEnrolled
                                  ? null
                                  : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedChildIds.remove(child.id);
                                  } else {
                                    _selectedChildIds.add(child.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                      child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                                      child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            '${child.age} ans • ${child.schoolGrade ?? "Niveau non précisé"}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isEnrolled)
                                      const Icon(Icons.check_circle, color: Colors.green)
                                    else if (isSelected)
                                      Icon(Icons.check_box, color: Theme.of(context).colorScheme.primary)
                                    else
                                      const Icon(Icons.check_box_outline_blank, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_selectedChildIds.isEmpty || _isSubmitting) ? null : _submitEnrollment,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Confirmer l'inscription"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitEnrollment() async {
    setState(() => _isSubmitting = true);

    final childProvider = context.read<ChildEnrollmentProvider>();
    bool allSuccess = true;

    for (final childId in _selectedChildIds) {
      final success = await childProvider.createEnrollment(
        courseId: widget.course.id,
        childId: childId,
        parentId: widget.parentId,
        totalAmount: widget.course.price,
      );
      if (!success) allSuccess = false;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (allSuccess) {
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(childProvider.error ?? 'Une ou plusieurs inscriptions ont échoué')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Félicitations !'),
        content: const Text(
          "L'inscription a été envoyée avec succès. Elle est en attente de validation par le responsable (club ou coach).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Widget pour les chips enfants
class ChildChip extends StatelessWidget {
  final String name;
  final Color primary;

  const ChildChip({
    super.key,
    required this.name,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.child_care, size: 14, color: primary),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}