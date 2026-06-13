class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<CategoryModel> getCategories() {
    return [
      const CategoryModel(id: '1',  name: 'Кийим-кече',           icon: '👕', color: 'FF6B6B'),
      const CategoryModel(id: '2',  name: 'Эркектер кийими',       icon: '👔', color: '4895EF'),
      const CategoryModel(id: '3',  name: 'Аялдар кийими',         icon: '👗', color: 'FF6B9D'),
      const CategoryModel(id: '4',  name: 'Балдар кийими',         icon: '🧒', color: 'FFD93D'),
      const CategoryModel(id: '5',  name: 'Мектеп формасы',        icon: '🏫', color: '6BCB77'),
      const CategoryModel(id: '6',  name: 'Кышкы кийим',           icon: '🧥', color: '4ECDC4'),
      const CategoryModel(id: '7',  name: 'Жайкы кийим',           icon: '☀️', color: 'FF922B'),
      const CategoryModel(id: '8',  name: 'Күзгү / Жазгы кийим',  icon: '🍂', color: 'F4A261'),
      const CategoryModel(id: '9',  name: 'Спорт кийими',          icon: '🏋️', color: 'AA96DA'),
      const CategoryModel(id: '10', name: 'Бут кийим',             icon: '👟', color: 'C77DFF'),
      const CategoryModel(id: '11', name: 'Аксессуарлар',          icon: '👜', color: 'FFD93D'),
      const CategoryModel(id: '12', name: 'Сумкалар',              icon: '🎒', color: 'FF6B6B'),
      const CategoryModel(id: '13', name: 'Кол / Баш кийим',       icon: '🧤', color: '4ECDC4'),
      const CategoryModel(id: '14', name: 'Зергерчилик',           icon: '💍', color: 'E63946'),
      const CategoryModel(id: '15', name: 'Кездеме / Мата',        icon: '🧵', color: 'F4A261'),
      const CategoryModel(id: '16', name: 'Электроника',           icon: '📱', color: '4895EF'),
      const CategoryModel(id: '17', name: 'Муздаткыч / Техника',   icon: '❄️', color: '52B788'),
      const CategoryModel(id: '18', name: 'Кир жуучу машина',      icon: '🫧', color: 'AA96DA'),
      const CategoryModel(id: '19', name: 'Куралдар / Инструмент', icon: '🔧', color: '888888'),
      const CategoryModel(id: '20', name: 'Үй буюмдар',            icon: '🏠', color: 'FF922B'),
      const CategoryModel(id: '21', name: 'Үй өсүмдүктөрү',       icon: '🪴', color: '6BCB77'),
      const CategoryModel(id: '22', name: 'Дүкөн буюмдары',        icon: '🏪', color: 'FFD93D'),
      const CategoryModel(id: '23', name: 'Спорт',                 icon: '⚽', color: 'FF6B9D'),
      const CategoryModel(id: '24', name: 'Балдар оюнчуктары',     icon: '🧸', color: 'FF6B6B'),
      const CategoryModel(id: '25', name: 'Сулуулук / Косметика',  icon: '💄', color: 'C77DFF'),
      const CategoryModel(id: '26', name: 'Жеке гигиена',          icon: '🧴', color: '4ECDC4'),
      const CategoryModel(id: '27', name: 'Азык-түлүк',            icon: '🛒', color: '52B788'),
      const CategoryModel(id: '28', name: 'Автотовар',             icon: '🚗', color: '4895EF'),
      const CategoryModel(id: '29', name: 'Китептер / Канцтовар',  icon: '📚', color: 'F4A261'),
      const CategoryModel(id: '30', name: 'Оюнчуктар',             icon: '🎮', color: 'E63946'),
    ];
  }
}
