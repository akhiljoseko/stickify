import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/environment/app_environment.dart';
import 'package:stickify/core/environment/app_experience.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/desktop_product_management_screen.dart';
import 'package:stickify/presentation/features/product/presentation/mobile/mobile_product_management_screen.dart';

/// Screen displaying the catalogue list of products and allowing administration operations.
/// Integrates CRUD actions for adding and updating products and their variants.
/// Resolves the layout dynamically between Desktop and Mobile optimized viewports.
class ProductManagementScreen extends StatelessWidget {
  /// Creates a [ProductManagementScreen] instance.
  const ProductManagementScreen({this.initialSubView, super.key});

  /// The initial sub-view to open.
  final String? initialSubView;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCubit(
        context.read<ProductRepository>(),
        context.read<FileStorageService>(),
      )..fetchPage(pageKey: 0, pageSize: 20),
      child: const _ProductManagementView(),
    );
  }
}

class _ProductManagementView extends StatelessWidget {
  const _ProductManagementView();

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();

    if (env.experience == AppExperience.mobile) {
      return const MobileProductManagementScreen();
    } else {
      return const DesktopProductManagementScreen();
    }
  }
}
