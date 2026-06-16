import 'package:flutter/foundation.dart';

/// Minimal provider with no database dependencies
/// Used only for iOS 27 compatibility testing
class MedicationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get medications => _medications;
  bool get isLoading => _isLoading;

  /// Initialize - no-op for testing
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    // No database initialization
    _medications = [];
    
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh - no-op for testing
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    
    // No database refresh
    _medications = [];
    
    _isLoading = false;
    notifyListeners();
  }
}
