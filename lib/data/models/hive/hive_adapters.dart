import 'package:hive_ce/hive_ce.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/data/models/hive/product_hive_model.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';

@GenerateAdapters([
  AdapterSpec<ElementBlueprintHiveModel>(),
  AdapterSpec<IngredientHiveModel>(),
  AdapterSpec<LabelTemplateHiveModel>(),
  AdapterSpec<NutritionFactsHiveModel>(),
  AdapterSpec<PrintJobHiveModel>(),
  AdapterSpec<ProductHiveModel>(),
  AdapterSpec<ProductVariantHiveModel>(),
  AdapterSpec<SheetConfigHiveModel>(),
  AdapterSpec<StickerConfigHiveModel>(),
  AdapterSpec<StickerPointHiveModel>(),
])
part 'hive_adapters.g.dart';
