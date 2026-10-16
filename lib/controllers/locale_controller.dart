// ============================================================================
// CONTROLADOR DE IDIOMA
// Maneja el cambio de idioma y lo persiste con SharedPreferences
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _keyLocale = 'app_locale';

  Locale _locale = const Locale('es'); // Español por defecto

  Locale get locale => _locale;

  // ==========================================================================
  // Cargar el idioma guardado
  // ==========================================================================
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_keyLocale) ?? 'es';
    _locale = Locale(langCode);
    notifyListeners();
  }

  // ==========================================================================
  // Cambiar el idioma
  // ==========================================================================
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
  }

  // ==========================================================================
  // Alternar entre español e inglés
  // ==========================================================================
  Future<void> toggleLocale() async {
    final newLang = _locale.languageCode == 'es' ? 'en' : 'es';
    await setLocale(Locale(newLang));
  }
}