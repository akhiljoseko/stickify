import 'package:stickify/core/environment/app_environment.dart';
import 'package:stickify/core/environment/app_experience.dart';
import 'package:stickify/core/features/feature_availability.dart';
import 'package:stickify/core/features/feature_id.dart';

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
        if (environment.experience == AppExperience.mobile) {
          return FeatureAvailability.desktopOnly;
        }
        return FeatureAvailability.available;
    }
  }
}
