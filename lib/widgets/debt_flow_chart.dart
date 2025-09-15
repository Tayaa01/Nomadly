import 'package:flutter/material.dart';
import '../models/shared_expense.dart';
import '../models/travel_group.dart';
import 'dart:math' as math;

class DebtFlowChart extends StatefulWidget {
  final List<Settlement> settlements;
  final List<GroupMember> members;
  final bool isDarkMode;

  const DebtFlowChart({
    super.key,
    required this.settlements,
    required this.members,
    required this.isDarkMode,
  });

  @override
  State<DebtFlowChart> createState() => _DebtFlowChartState();
}

class _DebtFlowChartState extends State<DebtFlowChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Positions des membres sur le cercle
  final Map<String, Offset> _memberPositions = {};
  
  // État d'interaction
  String? _hoveredMemberId;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Calculer les positions initiales des membres
    _calculateMemberPositions();
  }
  
  @override
  void didUpdateWidget(DebtFlowChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settlements != widget.settlements ||
        oldWidget.members != widget.members) {
      _calculateMemberPositions();
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Calculer les positions des membres sur un cercle
  void _calculateMemberPositions() {
    final int memberCount = widget.members.length;
    if (memberCount == 0) return;
    
    _memberPositions.clear();
    
    for (int i = 0; i < memberCount; i++) {
      final double angle = 2 * 3.14159 * i / memberCount;
      // Rayon du cercle = 0.8 pour laisser de la marge
      final double x = 0.8 * cos(angle);
      final double y = 0.8 * sin(angle);
      _memberPositions[widget.members[i].id] = Offset(x, y);
    }
  }
  
  // Obtenir la couleur pour un montant
  Color _getAmountColor(double amount) {
    final double normalizedAmount = amount / 100; // Normaliser pour l'échelle de couleur
    final double intensity = normalizedAmount.clamp(0.3, 1.0);
    
    return widget.isDarkMode
        ? Color.fromRGBO(0, (255 * intensity).round(), 0, 0.7)
        : Color.fromRGBO(0, (200 * intensity).round(), 100, 0.8);
  }
  
  // Obtenir l'épaisseur de la ligne en fonction du montant
  double _getLineWidth(double amount) {
    return 2.0 + (amount / 50).clamp(0.0, 6.0);
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty || widget.settlements.isEmpty) {
      return Center(child: Text('Aucune donnée à afficher'));
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  // Vérifier si un membre a été touché
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);
                  final Offset normalizedPosition = Offset(
                    (localPosition.dx / constraints.maxWidth) * 2 - 1,
                    (localPosition.dy / constraints.maxHeight) * 2 - 1,
                  );
                  
                  _checkMemberTap(normalizedPosition);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: DebtFlowPainter(
                    settlements: widget.settlements,
                    members: widget.members,
                    memberPositions: _memberPositions,
                    animationValue: _animation.value,
                    isDarkMode: widget.isDarkMode,
                    hoveredMemberId: _hoveredMemberId,
                    getAmountColor: _getAmountColor,
                    getLineWidth: _getLineWidth,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Vérifier si un membre a été touché
  void _checkMemberTap(Offset normalizedPosition) {
    String? tappedMemberId;
    
    for (final entry in _memberPositions.entries) {
      final distance = (normalizedPosition - entry.value).distance;
      if (distance < 0.15) { // Rayon de détection
        tappedMemberId = entry.key;
        break;
      }
    }
    
    setState(() {
      if (_hoveredMemberId == tappedMemberId) {
        // Désélectionner si déjà sélectionné
        _hoveredMemberId = null;
      } else {
        _hoveredMemberId = tappedMemberId;
      }
    });
  }
}

class DebtFlowPainter extends CustomPainter {
  final List<Settlement> settlements;
  final List<GroupMember> members;
  final Map<String, Offset> memberPositions;
  final double animationValue;
  final bool isDarkMode;
  final String? hoveredMemberId;
  final Color Function(double) getAmountColor;
  final double Function(double) getLineWidth;
  
  DebtFlowPainter({
    required this.settlements,
    required this.members,
    required this.memberPositions,
    required this.animationValue,
    required this.isDarkMode,
    this.hoveredMemberId,
    required this.getAmountColor,
    required this.getLineWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    
    // Dessiner les lignes de flux d'argent
    _drawMoneyFlows(canvas, size, center, radius);
    
    // Dessiner les membres
    _drawMembers(canvas, size, center, radius);
  }
  
  void _drawMoneyFlows(Canvas canvas, Size size, Offset center, double radius) {
    for (final settlement in settlements) {
      // Ne dessiner que les règlements non réglés ou ceux liés au membre survolé
      if (settlement.isSettled && 
          hoveredMemberId != null && 
          settlement.fromMemberId != hoveredMemberId && 
          settlement.toMemberId != hoveredMemberId) {
        continue;
      }
      
      final fromPosition = memberPositions[settlement.fromMemberId];
      final toPosition = memberPositions[settlement.toMemberId];
      
      if (fromPosition == null || toPosition == null) continue;
      
      final fromPoint = Offset(
        center.dx + fromPosition.dx * radius * 0.8,
        center.dy + fromPosition.dy * radius * 0.8,
      );
      
      final toPoint = Offset(
        center.dx + toPosition.dx * radius * 0.8,
        center.dy + toPosition.dy * radius * 0.8,
      );
      
      // Calculer le point de contrôle pour la courbe
      final midPoint = Offset(
        (fromPoint.dx + toPoint.dx) / 2,
        (fromPoint.dy + toPoint.dy) / 2,
      );
      
      // Décaler le point de contrôle perpendiculairement
      final perpVector = Offset(
        -(toPoint.dy - fromPoint.dy),
        toPoint.dx - fromPoint.dx,
      ).normalize();
      
      final controlPoint = Offset(
        midPoint.dx + perpVector.dx * radius * 0.3,
        midPoint.dy + perpVector.dy * radius * 0.3,
      );
      
      // Déterminer si ce règlement est lié au membre survolé
      final isHighlighted = hoveredMemberId != null && 
          (settlement.fromMemberId == hoveredMemberId || 
           settlement.toMemberId == hoveredMemberId);
      
      // Couleur et épaisseur de la ligne
      final color = isHighlighted 
          ? Colors.orange 
          : (settlement.isSettled 
              ? Colors.grey.withOpacity(0.5) 
              : getAmountColor(settlement.amount));
      
      final lineWidth = isHighlighted 
          ? getLineWidth(settlement.amount) + 1.5 
          : (settlement.isSettled 
              ? 1.5 
              : getLineWidth(settlement.amount));
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth * animationValue
        ..strokeCap = StrokeCap.round;
      
      // Dessiner la courbe de Bézier
      final path = Path()
        ..moveTo(fromPoint.dx, fromPoint.dy)
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          fromPoint.dx + (toPoint.dx - fromPoint.dx) * animationValue,
          fromPoint.dy + (toPoint.dy - fromPoint.dy) * animationValue,
        );
      
      canvas.drawPath(path, paint);
      
      // Dessiner la flèche à l'extrémité
      if (animationValue > 0.9) {
        _drawArrow(canvas, toPoint, controlPoint, color, lineWidth);
      }
      
      // Afficher le montant au milieu de la courbe
      if (animationValue > 0.5) {
        final textPosition = Offset(
          controlPoint.dx,
          controlPoint.dy,
        );
        
        final textStyle = TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 12 * (isHighlighted ? 1.2 : 1.0),
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          backgroundColor: isHighlighted 
              ? Colors.orange.withOpacity(0.2) 
              : Colors.transparent,
        );
        
        final textSpan = TextSpan(
          text: '${settlement.amount.toStringAsFixed(2)} €',
          style: textStyle,
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textPosition.dx - textPainter.width / 2,
            textPosition.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }
  
  void _drawArrow(Canvas canvas, Offset tip, Offset control, Color color, double width) {
    final direction = (tip - control).normalize();
    
    final arrowSize = 10.0 * width / 2.0;
    
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - direction.dx * arrowSize + direction.dy * arrowSize / 2,
        tip.dy - direction.dy * arrowSize - direction.dx * arrowSize / 2,
      )
      ..lineTo(
        tip.dx - direction.dx * arrowSize - direction.dy * arrowSize / 2,
        tip.dy - direction.dy * arrowSize + direction.dx * arrowSize / 2,
      )
      ..close();
    
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
  }
  
  void _drawMembers(Canvas canvas, Size size, Offset center, double radius) {
    for (final member in members) {
      final position = memberPositions[member.id];
      if (position == null) continue;
      
      final point = Offset(
        center.dx + position.dx * radius * 0.8,
        center.dy + position.dy * radius * 0.8,
      );
      
      // Déterminer si ce membre est survolé
      final isHighlighted = member.id == hoveredMemberId;
      
      // Dessiner le cercle du membre
      final circlePaint = Paint()
        ..color = isHighlighted 
            ? Colors.orange 
            : (isDarkMode ? Colors.blueAccent : Colors.blue)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        point,
        radius * 0.1 * (isHighlighted ? 1.2 : 1.0),
        circlePaint,
      );
      
      // Dessiner le texte du nom du membre
      final textStyle = TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 14 * (isHighlighted ? 1.2 : 1.0),
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        backgroundColor: isHighlighted 
            ? Colors.orange.withOpacity(0.2) 
            : Colors.transparent,
      );
      
      final textSpan = TextSpan(
        text: member.name,
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          point.dy + radius * 0.15,
        ),
      );
      
      // Dessiner l'initiale du membre dans le cercle
      final initialStyle = TextStyle(
        color: Colors.white,
        fontSize: 16 * (isHighlighted ? 1.2 : 1.0),
        fontWeight: FontWeight.bold,
      );
      
      final initialSpan = TextSpan(
        text: member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: initialStyle,
      );
      
      final initialPainter = TextPainter(
        text: initialSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      initialPainter.layout();
      initialPainter.paint(
        canvas,
        Offset(
          point.dx - initialPainter.width / 2,
          point.dy - initialPainter.height / 2,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(DebtFlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.hoveredMemberId != hoveredMemberId ||
           oldDelegate.settlements != settlements ||
           oldDelegate.members != members ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

// Extension pour normaliser un vecteur
extension OffsetExtension on Offset {
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return Offset(dx / magnitude, dy / magnitude);
  }
}

// Fonctions mathématiques
double sin(double angle) => math.sin(angle);
double cos(double angle) => math.cos(angle);