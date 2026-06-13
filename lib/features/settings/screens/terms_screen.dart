import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Эрежелер жана купуялык саясаты" — толук маалымат экраны.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Эрежелер жана купуялык саясаты',
            style: AppTextStyles.headingSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              title: '1. Жалпы шарттар',
              body:
                  'DD Online — Дордой базарындагы сатуучулар менен сатып '
                  'алуучуларды бириктирүүчү онлайн платформа. Колдонмону '
                  'орнотуу жана колдонуу менен сиз ушул бетте көрсөтүлгөн '
                  'эрежелерди жана купуялык саясатын кабыл алгандыгыңызды '
                  'тастыктайсыз.',
            ),
            _section(
              title: '2. Платформанын ролу',
              body:
                  'DD Online товарларды өзү сатпайт. Платформа сатуучулар '
                  'менен сатып алуучуларды байланыштыруу, товарларды '
                  'издеп табуу жана дүкөнгө чейинки маршрутту көрсөтүү '
                  'үчүн кызмат кылат. Товардын баасы, сапаты, бар-жоктугу '
                  'жана сатуу шарттары үчүн жоопкерчиликти ал товарды '
                  'жарыялаган сатуучу өзү тартат.',
            ),
            _section(
              title: '3. Колдонуучунун милдеттери',
              body:
                  'Колдонуучу каттоодо чыныгы маалымат көрсөтүүгө, башка '
                  'колдонуучуларга жана сатуучуларга сылык мамиле '
                  'кылууга мыйзамга жат, алдамчы же зыян келтирүүчү '
                  'мазмун жайгаштырбоого милдеттенет. Бул эрежелер '
                  'бузулган учурда профиль убактылуу же биротоло '
                  'бөгөттөлүшү мүмкүн.',
            ),
            _section(
              title: '4. Сатуучулар үчүн эрежелер',
              body:
                  'Сатуучу жарыялаган товардын сүрөтү, баасы жана '
                  'сүрөттөмөсү чындыкка дал келиши керек. Тыюу салынган, '
                  'контрафакттык же мыйзамсыз товарларды жарыялоого жол '
                  'берилбейт. Администрация шектүү же эрежеге каршы '
                  'жарыяларды алдын ала эскертүүсүз өчүрүү же сатуучунун '
                  'катталуусун токтотуу укугун сактайт.',
            ),
            _section(
              title: '5. Купуялык саясаты',
              body:
                  'Биз сиздин атыңыз, телефон номериңиз, жайгашкан '
                  'жайыңыз (геолокация) жана колдонмо ичиндеги жазышуу '
                  'тарыхы сыяктуу маалыматтарды чогултабыз. Бул маалымат '
                  'төмөнкү максаттарда колдонулат: каттоо жана аутентификация, '
                  'сатуучу менен сатып алуучуну байланыштыруу, дүкөнгө '
                  'маршрут түзүү, колдонмонун иштөө сапатын жакшыртуу жана '
                  'жарнама/билдирүүлөрдү жөнөтүү.',
            ),
            _section(
              title: '6. Маалыматты сактоо жана коргоо',
              body:
                  'Колдонуучунун маалыматы шифрленген серверлерде сакталат '
                  'жана үчүнчү тараптарга сатылбайт. Маалымат сатуучу менен '
                  'сатып алуучунун ортосундагы байланышты ишке ашыруу, '
                  'статистика жана коопсуздук максатында гана колдонулушу '
                  'мүмкүн. Колдонуучу каалаган убакта өз профилин жана '
                  'жекелик маалыматтарын өчүрүүнү сурана алат.',
            ),
            _section(
              title: '7. Геолокация жана картадан колдонуу',
              body:
                  'Колдонмо "Маршрут түзүү" функциясын иштетүү үчүн сиздин '
                  'жайгашкан жериңизге уруксат сурайт. Бул маалымат сиздин '
                  'түзмөгүңүздө гана пайдаланылат жана 2ГИС сыяктуу үчүнчү '
                  'тарап тиркемесине маршрут түзүү үчүн жөнөтүлөт.',
            ),
            _section(
              title: '8. Эрежелердин өзгөрүүсү',
              body:
                  'Администрация бул эрежелерди жана купуялык саясатын '
                  'мезгил-мезгили менен жаңыртып турат. Маанилуу '
                  'өзгөрүүлөр тууралуу колдонуучуларга колдонмо аркылуу '
                  'кабарлоо жасалат.',
            ),
            _section(
              title: '9. Байланыш',
              body:
                  'Суроо-талаптар, даттануулар же сунуштар үчүн биз менен '
                  'төмөнкү байланыш аркылуу кайрылууга болот:',
            ),
            const SizedBox(height: 4),
            _contactRow(Icons.business_outlined, 'DD Online'),
            const SizedBox(height: 8),
            _contactRow(Icons.email_outlined, 'support@ddonline.kg'),
            const SizedBox(height: 8),
            _contactRow(Icons.phone_outlined, '+996 (XXX) XX-XX-XX'),
            const SizedBox(height: 8),
            _contactRow(Icons.location_on_outlined, 'Дордой базары, Бишкек, Кыргызстан'),
            const SizedBox(height: 24),
            Text(
              'Бул документ маалымат берүү максатында түзүлгөн жана '
              'юридикалык консультация эмес.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
