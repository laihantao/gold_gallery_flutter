import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

/// Bottom sheet to create and delete collections. Talks to the app-wide
/// [CollectionNotifier], so it can be opened from anywhere (Settings, the
/// listing page's quick-create entry, etc.). Watches the notifier, so the
/// in-sheet list refreshes automatically after create/delete.
class ManageCollectionsSheet extends StatefulWidget {
  const ManageCollectionsSheet({super.key});

  /// Opens the sheet as a transparent, scroll-controlled modal.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ManageCollectionsSheet(),
    );
  }

  @override
  State<ManageCollectionsSheet> createState() => _ManageCollectionsSheetState();
}

class _ManageCollectionsSheetState extends State<ManageCollectionsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(AppTheme appTheme, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? appTheme.error : appTheme.snackBarBg,
        content: Text(message),
      ),
    );
  }

  Future<void> _create(
    CollectionNotifier notifier,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    if (notifier.nameExists(name)) {
      _snack(appTheme, l10n.collectionNameExists, isError: true);
      return;
    }
    await notifier.createCollection(name);
    _ctrl.clear();
    if (!mounted) return;
    _snack(appTheme, l10n.collectionCreated(name));
  }

  Future<void> _rename(
    CollectionNotifier notifier,
    AppTheme appTheme,
    AppLocalizations l10n,
    Collection collection,
  ) async {
    final ctrl = TextEditingController(text: collection.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.renameCollectionTitle,
          style: TextStyle(
            color: appTheme.inkDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          style: TextStyle(color: appTheme.inkDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.newCollectionHint,
            hintStyle: TextStyle(color: appTheme.inkLight, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: appTheme.inkLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newName == null || newName.isEmpty || newName == collection.name) {
      return;
    }
    if (!mounted) return;
    if (notifier.nameExists(newName, excludeId: collection.id)) {
      _snack(appTheme, l10n.collectionNameExists, isError: true);
      return;
    }
    await notifier.renameCollection(collection.id, newName);
    if (!mounted) return;
    _snack(appTheme, l10n.collectionRenamed(newName));
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;
    final collectionNotifier = context.watch<CollectionNotifier>();
    final collections = collectionNotifier.collections;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_special_outlined,
                    color: appTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.manageCollections,
                    style: TextStyle(
                      color: appTheme.inkDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: appTheme.border),

            // New collection input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _create(collectionNotifier, appTheme, l10n),
                      style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.newCollectionHint,
                        hintStyle: TextStyle(
                          color: appTheme.inkLight,
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: appTheme.primaryBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: appTheme.border,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: appTheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _create(collectionNotifier, appTheme, l10n),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (collections.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (_, i) {
                    final c = collections[i];
                    return ListTile(
                      leading: Icon(
                        Icons.folder_rounded,
                        color: appTheme.primary,
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                      ),
                      subtitle: Text(
                        l10n.itemCount(c.jewelleryIds.length),
                        style: TextStyle(
                          color: appTheme.inkLight,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: appTheme.inkMid,
                              size: 18,
                            ),
                            onPressed: () => _rename(
                              collectionNotifier,
                              appTheme,
                              l10n,
                              c,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: appTheme.error,
                              size: 18,
                            ),
                            onPressed: () =>
                                collectionNotifier.deleteCollection(c.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.noCollectionsCreateHint,
                  style: TextStyle(
                    color: appTheme.inkLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
