import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import '../services/seed_data.dart';

class ServicesProvider extends ChangeNotifier {
  List<Service> _services = SeedData.officialServices;
  bool _isLoading = false;
  String? _selectedCategory;
  String _searchQuery = '';

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<Service> get filteredServices {
    return _services.where((s) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'all' ||
          s.category == _selectedCategory;

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          s.nameBn.toLowerCase().contains(query) ||
          s.nameEn.toLowerCase().contains(query) ||
          s.slug.toLowerCase().contains(query) ||
          s.departmentBn.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Service> get featuredServices {
    const topSlugs = [
      'passport',
      'nid-correction',
      'birth-registration',
      'widow-allowance',
      'scholarship',
      'trade-license',
    ];
    final list = _services.where((s) => topSlugs.contains(s.slug)).toList();
    return list.isNotEmpty ? list : _services.take(6).toList();
  }

  ServicesProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadServices();
    });
  }

  Future<void> loadServices() async {
    final fetched = await ApiService.fetchAllServices();
    if (fetched.isNotEmpty) {
      _services = fetched;
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    if (category == 'all') {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    notifyListeners();
  }
}

