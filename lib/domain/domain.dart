/// Global domain layer barrel export.
///
/// Import this single file to access all domain entities and repository
/// interfaces:
/// ```dart
/// import 'package:stickify/domain/domain.dart';
/// ```
library;

export 'entities/editor/barcode_element_blueprint.dart';
export 'entities/editor/element_blueprint.dart';
export 'entities/editor/image_element_blueprint.dart';
export 'entities/editor/qr_element_blueprint.dart';
export 'entities/editor/shape_element_blueprint.dart';
export 'entities/editor/text_element_blueprint.dart';
export 'entities/ingredient.dart';
export 'entities/label_template.dart';
export 'entities/nutrition_facts.dart';
export 'entities/print_job.dart';
export 'entities/printer_device.dart';
export 'entities/product.dart';
export 'entities/product_variant.dart';
export 'entities/search_item.dart';
export 'entities/sheet_config.dart';
export 'entities/sticker_config.dart';
export 'repositories/print_job_repository.dart';
export 'repositories/product_repository.dart';
export 'repositories/search_repository.dart';
export 'repositories/template_repository.dart';
export 'services/label_layout_engine.dart';
export 'services/paper_validation_engine.dart';
export 'services/print_service.dart';
export 'entities/feature_id.dart';
export 'entities/feature_availability.dart';
export 'services/auth_service.dart';
export 'services/local_database.dart';
export 'services/remote_database_service.dart';
export 'services/feature_access_service.dart';
export 'services/printer_discovery_service.dart';
export 'services/print_job_id_generator.dart';
