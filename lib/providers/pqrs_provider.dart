import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/models.dart';
import '../data/repositories/banking_repository.dart';

class PqrsProvider extends ChangeNotifier {
  final _repo = PqrsRepository();

  List<PqrsModel> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.myPqrs();
    } on ApiException catch (e) {
      error = e.friendly;
    } catch (e) {
      error = 'No se pudieron cargar tus PQRS.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String type,
    required String subject,
    required String message,
  }) async {
    error = null;
    try {
      final created =
          await _repo.create(type: type, subject: subject, message: message);
      items = [created, ...items];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.friendly;
      notifyListeners();
      return false;
    } catch (e) {
      error = 'No se pudo enviar tu PQRS.';
      notifyListeners();
      return false;
    }
  }
}
