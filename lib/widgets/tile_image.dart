import 'package:flutter/material.dart';

/// Un trozo (fila [row], columna [col]) de una cuadrícula n x n de [asset],
/// recortado a cuadrado desde el centro.
class TileImage extends StatelessWidget {
  const TileImage({
    super.key,
    required this.asset,
    required this.boardSide,
    required this.n,
    required this.row,
    required this.col,
  });

  final String asset;
  final double boardSide;
  final int n;
  final int row;
  final int col;

  @override
  Widget build(BuildContext context) {
    final align = Alignment(
      n == 1 ? 0 : -1 + 2 * col / (n - 1),
      n == 1 ? 0 : -1 + 2 * row / (n - 1),
    );
    return OverflowBox(
      maxWidth: boardSide,
      maxHeight: boardSide,
      alignment: align,
      child: SizedBox(
        width: boardSide,
        height: boardSide,
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}
