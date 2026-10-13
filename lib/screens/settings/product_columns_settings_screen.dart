import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billflow/common/common.dart';
import 'package:billflow/l10n/app_localizations.dart';
import 'package:billflow/providers/repositories.dart';
import 'package:billflow/common/constants.dart';

class ProductColumnsSettingsScreen extends ConsumerStatefulWidget {
  const ProductColumnsSettingsScreen({super.key});

  @override
  ConsumerState<ProductColumnsSettingsScreen> createState() =>
      _ProductColumnsSettingsScreenState();
}

class _ProductColumnsSettingsScreenState
    extends ConsumerState<ProductColumnsSettingsScreen> {
  ProductColumnsConfig _config = const ProductColumnsConfig();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMetadataExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final config = await settingsRepo.getProductColumnsConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setProductColumnsConfig(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productColumnsSavedMessage)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onReorderField(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final items = List<String>.from(_config.fieldOrder);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      _config = _config.copyWith(fieldOrder: items);
    });
  }

  void _onReorderMeta(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final items = List<String>.from(_config.metaOrder);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      _config = _config.copyWith(metaOrder: items);
    });
  }

  Widget _buildItemCard({
    required Key key,
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Widget? actionWidget,
    bool isSubItem = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = onChanged == null
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : (isSubItem
            ? (isDark
                ? theme.colorScheme.surfaceContainerHigh
                : Colors.grey.shade100)
            : theme.colorScheme.surfaceContainer);

    return Container(
      key: key,
      margin: EdgeInsets.only(
        left: isSubItem ? 32 : 0,
        right: 0,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: isSubItem
              ? theme.primaryColor.withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (value && onChanged != null)
                      ? theme.primaryColor.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: (value && onChanged != null)
                      ? theme.primaryColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionWidget != null) actionWidget,
              const SizedBox(width: 8),
              // Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldItemWidget(String fieldKey, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (fieldKey) {
      case 'name':
        return _buildItemCard(
          key: const ValueKey('name'),
          index: index,
          title: l10n.productColumnsNameLabel,
          subtitle: l10n.productColumnsAlwaysRequiredSubtitle,
          icon: Icons.label_outline,
          value: true,
          onChanged: null,
        );
      case 'price':
        return _buildItemCard(
          key: const ValueKey('price'),
          index: index,
          title: l10n.productColumnsPriceLabel,
          subtitle: l10n.productColumnsAlwaysRequiredSubtitle,
          icon: Icons.currency_rupee,
          value: true,
          onChanged: null,
        );
      case 'stock':
        return _buildItemCard(
          key: const ValueKey('stock'),
          index: index,
          title: l10n.productColumnsStockLabel,
          subtitle: l10n.productColumnsStockSubtitle,
          icon: Icons.inventory_2_outlined,
          value: _config.stock,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(stock: v)),
        );
      case 'aliasName':
        return _buildItemCard(
          key: const ValueKey('aliasName'),
          index: index,
          title: l10n.productColumnsAliasNameLabel,
          subtitle: l10n.productColumnsAliasNameSubtitle,
          icon: Icons.translate,
          value: _config.aliasName,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(aliasName: v)),
        );
      case 'taxRate':
        return _buildItemCard(
          key: const ValueKey('taxRate'),
          index: index,
          title: l10n.productColumnsTaxRateLabel,
          subtitle: l10n.productColumnsTaxRateSubtitle,
          icon: Icons.percent_rounded,
          value: _config.taxRate,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(taxRate: v)),
        );
      case 'hsncode':
        return _buildItemCard(
          key: const ValueKey('hsncode'),
          index: index,
          title: l10n.productColumnsHsnSacLabel,
          subtitle: l10n.productColumnsHsnSacSubtitle,
          icon: Icons.qr_code_2,
          value: _config.hsncode,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(hsncode: v)),
        );
      case 'skuCode':
        return _buildItemCard(
          key: const ValueKey('skuCode'),
          index: index,
          title: l10n.productColumnsMetaSkuCodeLabel,
          subtitle: 'Unique Stock Keeping Unit barcode / identifier.',
          icon: Icons.qr_code_2,
          value: _config.metaSkuCode,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(metaSkuCode: v)),
        );
      case 'image':
        return _buildItemCard(
          key: const ValueKey('image'),
          index: index,
          title: 'Product Image',
          subtitle: 'Add and display image attachments (URL or upload) for products.',
          icon: Icons.image_outlined,
          value: _config.image,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(image: v)),
        );
      case 'description':
        return _buildItemCard(
          key: const ValueKey('description'),
          index: index,
          title: l10n.productColumnsDescriptionLabel,
          subtitle: l10n.productColumnsDescriptionSubtitle,
          icon: Icons.notes,
          value: _config.description,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(description: v)),
        );
      case 'purchasePrice':
        return _buildItemCard(
          key: const ValueKey('purchasePrice'),
          index: index,
          title: l10n.productColumnsPurchasePriceLabel,
          subtitle: l10n.productColumnsPurchasePriceSubtitle,
          icon: Icons.shopping_cart_outlined,
          value: _config.purchasePrice,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(purchasePrice: v)),
        );
      case 'purchasePriceAdminOnly':
        return _buildItemCard(
          key: const ValueKey('purchasePriceAdminOnly'),
          index: index,
          title: l10n.productColumnsPurchasePriceAdminOnlyLabel,
          subtitle: l10n.productColumnsPurchasePriceAdminOnlySubtitle,
          icon: Icons.admin_panel_settings_outlined,
          value: _config.purchasePriceAdminOnly,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(purchasePriceAdminOnly: v)),
        );
      case 'stockEditAdminOnly':
        return _buildItemCard(
          key: const ValueKey('stockEditAdminOnly'),
          index: index,
          title: l10n.productColumnsStockEditAdminOnlyLabel,
          subtitle: l10n.productColumnsStockEditAdminOnlySubtitle,
          icon: Icons.inventory_2_outlined,
          value: _config.stockEditAdminOnly,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(stockEditAdminOnly: v)),
        );
      case 'defaultDiscount':
        return _buildItemCard(
          key: const ValueKey('defaultDiscount'),
          index: index,
          title: l10n.productColumnsDefaultDiscountLabel,
          subtitle: l10n.productColumnsDefaultDiscountSubtitle,
          icon: Icons.discount_outlined,
          value: _config.defaultDiscount,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(defaultDiscount: v)),
        );
      case 'unit':
        return _buildItemCard(
          key: const ValueKey('unit'),
          index: index,
          title: l10n.productColumnsUnitLabel,
          subtitle: l10n.productColumnsUnitSubtitle,
          icon: Icons.straighten,
          value: _config.unit,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(unit: v)),
        );
      case 'type':
        return _buildItemCard(
          key: const ValueKey('type'),
          index: index,
          title: l10n.productColumnsProductServiceTypeLabel,
          subtitle: l10n.productColumnsProductServiceTypeSubtitle,
          icon: Icons.category_outlined,
          value: _config.type,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(type: v)),
        );
      case 'extraCost':
        return _buildItemCard(
          key: const ValueKey('extraCost'),
          index: index,
          title: l10n.productColumnsExtraCostLabel,
          subtitle: l10n.productColumnsExtraCostSubtitle,
          icon: Icons.add_card_outlined,
          value: _config.extraCost,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(extraCost: v)),
        );
      default:
        return const SizedBox.shrink(key: ValueKey('empty'));
    }
  }

  Widget _buildMetaItemWidget(String metaKey, int subIndex) {
    final l10n = AppLocalizations.of(context)!;
    switch (metaKey) {
      case 'metaStorageLocation':
        return _buildItemCard(
          key: const ValueKey('metaStorageLocation'),
          index: subIndex,
          title: l10n.productColumnsMetaStorageLocationLabel,
          subtitle: 'Aisle, shelf, rack, or bin storage coordinates.',
          icon: Icons.place_outlined,
          value: _config.metaStorageLocation,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(metaStorageLocation: v)),
          isSubItem: true,
        );
      case 'metaContainerNumber':
        return _buildItemCard(
          key: const ValueKey('metaContainerNumber'),
          index: subIndex,
          title: l10n.productColumnsMetaContainerNumberLabel,
          subtitle: 'Container, carton, or shipping box identifier.',
          icon: Icons.inventory_2_outlined,
          value: _config.metaContainerNumber,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(metaContainerNumber: v)),
          isSubItem: true,
        );
      case 'metaBatchNumber':
        return _buildItemCard(
          key: const ValueKey('metaBatchNumber'),
          index: subIndex,
          title: l10n.productColumnsMetaBatchNumberLabel,
          subtitle: 'Production batch or lot tracking code.',
          icon: Icons.tag,
          value: _config.metaBatchNumber,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(metaBatchNumber: v)),
          isSubItem: true,
        );
      case 'metaExpiryDate':
        return _buildItemCard(
          key: const ValueKey('metaExpiryDate'),
          index: subIndex,
          title: l10n.productColumnsMetaExpiryDateLabel,
          subtitle: 'Product expiration or best-before date.',
          icon: Icons.event_outlined,
          value: _config.metaExpiryDate,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(metaExpiryDate: v)),
          isSubItem: true,
        );
      case 'metaManufactureDate':
        return _buildItemCard(
          key: const ValueKey('metaManufactureDate'),
          index: subIndex,
          title: l10n.productColumnsMetaManufactureDateLabel,
          subtitle: 'Date when product was manufactured.',
          icon: Icons.precision_manufacturing_outlined,
          value: _config.metaManufactureDate,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(metaManufactureDate: v)),
          isSubItem: true,
        );
      case 'metaManufactureName':
        return _buildItemCard(
          key: const ValueKey('metaManufactureName'),
          index: subIndex,
          title: l10n.productColumnsMetaManufactureNameLabel,
          subtitle: 'Producing company or brand manufacturer.',
          icon: Icons.factory_outlined,
          value: _config.metaManufactureName,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(metaManufactureName: v)),
          isSubItem: true,
        );
      case 'metaSupplierName':
        return _buildItemCard(
          key: const ValueKey('metaSupplierName'),
          index: subIndex,
          title: l10n.productColumnsMetaSupplierNameLabel,
          subtitle: 'Distributor or vendor supplier name.',
          icon: Icons.local_shipping_outlined,
          value: _config.metaSupplierName,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(metaSupplierName: v)),
          isSubItem: true,
        );
      case 'metaNotes':
        return _buildItemCard(
          key: const ValueKey('metaNotes'),
          index: subIndex,
          title: l10n.productColumnsMetaNotesLabel,
          subtitle: 'Internal product notes or handling remarks.',
          icon: Icons.notes,
          value: _config.metaNotes,
          onChanged: (v) =>
              setState(() => _config = _config.copyWith(metaNotes: v)),
          isSubItem: true,
        );
      default:
        return const SizedBox.shrink(key: ValueKey('empty_sub'));
    }
  }

  Widget _buildProductMetadataGroup(int index) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('productMetadata'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Metadata Header Card
          _buildItemCard(
            key: const ValueKey('productMetadata_header'),
            index: index,
            title: l10n.productColumnsMetadataLabel,
            subtitle: l10n.productColumnsMetadataSubtitle,
            icon: Icons.more_horiz,
            value: _config.productMetadata,
            onChanged: (v) => setState(
                () => _config = _config.copyWith(productMetadata: v)),
            actionWidget: Tooltip(
              message: _isMetadataExpanded ? 'Collapse' : 'Expand',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(
                    () => _isMetadataExpanded = !_isMetadataExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: AnimatedRotation(
                    turns: _isMetadataExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sub-items list (when expanded and metadata enabled)
          if (_isMetadataExpanded && _config.productMetadata) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right,
                      size: 16,
                      color: theme.primaryColor.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Metadata Fields (Drag to reorder):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _config.metaOrder.length,
              onReorder: _onReorderMeta,
              itemBuilder: (context, subIndex) {
                final metaKey = _config.metaOrder[subIndex];
                return _buildMetaItemWidget(metaKey, subIndex);
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.grey[50],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.productColumnsScreenTitle),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.productColumnsScreenTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _config = _config.copyWith(
                                fieldOrder:
                                    ProductColumnsConfig.defaultFieldOrder,
                                metaOrder:
                                    ProductColumnsConfig.defaultMetaOrder,
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order reset to defaults.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset Order'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Save button pinned at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving
                            ? l10n.createInvoiceSavingEllipsisLabel
                            : l10n.actionSave),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(
              width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.productColumnsIntroText,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.drag_indicator,
                                            size: 16,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Drag the handles to rearrange display positions.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Reorderable Main List
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: _config.fieldOrder.length,
                            onReorder: _onReorderField,
                            itemBuilder: (context, index) {
                              final fieldKey = _config.fieldOrder[index];
                              if (fieldKey == 'productMetadata') {
                                return _buildProductMetadataGroup(index);
                              }
                              return _buildFieldItemWidget(fieldKey, index);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
