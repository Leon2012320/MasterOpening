import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/board_theme.dart';

/// Die einzige Stelle, an der `chessground` benutzt wird.
///
/// Alles darüber arbeitet mit `Position`, `Move` und den App-Einstellungen;
/// hier werden daraus Brett-Widgets. Ein Wechsel des Brett-Pakets bliebe
/// dadurch auf diese Datei beschränkt.
abstract final class BoardTheming {
  /// Zwischenspeicher, weil `chessground` das Brett bei jedem neuen
  /// Farbschema-Objekt komplett neu zeichnet.
  static final Map<(BoardStyle, bool), ChessboardColorScheme> _schemes = {};

  static ChessboardColorScheme scheme(
    BoardStyle style, {
    required bool isDark,
  }) {
    return _schemes.putIfAbsent((style, isDark), () {
      final colors = BoardColors.of(style, isDark: isDark);
      return ChessboardColorScheme(
        lightSquare: colors.lightSquare,
        darkSquare: colors.darkSquare,
        background: SolidColorChessboardBackground(
          lightSquare: colors.lightSquare,
          darkSquare: colors.darkSquare,
        ),
        whiteCoordBackground: SolidColorChessboardBackground(
          lightSquare: colors.lightSquare,
          darkSquare: colors.darkSquare,
          coordinates: true,
        ),
        blackCoordBackground: SolidColorChessboardBackground(
          lightSquare: colors.lightSquare,
          darkSquare: colors.darkSquare,
          coordinates: true,
          orientation: Side.black,
        ),
        lastMove: const HighlightDetails(solidColor: BoardColors.lastMove),
        selected: const HighlightDetails(solidColor: BoardColors.selected),
        validMoves: BoardColors.selected,
        validPremoves: BoardColors.hint,
      );
    });
  }

  static PieceAssets pieceAssets(String name) {
    for (final set in PieceSet.values) {
      if (set.name == name) return set.assets;
    }
    return PieceSet.staunty.assets;
  }

  static ChessboardSettings settings(
    AppSettings app, {
    required bool isDark,
    bool showValidMoves = true,
  }) {
    return ChessboardSettings(
      colorScheme: scheme(app.boardStyle, isDark: isDark),
      pieceAssets: pieceAssets(app.pieceSet),
      borderRadius: BorderRadius.circular(AppRadius.md),
      enableCoordinates: app.showCoordinates,
      animationDuration: app.boardAnimations
          ? const Duration(milliseconds: 220)
          : Duration.zero,
      showValidMoves: showValidMoves,
      // Vorziehen ergibt nur im echten Spiel Sinn, nicht beim Lernen.
      enablePremoves: false,
      autoQueenPromotion: true,
    );
  }

  static StaticChessboardSettings staticSettings(
    AppSettings app, {
    required bool isDark,
    bool coordinates = false,
  }) {
    return StaticChessboardSettings(
      colorScheme: scheme(app.boardStyle, isDark: isDark),
      pieceAssets: pieceAssets(app.pieceSet),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      enableCoordinates: coordinates,
      animationDuration: app.boardAnimations
          ? const Duration(milliseconds: 220)
          : Duration.zero,
    );
  }
}

/// Ein Brett, auf dem gezogen werden kann.
///
/// Nimmt eine `Position` entgegen statt eines FEN: die legalen Züge kommen
/// dann aus derselben Quelle wie die Stellung, und niemand kann beides aus
/// Versehen auseinanderlaufen lassen.
class AppChessboard extends StatefulWidget {
  const AppChessboard({
    required this.size,
    required this.position,
    required this.orientation,
    required this.settings,
    this.lastMove,
    this.onMove,
    this.interactableSide = PlayerSide.none,
    this.annotations = const {},
    this.shapes = const {},
    super.key,
  });

  final double size;
  final Position position;
  final Side orientation;
  final ChessboardSettings settings;
  final Move? lastMove;
  final void Function(NormalMove move)? onMove;

  /// Welche Seite ziehen darf. `none` macht das Brett zur reinen Anzeige,
  /// die Figuren bleiben aber animiert.
  final PlayerSide interactableSide;

  final Map<Square, Annotation> annotations;
  final Set<Shape> shapes;

  @override
  State<AppChessboard> createState() => _AppChessboardState();
}

class _AppChessboardState extends State<AppChessboard> {
  late ChessboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController(game: _gameData());
  }

  @override
  void didUpdateWidget(AppChessboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position.fen != widget.position.fen ||
        oldWidget.lastMove != widget.lastMove ||
        oldWidget.interactableSide != widget.interactableSide) {
      _controller.updatePosition(
        _gameData(),
        animate: widget.settings.animationDuration > Duration.zero,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  GameData _gameData() {
    return GameData(
      fen: widget.position.fen,
      lastMove: widget.lastMove,
      playerSide: widget.interactableSide,
      sideToMove: widget.position.turn,
      validMoves: makeLegalMoves(widget.position),
      kingSquareInCheck: widget.position.isCheck
          ? widget.position.board.kingOf(widget.position.turn)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chessboard(
      size: widget.size,
      controller: _controller,
      orientation: widget.orientation,
      settings: widget.settings,
      annotations: widget.annotations,
      shapes: widget.shapes,
      onMove: (move, {viaDragAndDrop}) {
        if (move is NormalMove) widget.onMove?.call(move);
      },
    );
  }
}

/// Ein kleines, nicht bedienbares Brett — Vorschau auf Karten und Symbol
/// einer Eröffnung in der Bibliothek.
class BoardThumbnail extends StatelessWidget {
  const BoardThumbnail({
    required this.fen,
    required this.size,
    required this.settings,
    this.orientation = Side.white,
    this.lastMove,
    super.key,
  });

  final String fen;
  final double size;
  final StaticChessboardSettings settings;
  final Side orientation;
  final Move? lastMove;

  @override
  Widget build(BuildContext context) {
    return StaticChessboard(
      size: size,
      orientation: orientation,
      fen: fen,
      lastMove: lastMove,
      settings: settings,
    );
  }
}
