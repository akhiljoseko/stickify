import 'package:stickify/domain/entities/search_item.dart';
import 'package:stickify/domain/repositories/search_repository.dart';

/// Concrete mock implementation of [SearchRepository].
///
/// Houses static catalog data including custom items matching the Stitch
/// search results screen design, and simulates network delays for realistic states.
class MockSearchRepository implements SearchRepository {
  const MockSearchRepository();

  static const List<SearchItem> _kMockSearchItems = [
    // Stitch Mockup Almond Products
    SearchItem(
      id: 'alm-1',
      title: 'Artisanal Toasted Almonds - 150g Pouch',
      sku: 'ALM-TS-150P',
      category: 'Products',
      description: 'Premium toasted almonds package labels for order dispatch.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCQVSTx73sDDgnFaeQscsSiOqXUoFey2fIrD6l_hWTLAl5Slk7Eu3tV_isNuICJ-P386tqV4xCW159n3NWgl4K_Ocy8y0VgUz4TeI0VPC96rpH9pJ2FCx4_6BiQ0F9gCNmsTUPhrkdto6zEgqIeS1Ea6hfpr67Q95dx1LJyAw2O6c7jbwP05t7T8B0Lptrai6pXYZ1B4SzV2HIb48VBOYm9VGBfkIheff22e_I1I6pGyYkVIIVUDW924Kmn9KXz4XPFhxmA3fSyvAo',
      relevanceScore: 0.98,
      tags: ['organic', 'almonds', 'toasted', 'beverage', 'shipping'],
    ),
    SearchItem(
      id: 'alm-2',
      title: 'Artisanal Toasted Almonds - 500g Jar',
      sku: 'ALM-TS-500J',
      category: 'Products',
      description: 'Gourmet toasted almonds in glass jar container.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHygZ1kMLm0HlwIxttGzr_RxCtvFOwOakA456hiUexAVhz0zfutnCajsy_qGwOwbSYbZfxJJCcoaMS7bfs9eXnITU5xUSdBj6Hx7XFfDVaTY6luMrlK2PaQExxz0dh0VItSju7p7SkqpbNE804LCiMtpGjUdBgm-L1Ng6pcyLUUu2XAGPfUxuiw3yYx9ivqjt2Xu0L-R-fQ_ls2wueVGOSVpvrBwRShTxaok9c3TRns6MAO8-greEQ4pIPdaHaOUWBLLm1qqFOgsI',
      relevanceScore: 0.92,
      tags: ['organic', 'almonds', 'toasted', 'jar', 'beverage'],
    ),
    SearchItem(
      id: 'alm-3',
      title: 'Smoked Honey Almonds - 250g Pouch',
      sku: 'ALM-SH-250P',
      category: 'Products',
      description: 'Honey glazed smoked almonds with sweet and salty glisten.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCyvuOnXRLCuoN8kOTpMmc8lJYUuvp6reSnJkGngA1X0RQpu0F8qIBrJD6QEoggq2g2vPQPIhIrLW7LC_V80yitqnub3l5sE-28ufWdEChny6PsNxJxWp00Em_FjeQ_UeckIAa-70un-tmjmWEW_dvXExftSt9hrzxDRWubVd1rgrpEDaiKdeEJEhGvv3ghMmpggUG5sVki3aGxw9fzNq6EkS-Mx96b1FJmA73T6kWJh_TGJeYSvXGgGX2VXJSYKoVmbTbuwcVoo7g',
      relevanceScore: 0.85,
      tags: ['smoked', 'almonds', 'honey', 'pouch', 'beverage'],
    ),
    SearchItem(
      id: 'alm-4',
      title: 'Bulk Raw Almonds - 5kg Sack',
      sku: 'ALM-RW-5KG',
      category: 'Products',
      description: 'Raw, unpeeled whole almonds in large warehouse sack packaging.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBh-ES6WJjwRtOHY0XtMDYAC2NvlRmkusEeIAQTyKs-oQbCylH5k1s50iFe6eAWbstoi5_iqSlWXFzE7msyGy2ELlaJ7TP4bnQXnx6H0OBOLG4pId1rweMcDwJ6-xBtmjVQR6vu-KDbESOpSgjOKQxPOIm9lvFP7uRTPvsPlvJEE1Gd-REUJObfJxsYPjI1ERHWRN3tQY49jlJ61nurSbiu8NMmiq7Stspi0dRCeaFoYJLJeM2GO9-bToP2j73PVvg-rwxcxw3-yqA',
      relevanceScore: 0.78,
      tags: ['raw', 'almonds', 'bulk', 'sack', 'shipping'],
    ),

    // Standard Catalog Items
    SearchItem(
      id: '1',
      title: 'Organic Cold Brew 12oz',
      sku: 'BEV-CB-ORG-12',
      category: 'Products',
      description: 'Premium organic cold brew coffee labels for warehouse processing.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.98,
      tags: ['organic', 'beverage', 'cold-brew', 'shipping'],
    ),
    SearchItem(
      id: '2',
      title: 'Premium Matte Label Stock',
      sku: 'STK-MT-LBL-01',
      category: 'Products',
      description: 'High-durability matte finish label roll for industrial use.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.92,
      tags: ['stock', 'matte', 'label', 'barcode', 'hardware'],
    ),
    SearchItem(
      id: '3',
      title: 'Thermal Gloss Sticker Paper',
      sku: 'THR-GL-STK-02',
      category: 'Products',
      description: 'Glossy thermal adhesive sticker rolls for shipping codes.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.85,
      tags: ['thermal', 'glossy', 'sticker', 'standard'],
    ),
    SearchItem(
      id: '4',
      title: 'Shipping Label Standard',
      sku: 'SHP-LBL-STD-46',
      category: 'Templates',
      description: 'Standard 4x6 shipping address barcode layout template.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.95,
      tags: ['shipping', 'standard', '4x6', 'barcode'],
    ),
    SearchItem(
      id: '5',
      title: 'Product Warning Tag',
      sku: 'PRD-WRN-TAG-01',
      category: 'Templates',
      description: 'Warning notice and safety icon layout templates.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.89,
      tags: ['warning', 'safety', 'hazard', 'standard'],
    ),
    SearchItem(
      id: '6',
      title: 'Barcode Inventory Label',
      sku: 'BAR-INV-LBL-02',
      category: 'Templates',
      description: 'Clean barcode inventory label layout for warehouse scanning.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.82,
      tags: ['barcode', 'inventory', 'technical', 'standard'],
    ),
    SearchItem(
      id: '7',
      title: 'Printer Station #01',
      sku: 'PRN-STN-01',
      category: 'Stations',
      description: 'High-speed industrial thermal printer node in Packing Zone A.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.78,
      tags: ['printer', 'hardware', 'station-1', 'barcode'],
    ),
    SearchItem(
      id: '8',
      title: 'Printer Station #02',
      sku: 'PRN-STN-02',
      category: 'Stations',
      description: 'Backup thermal printer node in Loading Dock B.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
      relevanceScore: 0.75,
      tags: ['printer', 'hardware', 'station-2', 'barcode'],
    ),
  ];

  @override
  Future<List<SearchItem>> search(
    String query, {
    Set<String>? categories,
    Set<String>? tags,
    bool sortByRelevance = true,
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final cleanQuery = query.trim().toLowerCase();

    // 1. Text Query Filter
    var items = _kMockSearchItems.where((item) {
      final matchesTitle = item.title.toLowerCase().contains(cleanQuery);
      final matchesSku = (item.sku ?? '').toLowerCase().contains(cleanQuery);
      final matchesDescription = item.description.toLowerCase().contains(cleanQuery);
      final matchesTags = item.tags.any((t) => t.toLowerCase().contains(cleanQuery));
      return matchesTitle || matchesSku || matchesDescription || matchesTags;
    }).toList();

    // 2. Category Facet Filter
    if (categories != null && categories.isNotEmpty) {
      items = items.where((item) => categories.contains(item.category)).toList();
    }

    // 3. Tag Facet Filter
    if (tags != null && tags.isNotEmpty) {
      items = items.where((item) => item.tags.any((t) => tags.contains(t))).toList();
    }

    // 4. Sort Ordering
    if (sortByRelevance) {
      items.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    } else {
      items.sort((a, b) => a.title.compareTo(b.title));
    }

    return items;
  }
}
