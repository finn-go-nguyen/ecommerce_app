import 'dart:math';

import 'package:ecommerce_app/src/features/cart/presentation/shopping_cart/shopping_cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../common_widgets/common_widgets.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../localization/string_hardcoded.dart';
import '../../../products/data/fake_products_repository.dart';
import '../../../products/domain/product.dart';
import '../../domain/item.dart';

/// Shows a shopping cart item (or loading/error UI if needed)
class ShoppingCartItem extends StatelessWidget {
  const ShoppingCartItem({
    Key? key,
    required this.item,
    required this.itemIndex,
    this.isEditable = true,
  }) : super(key: key);
  final Item item;
  final int itemIndex;

  /// if true, an [ItemQuantitySelector] and a delete button will be shown
  /// if false, the quantity will be shown as a read-only label (used in the
  /// [PaymentPage])
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.p8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Consumer(builder: (context, ref, child) {
            final productValue =
                ref.watch(productStreamProvider(item.productId));
            return AsyncValueWidget<Product?>(
              value: productValue,
              data: (product) => ShoppingCartItemContents(
                product: product!,
                item: item,
                itemIndex: itemIndex,
                isEditable: isEditable,
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Shows a shopping cart item for a given product
class ShoppingCartItemContents extends StatelessWidget {
  const ShoppingCartItemContents({
    Key? key,
    required this.product,
    required this.item,
    required this.itemIndex,
    required this.isEditable,
  }) : super(key: key);
  final Product product;
  final Item item;
  final int itemIndex;
  final bool isEditable;

  // * Keys for testing using find.byKey()
  static Key deleteKey(int index) => Key('delete-$index');

  @override
  Widget build(BuildContext context) {
    // TODO: error handling
    // TODO: Inject formatter
    final priceFormatted = NumberFormat.simpleCurrency().format(product.price);
    return ResponsiveTwoColumnLayout(
      startFlex: 1,
      endFlex: 2,
      breakpoint: 320,
      startContent: CustomImage(imageUrl: product.imageUrl),
      spacing: Sizes.p24,
      endContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(product.title, style: Theme.of(context).textTheme.headline5),
          gapH24,
          Text(priceFormatted, style: Theme.of(context).textTheme.headline5),
          gapH24,
          isEditable
              // show the quantity selector and a delete button
              ? EditOrRemoveItemWidget(
                  product: product,
                  item: item,
                  itemIndex: itemIndex,
                )
              // else, show the quantity as a read-only label
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sizes.p8),
                  child: Text(
                    'Quantity: ${item.quantity}'.hardcoded,
                  ),
                ),
        ],
      ),
    );
  }
}

// custom widget to show the quantity selector and a delete button
class EditOrRemoveItemWidget extends ConsumerWidget {
  const EditOrRemoveItemWidget({
    super.key,
    required this.product,
    required this.item,
    required this.itemIndex,
  });
  final Product product;
  final Item item;
  final int itemIndex;

  // * Keys for testing using find.byKey()
  static Key deleteKey(int index) => Key('delete-$index');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingCartcontrollerProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ItemQuantitySelector(
          quantity: item.quantity,
          maxQuantity: min(product.availableQuantity, 10),
          itemIndex: itemIndex,
          onChanged: state.isLoading
              ? null
              : (quantity) => ref
                  .read(shoppingCartcontrollerProvider.notifier)
                  .updateItemQuantity(item.productId, quantity),
        ),
        IconButton(
          key: deleteKey(itemIndex),
          icon: Icon(Icons.delete, color: Colors.red[700]),
          onPressed: state.isLoading
              ? null
              : () => ref
                  .read(shoppingCartcontrollerProvider.notifier)
                  .removeItemById(item.productId),
        ),
        const Spacer(),
      ],
    );
  }
}
