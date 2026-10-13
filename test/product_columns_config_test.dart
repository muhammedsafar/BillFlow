import 'package:flutter_test/flutter_test.dart';
import 'package:billflow/common/common.dart';

void main() {
  test('stockEditAdminOnly defaults off, including in configs saved before it',
      () {
    expect(const ProductColumnsConfig().stockEditAdminOnly, isFalse);
    expect(ProductColumnsConfig.fromJson({'purchasePriceAdminOnly': true})
        .stockEditAdminOnly, isFalse);
  });

  test('stockEditAdminOnly survives JSON and copyWith', () {
    final on = const ProductColumnsConfig().copyWith(stockEditAdminOnly: true);
    expect(ProductColumnsConfig.fromJson(on.toJson()).stockEditAdminOnly, isTrue);
    expect(on.copyWith(stock: false).stockEditAdminOnly, isTrue);
  });

  test('fieldOrder and metaOrder default, sanitize, and survive JSON', () {
    const config = ProductColumnsConfig();
    expect(config.fieldOrder, ProductColumnsConfig.defaultFieldOrder);
    expect(config.metaOrder, ProductColumnsConfig.defaultMetaOrder);

    final reordered = config.copyWith(
      fieldOrder: ['extraCost', 'name', 'price'],
      metaOrder: ['metaNotes', 'metaExpiryDate'],
    );
    // Sanitization appends remaining fields without duplicates
    expect(reordered.fieldOrder.first, 'extraCost');
    expect(reordered.fieldOrder.length, ProductColumnsConfig.defaultFieldOrder.length);
    expect(reordered.metaOrder.first, 'metaNotes');
    expect(reordered.metaOrder.length, ProductColumnsConfig.defaultMetaOrder.length);

    final fromJson = ProductColumnsConfig.fromJson(reordered.toJson());
    expect(fromJson.fieldOrder.first, 'extraCost');
    expect(fromJson.metaOrder.first, 'metaNotes');
    expect(fromJson.fieldOrder.contains('image'), isTrue);
  });

  test('image field defaults true and survives JSON and copyWith', () {
    const config = ProductColumnsConfig();
    expect(config.image, isTrue);
    expect(ProductColumnsConfig.defaultFieldOrder.contains('image'), isTrue);

    final disabled = config.copyWith(image: false);
    expect(disabled.image, isFalse);
    expect(ProductColumnsConfig.fromJson(disabled.toJson()).image, isFalse);

    // Existing config without 'image' key defaults to true
    expect(ProductColumnsConfig.fromJson({}).image, isTrue);
  });
}

