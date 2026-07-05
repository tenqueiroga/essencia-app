import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/olfato_tokens.dart';
import 'collection_page.dart';

export 'collection_page.dart' show CollectionItemType, CollectionItemTypeExt;

/// Shows a bottom sheet dialog requiring the user to select
/// a Collection Item Type before adding to collection.
/// Returns the selected type, or null if dismissed.
Future<CollectionItemType?> showTypeSelectionDialog(
    BuildContext context) async {
  return showModalBottomSheet<CollectionItemType>(
    context: context,
    backgroundColor: OlfatoTokens.vanilla,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _TypeSelectionContent(),
  );
}

class _TypeSelectionContent extends StatelessWidget {
  const _TypeSelectionContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: OlfatoTokens.gray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tipo de item',
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OlfatoTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Como você possui este perfume?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: OlfatoTokens.gray,
            ),
          ),
          const SizedBox(height: 24),
          _TypeOption(
            type: CollectionItemType.perfume,
            icon: Icons.local_bar,
            description: 'Frasco completo',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: CollectionItemType.decant,
            icon: Icons.science_outlined,
            description: 'Decante / Split',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: CollectionItemType.amostra,
            icon: Icons.colorize,
            description: 'Amostra / Sample',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: CollectionItemType.jaTive,
            icon: Icons.history,
            description: 'Já tive / Terminado',
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final CollectionItemType type;
  final IconData icon;
  final String description;

  const _TypeOption({
    required this.type,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: OlfatoTokens.mist,
          borderRadius: BorderRadius.circular(OlfatoTokens.radiusControl),
          border: Border.all(color: OlfatoTokens.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: OlfatoTokens.plum, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.singularLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OlfatoTokens.ink,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: OlfatoTokens.gray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: OlfatoTokens.gray, size: 20),
          ],
        ),
      ),
    );
  }
}
