import 'package:hive_ce/hive_ce.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/data/models/hive/printer_profile_hive_model.dart';
import 'package:stickify/data/models/hive/product_hive_model.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/data/models/hive/variant_print_stats_hive_model.dart';

@GenerateAdapters([
  AdapterSpec<CalibrationRuleHiveModel>(),
  AdapterSpec<CalibrationTargetHiveModel>(),
  AdapterSpec<ElementBlueprintHiveModel>(),
  AdapterSpec<IngredientHiveModel>(),
  AdapterSpec<LabelTemplateHiveModel>(),
  AdapterSpec<NutritionFactsHiveModel>(),
  AdapterSpec<OptimizationPreferencesHiveModel>(),
  AdapterSpec<PaperConfigurationReferenceHiveModel>(),
  AdapterSpec<PrintJobHiveModel>(),
  AdapterSpec<PrintStickerTransformHiveModel>(),
  AdapterSpec<PrinterCalibrationHiveModel>(),
  AdapterSpec<PrinterCapabilitiesHiveModel>(),
  AdapterSpec<PrinterIdentityHiveModel>(),
  AdapterSpec<PrinterProfileHiveModel>(),
  AdapterSpec<PrinterTrayProfileHiveModel>(),
  AdapterSpec<ProductHiveModel>(),
  AdapterSpec<ProductVariantHiveModel>(),
  AdapterSpec<SheetConfigHiveModel>(),
  AdapterSpec<StickerConfigHiveModel>(),
  AdapterSpec<StickerPointHiveModel>(),
  AdapterSpec<VariantPrintStatsHiveModel>(),
])
part 'hive_adapters.g.dart';
