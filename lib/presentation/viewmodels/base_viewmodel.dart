import 'package:flutter/material.dart';

enum ViewState { idle, busy, error }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }
}
