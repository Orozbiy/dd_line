import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _ky = {
    'settings':       'Жөндөөлөр',
    'language':       'Тил',
    'notifications':  'Билдирмелер',
    'dark_mode':      'Күңүрт режим',
    'profile':        'Профил',
    'cache':          'Кэшти тазалоо',
    'support':        'Колдоо',
    'terms':          'Эрежелер',
    'home':           'Башкы',
    'cart':           'Себет',
    'favorites':      'Тандамалар',
    'chat':           'Чат',
    'search':         'Издөө',
    'save':           'Сактоо',
    'cancel':         'Жокко чыгаруу',
    'delete':         'Өчүрүү',
    'yes':            'Ооба',
    'no':             'Жок',
    'loading':        'Жүктөлүүдө...',
    'error':          'Ката кетти',
    'success':        'Ийгиликтүү',
    'shop':           'Дүкөн',
    'product':        'Товар',
    'price':          'Баасы',
    'add_to_cart':    'Себетке кошуу',
    'sign_out':       'Чыгуу',
  };

  static const _ru = {
    'settings':       'Настройки',
    'language':       'Язык',
    'notifications':  'Уведомления',
    'dark_mode':      'Тёмный режим',
    'profile':        'Профиль',
    'cache':          'Очистить кэш',
    'support':        'Поддержка',
    'terms':          'Правила',
    'home':           'Главная',
    'cart':           'Корзина',
    'favorites':      'Избранное',
    'chat':           'Чат',
    'search':         'Поиск',
    'save':           'Сохранить',
    'cancel':         'Отмена',
    'delete':         'Удалить',
    'yes':            'Да',
    'no':             'Нет',
    'loading':        'Загрузка...',
    'error':          'Ошибка',
    'success':        'Успешно',
    'shop':           'Магазин',
    'product':        'Товар',
    'price':          'Цена',
    'add_to_cart':    'В корзину',
    'sign_out':       'Выйти',
  };

  String get(String key) {
    final map = locale.languageCode == 'ru' ? _ru : _ky;
    return map[key] ?? key;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ky', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}