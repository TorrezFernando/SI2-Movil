import 'package:flutter/foundation.dart';
import '../../data/models/propiedad_model.dart';
import '../../data/repositories/propiedades_repository.dart';

class PropiedadesProvider extends ChangeNotifier {
  PropiedadesProvider(this._repository);

  final PropiedadesRepository _repository;

  List<PropiedadModel> _propiedades = [];
  List<PropiedadModel> get propiedades => _propiedadesFiltradas;
  List<PropiedadModel> _propiedadesFiltradas = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filtros
  double? _precioMin;
  double? _precioMax;
  String? _tipoOperacion;
  String? _estado;

  double? get precioMin => _precioMin;
  double? get precioMax => _precioMax;
  String? get tipoOperacion => _tipoOperacion;
  String? get estado => _estado;

  void setFiltros({
    double? min,
    double? max,
    String? tipoOp,
    String? est,
  }) {
    _precioMin = min;
    _precioMax = max;
    _tipoOperacion = tipoOp;
    _estado = est;
    _aplicarFiltros();
  }
  
  void limpiarFiltros() {
    _precioMin = null;
    _precioMax = null;
    _tipoOperacion = null;
    _estado = null;
    _propiedadesFiltradas = List.from(_propiedades);
    notifyListeners();
  }

  void _aplicarFiltros() {
    _propiedadesFiltradas = _propiedades.where((p) {
      if (_precioMin != null && p.precio < _precioMin!) return false;
      if (_precioMax != null && p.precio > _precioMax!) return false;
      if (_tipoOperacion != null && _tipoOperacion!.isNotEmpty && p.tipoOperacion != _tipoOperacion) return false;
      if (_estado != null && _estado!.isNotEmpty && p.estado != _estado) return false;
      return true;
    }).toList();
    notifyListeners();
  }

  Future<void> fetchPropiedades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _propiedades = await _repository.getPropiedades();
      _aplicarFiltros();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
