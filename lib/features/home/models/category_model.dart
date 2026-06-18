class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final List<SubCategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.subcategories = const [],
  });

  static List<CategoryModel> getCategories() {
    return [
      const CategoryModel(
        id: '1', name: 'Кийим-кече', icon: '👕', color: 'FF6B6B',
        subcategories: [
          SubCategoryModel(id: '1_1', name: 'Баары', icon: '👕'),
          SubCategoryModel(id: '1_2', name: 'Эркектер', icon: '👔'),
          SubCategoryModel(id: '1_3', name: 'Аялдар', icon: '👗'),
          SubCategoryModel(id: '1_4', name: 'Балдар', icon: '🧒'),
          SubCategoryModel(id: '1_5', name: 'Мектеп формасы', icon: '🏫'),
          SubCategoryModel(id: '1_6', name: 'Кышкы кийим', icon: '🧥'),
          SubCategoryModel(id: '1_7', name: 'Жайкы кийим', icon: '☀️'),
          SubCategoryModel(id: '1_8', name: 'Спорт кийими', icon: '🏋️'),
          SubCategoryModel(id: '1_9', name: 'Жумушчу кийим', icon: '🦺'),
          SubCategoryModel(id: '1_10', name: 'Улуттук кийим', icon: '🪭'),
        ],
      ),
      const CategoryModel(
        id: '2', name: 'Бут кийим', icon: '👟', color: 'C77DFF',
        subcategories: [
          SubCategoryModel(id: '2_1', name: 'Баары', icon: '👟'),
          SubCategoryModel(id: '2_2', name: 'Эркектер', icon: '👞'),
          SubCategoryModel(id: '2_3', name: 'Аялдар', icon: '👠'),
          SubCategoryModel(id: '2_4', name: 'Балдар', icon: '👶'),
          SubCategoryModel(id: '2_5', name: 'Спорт', icon: '⚽'),
          SubCategoryModel(id: '2_6', name: 'Кышкы', icon: '❄️'),
          SubCategoryModel(id: '2_7', name: 'Сандал/Тапочка', icon: '🩴'),
          SubCategoryModel(id: '2_8', name: 'Жумушчу', icon: '🔨'),
        ],
      ),
      const CategoryModel(
        id: '3', name: 'Аксессуарлар', icon: '👜', color: 'FFD93D',
        subcategories: [
          SubCategoryModel(id: '3_1', name: 'Баары', icon: '👜'),
          SubCategoryModel(id: '3_2', name: 'Сумкалар', icon: '🎒'),
          SubCategoryModel(id: '3_3', name: 'Кол саат', icon: '⌚'),
          SubCategoryModel(id: '3_4', name: 'Көз айнек', icon: '🕶️'),
          SubCategoryModel(id: '3_5', name: 'Зергерчилик', icon: '💍'),
          SubCategoryModel(id: '3_6', name: 'Кемер', icon: '👒'),
          SubCategoryModel(id: '3_7', name: 'Жоолук/Шарф', icon: '🧣'),
          SubCategoryModel(id: '3_8', name: 'Перчатка', icon: '🧤'),
          SubCategoryModel(id: '3_9', name: 'Баш кийим', icon: '🧢'),
        ],
      ),
      const CategoryModel(
        id: '4', name: 'Электроника', icon: '📱', color: '4895EF',
        subcategories: [
          SubCategoryModel(id: '4_1', name: 'Баары', icon: '📱'),
          SubCategoryModel(id: '4_2', name: 'Телефондор', icon: '📲'),
          SubCategoryModel(id: '4_3', name: 'Ноутбук', icon: '💻'),
          SubCategoryModel(id: '4_4', name: 'Планшет', icon: '📟'),
          SubCategoryModel(id: '4_5', name: 'Наушник', icon: '🎧'),
          SubCategoryModel(id: '4_6', name: 'Зарядка/Кабель', icon: '🔌'),
          SubCategoryModel(id: '4_7', name: 'Камера', icon: '📷'),
          SubCategoryModel(id: '4_8', name: 'Акылдуу саат', icon: '⌚'),
          SubCategoryModel(id: '4_9', name: 'Оюн консоли', icon: '🎮'),
          SubCategoryModel(id: '4_10', name: 'Принтер', icon: '🖨️'),
        ],
      ),
      const CategoryModel(
        id: '5', name: 'Үй буюмдар', icon: '🏠', color: 'FF922B',
        subcategories: [
          SubCategoryModel(id: '5_1', name: 'Баары', icon: '🏠'),
          SubCategoryModel(id: '5_2', name: 'Мебель', icon: '🛋️'),
          SubCategoryModel(id: '5_3', name: 'Жууркан/Жаздык', icon: '🛏️'),
          SubCategoryModel(id: '5_4', name: 'Идиш-аяк', icon: '🍽️'),
          SubCategoryModel(id: '5_5', name: 'Ашкана буюмдары', icon: '🥘'),
          SubCategoryModel(id: '5_6', name: 'Үй жасалгасы', icon: '🖼️'),
          SubCategoryModel(id: '5_7', name: 'Жарык буюмдары', icon: '💡'),
          SubCategoryModel(id: '5_8', name: 'Килем/Чий', icon: '🪆'),
          SubCategoryModel(id: '5_9', name: 'Штора/Пардэ', icon: '🪟'),
          SubCategoryModel(id: '5_10', name: 'Сантехника', icon: '🚿'),
        ],
      ),
      const CategoryModel(
        id: '6', name: 'Техника', icon: '❄️', color: '52B788',
        subcategories: [
          SubCategoryModel(id: '6_1', name: 'Баары', icon: '❄️'),
          SubCategoryModel(id: '6_2', name: 'Муздаткыч', icon: '🧊'),
          SubCategoryModel(id: '6_3', name: 'Кир жуучу машина', icon: '🫧'),
          SubCategoryModel(id: '6_4', name: 'Телевизор', icon: '📺'),
          SubCategoryModel(id: '6_5', name: 'Кондиционер', icon: '🌬️'),
          SubCategoryModel(id: '6_6', name: 'Газ плита', icon: '🔥'),
          SubCategoryModel(id: '6_7', name: 'Микротолкундуу', icon: '📡'),
          SubCategoryModel(id: '6_8', name: 'Чаң соргуч', icon: '🌀'),
          SubCategoryModel(id: '6_9', name: 'Утюг', icon: '🧺'),
        ],
      ),
      const CategoryModel(
        id: '7', name: 'Спорт', icon: '⚽', color: 'FF6B9D',
        subcategories: [
          SubCategoryModel(id: '7_1', name: 'Баары', icon: '⚽'),
          SubCategoryModel(id: '7_2', name: 'Футбол', icon: '⚽'),
          SubCategoryModel(id: '7_3', name: 'Баскетбол', icon: '🏀'),
          SubCategoryModel(id: '7_4', name: 'Волейбол', icon: '🏐'),
          SubCategoryModel(id: '7_5', name: 'Тренажер', icon: '🏋️'),
          SubCategoryModel(id: '7_6', name: 'Велосипед', icon: '🚴'),
          SubCategoryModel(id: '7_7', name: 'Бокс', icon: '🥊'),
          SubCategoryModel(id: '7_8', name: 'Йога/Фитнес', icon: '🧘'),
          SubCategoryModel(id: '7_9', name: 'Жүзүү', icon: '🏊'),
          SubCategoryModel(id: '7_10', name: 'Жүгүрүү', icon: '🏃'),
        ],
      ),
      const CategoryModel(
        id: '8', name: 'Балдар', icon: '🧸', color: 'FF6B6B',
        subcategories: [
          SubCategoryModel(id: '8_1', name: 'Баары', icon: '🧸'),
          SubCategoryModel(id: '8_2', name: 'Оюнчуктар', icon: '🪀'),
          SubCategoryModel(id: '8_3', name: 'Велосипед', icon: '🚲'),
          SubCategoryModel(id: '8_4', name: 'Коляска', icon: '🛒'),
          SubCategoryModel(id: '8_5', name: 'Балдар мебели', icon: '🪑'),
          SubCategoryModel(id: '8_6', name: 'Мектеп буюмдары', icon: '📐'),
          SubCategoryModel(id: '8_7', name: 'Балдар китептери', icon: '📖'),
          SubCategoryModel(id: '8_8', name: 'Балдар тамагы', icon: '🍼'),
        ],
      ),
      const CategoryModel(
        id: '9', name: 'Сулуулук', icon: '💄', color: 'C77DFF',
        subcategories: [
          SubCategoryModel(id: '9_1', name: 'Баары', icon: '💄'),
          SubCategoryModel(id: '9_2', name: 'Жүз карачу', icon: '🧖'),
          SubCategoryModel(id: '9_3', name: 'Чач карачу', icon: '💇'),
          SubCategoryModel(id: '9_4', name: 'Парфюм', icon: '🌸'),
          SubCategoryModel(id: '9_5', name: 'Макияж', icon: '💋'),
          SubCategoryModel(id: '9_6', name: 'Тырмак', icon: '💅'),
          SubCategoryModel(id: '9_7', name: 'Массаж буюмдары', icon: '💆'),
        ],
      ),
      const CategoryModel(
        id: '10', name: 'Гигиена', icon: '🧴', color: '4ECDC4',
        subcategories: [
          SubCategoryModel(id: '10_1', name: 'Баары', icon: '🧴'),
          SubCategoryModel(id: '10_2', name: 'Шампунь/Гель', icon: '🚿'),
          SubCategoryModel(id: '10_3', name: 'Тиш пасталары', icon: '🦷'),
          SubCategoryModel(id: '10_4', name: 'Сабын', icon: '🧼'),
          SubCategoryModel(id: '10_5', name: 'Дезодорант', icon: '✨'),
          SubCategoryModel(id: '10_6', name: 'Аялдар гигиенасы', icon: '🌺'),
          SubCategoryModel(id: '10_7', name: 'Балдар гигиенасы', icon: '👶'),
        ],
      ),
      const CategoryModel(
        id: '11', name: 'Азык-түлүк', icon: '🛒', color: '52B788',
        subcategories: [
          SubCategoryModel(id: '11_1', name: 'Баары', icon: '🛒'),
          SubCategoryModel(id: '11_2', name: 'Дан азыктары', icon: '🌾'),
          SubCategoryModel(id: '11_3', name: 'Консервалар', icon: '🥫'),
          SubCategoryModel(id: '11_4', name: 'Майлар/Соустар', icon: '🫙'),
          SubCategoryModel(id: '11_5', name: 'Кондитердик', icon: '🍰'),
          SubCategoryModel(id: '11_6', name: 'Суусундуктар', icon: '🥤'),
          SubCategoryModel(id: '11_7', name: 'Чай/Кофе', icon: '☕'),
          SubCategoryModel(id: '11_8', name: 'Наан/Нан', icon: '🍞'),
          SubCategoryModel(id: '11_9', name: 'Жашылчалар', icon: '🥦'),
        ],
      ),
      const CategoryModel(
        id: '12', name: 'Автотовар', icon: '🚗', color: '4895EF',
        subcategories: [
          SubCategoryModel(id: '12_1', name: 'Баары', icon: '🚗'),
          SubCategoryModel(id: '12_2', name: 'Аксессуарлар', icon: '🪝'),
          SubCategoryModel(id: '12_3', name: 'Автохимия', icon: '🧪'),
          SubCategoryModel(id: '12_4', name: 'Дөңгөлөктөр', icon: '🛞'),
          SubCategoryModel(id: '12_5', name: 'Запас бөлүктөр', icon: '⚙️'),
          SubCategoryModel(id: '12_6', name: 'Видеорегистратор', icon: '📹'),
          SubCategoryModel(id: '12_7', name: 'Автоаудио', icon: '🔊'),
          SubCategoryModel(id: '12_8', name: 'Автосветтер', icon: '💡'),
        ],
      ),
      const CategoryModel(
        id: '13', name: 'Китеп/Канцтовар', icon: '📚', color: 'F4A261',
        subcategories: [
          SubCategoryModel(id: '13_1', name: 'Баары', icon: '📚'),
          SubCategoryModel(id: '13_2', name: 'Окуу китептери', icon: '📖'),
          SubCategoryModel(id: '13_3', name: 'Көркөм адабият', icon: '📕'),
          SubCategoryModel(id: '13_4', name: 'Балдар китептери', icon: '📗'),
          SubCategoryModel(id: '13_5', name: 'Дептер/Блокнот', icon: '📓'),
          SubCategoryModel(id: '13_6', name: 'Калем/Маркер', icon: '✏️'),
          SubCategoryModel(id: '13_7', name: 'Рюкзак/Сумка', icon: '🎒'),
        ],
      ),
      const CategoryModel(
        id: '14', name: 'Кездеме/Тигүү', icon: '🧵', color: 'F4A261',
        subcategories: [
          SubCategoryModel(id: '14_1', name: 'Баары', icon: '🧵'),
          SubCategoryModel(id: '14_2', name: 'Кездеме/Мата', icon: '🪢'),
          SubCategoryModel(id: '14_3', name: 'Жип', icon: '🧶'),
          SubCategoryModel(id: '14_4', name: 'Тигүү жабдуулары', icon: '🪡'),
          SubCategoryModel(id: '14_5', name: 'Фурнитура', icon: '🔘'),
          SubCategoryModel(id: '14_6', name: 'Вышивка', icon: '🌼'),
        ],
      ),
      const CategoryModel(
        id: '15', name: 'Куралдар', icon: '🔧', color: '888888',
        subcategories: [
          SubCategoryModel(id: '15_1', name: 'Баары', icon: '🔧'),
          SubCategoryModel(id: '15_2', name: 'Электр куралдары', icon: '⚡'),
          SubCategoryModel(id: '15_3', name: 'Кол куралдары', icon: '🔨'),
          SubCategoryModel(id: '15_4', name: 'Сантехника', icon: '🚰'),
          SubCategoryModel(id: '15_5', name: 'Курулуш материалы', icon: '🧱'),
          SubCategoryModel(id: '15_6', name: 'Краска/Лак', icon: '🎨'),
          SubCategoryModel(id: '15_7', name: 'Нурдаткычтар', icon: '🔦'),
        ],
      ),
      const CategoryModel(
        id: '16', name: 'Оюн/Эглентүү', icon: '🎮', color: 'E63946',
        subcategories: [
          SubCategoryModel(id: '16_1', name: 'Баары', icon: '🎮'),
          SubCategoryModel(id: '16_2', name: 'Видеооюндар', icon: '🕹️'),
          SubCategoryModel(id: '16_3', name: 'Настолка оюндары', icon: '♟️'),
          SubCategoryModel(id: '16_4', name: 'Пазл', icon: '🧩'),
          SubCategoryModel(id: '16_5', name: 'Музыка аспаптары', icon: '🎸'),
          SubCategoryModel(id: '16_6', name: 'Сүрөт тартуу', icon: '🖌️'),
        ],
      ),
      const CategoryModel(
        id: '17', name: 'Багчылык', icon: '🪴', color: '6BCB77',
        subcategories: [
          SubCategoryModel(id: '17_1', name: 'Баары', icon: '🪴'),
          SubCategoryModel(id: '17_2', name: 'Үй өсүмдүктөрү', icon: '🌿'),
          SubCategoryModel(id: '17_3', name: 'Багчылык куралдары', icon: '🌱'),
          SubCategoryModel(id: '17_4', name: 'Топурак/Жер', icon: '🌍'),
          SubCategoryModel(id: '17_5', name: 'Уруктар', icon: '🌻'),
          SubCategoryModel(id: '17_6', name: 'Кашпо/Горшок', icon: '🏺'),
        ],
      ),
      const CategoryModel(
        id: '18', name: 'Жаныбарлар', icon: '🐾', color: 'FF922B',
        subcategories: [
          SubCategoryModel(id: '18_1', name: 'Баары', icon: '🐾'),
          SubCategoryModel(id: '18_2', name: 'Ит буюмдары', icon: '🐕'),
          SubCategoryModel(id: '18_3', name: 'Мышык буюмдары', icon: '🐈'),
          SubCategoryModel(id: '18_4', name: 'Жем/Азык', icon: '🦴'),
          SubCategoryModel(id: '18_5', name: 'Тор/Клетка', icon: '🪹'),
          SubCategoryModel(id: '18_6', name: 'Ветеринардык', icon: '💊'),
        ],
      ),
    ];
  }
}

class SubCategoryModel {
  final String id;
  final String name;
  final String icon;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });
}
