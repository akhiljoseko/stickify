import 'package:stickify/core/environment/app_environment.dart';
import 'package:stickify/domain/entities/feature_availability.dart';
import 'package:stickify/domain/entities/feature_id.dart';

/// Centralized service to evaluate if a feature is available on the current platform/form-factor.
class FeatureAccessService {
  /// Instantiates a new [FeatureAccessService].
  const FeatureAccessService();

  /// Checks the active [FeatureAvailability] mode for a given [feature] and [environment].
  FeatureAvailability availabilityOf(
    FeatureId feature,
    AppEnvironment environment,
  ) {
    switch (feature) {
      case FeatureId.dashboard:
      case FeatureId.printSetup:
      case FeatureId.search:
      case FeatureId.productCatalogView:
      case FeatureId.productVariantEdit:
        return FeatureAvailability.available;

      case FeatureId.templateCreation:
      case FeatureId.productCatalogAdmin:
        return FeatureAvailability.available;
    }
  }
}
