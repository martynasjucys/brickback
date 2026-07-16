// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get navRebuilds => 'Surinkimai';

  @override
  String get navProfile => 'Profilis';

  @override
  String get homeTitle => 'Surinkimai';

  @override
  String get homeSubtitle => 'Sugrąžinkite LEGO rinkinius iš dalių krūvos.';

  @override
  String get addSet => 'Pridėti rinkinį';

  @override
  String get addASet => 'Pridėti rinkinį';

  @override
  String get couldntLoad => 'Nepavyko įkelti';

  @override
  String get homeEmptyTitle => 'Kol kas nėra rinkinių';

  @override
  String get homeEmptyMessage =>
      'Pridėkite rinkinį ir pradėkite rūšiuoti krūvą.';

  @override
  String get continueRebuilding => 'Tęsti surinkimą';

  @override
  String get remove => 'Šalinti';

  @override
  String get verifiedBadge => 'Patvirtinta ✓';

  @override
  String completeParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baigta · $count dalių',
      few: 'Baigta · $count dalys',
      one: 'Baigta · $count dalis',
    );
    return '$_temp0';
  }

  @override
  String partsProgress(int have, int total, int pct) {
    return '$have / $total dalys · $pct%';
  }

  @override
  String shortProgress(int have, int total, int pct) {
    return '$have / $total · $pct%';
  }

  @override
  String get profileTitle => 'Profilis';

  @override
  String get guest => 'Svečias';

  @override
  String get signedIn => 'Prisijungta';

  @override
  String get signedInSyncOn => 'Prisijungta · sinchronizacija įjungta';

  @override
  String get localNotSignedIn => 'Vietinis režimas · neprisijungta';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Nemokama';

  @override
  String get cloudSync => 'Sinchronizavimas debesyje';

  @override
  String get syncBodyPremium =>
      'Jūsų surinkimai sinchronizuojami su paskyra visuose įrenginiuose.';

  @override
  String get syncBodySignedInFree =>
      'Prisijungta. Sinchronizavimas debesyje atrakinamas su Premium.';

  @override
  String get syncBodySignedOut =>
      'Jūsų surinkimai lieka šiame įrenginyje. Prisijunkite, kad sinchronizuotumėte tarp įrenginių.';

  @override
  String get turnOnCloudSync => 'Įjungti sinchronizavimą debesyje';

  @override
  String get syncNow => 'Sinchronizuoti dabar';

  @override
  String get syncedToast => 'Sinchronizuota';

  @override
  String get seePremium => 'Peržiūrėti Premium';

  @override
  String get signOut => 'Atsijungti';

  @override
  String get designGallery => 'Dizaino galerija';

  @override
  String get language => 'Kalba';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageLithuanian => 'Lietuvių';

  @override
  String get searchHint => 'Ieškokite pagal rinkinio numerį ar pavadinimą…';

  @override
  String get searchEmptyTitle => 'Ieškokite kataloge';

  @override
  String get searchEmptyMessage =>
      'Raskite LEGO rinkinį pagal pavadinimą ar numerį, pvz., „911“ arba „Millennium Falcon“.';

  @override
  String get searchFailedTitle => 'Paieška nepavyko';

  @override
  String get noMatchesTitle => 'Nėra atitikmenų';

  @override
  String get searchNoMatchesMessage =>
      'Pabandykite kitą pavadinimą ar rinkinio numerį.';

  @override
  String partsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dalių',
      few: '$count dalys',
      one: '$count dalis',
      zero: 'nėra dalių',
    );
    return '$_temp0';
  }

  @override
  String get setHeader => 'Rinkinys';

  @override
  String get uniqueParts => 'Unikalios dalys';

  @override
  String get minifigs => 'Minifigūrėlės';

  @override
  String get startSorting => 'Pradėti rūšiuoti';

  @override
  String get setCouldntLoad => 'Nepavyko įkelti rinkinio';

  @override
  String get startSortingHint =>
      'Prideda vietinę kopiją, kurią galite rūšiuoti neprisijungę. Pridėkite tą patį rinkinį dar kartą antrai fizinei kopijai.';

  @override
  String get partsCouldntLoad => 'Nepavyko įkelti dalių';

  @override
  String get partsEmptyTitle => 'Nėra dalių';

  @override
  String get partsEmptyMessage => 'Šis rinkinys kataloge neturi dalių sąrašo.';

  @override
  String uniquePartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unikalių dalių',
      few: '$count unikalios dalys',
      one: '$count unikali dalis',
    );
    return '$_temp0';
  }

  @override
  String quantityTimes(int count) {
    return '×$count';
  }

  @override
  String get colorUnknown => 'Nežinoma';

  @override
  String get minifigsCouldntLoad => 'Nepavyko įkelti minifigūrėlių';

  @override
  String get minifigsEmptyTitle => 'Nėra minifigūrėlių';

  @override
  String get minifigsEmptyMessage => 'Šis rinkinys neturi minifigūrėlių.';

  @override
  String get paywallTitle => 'BrickBack Premium';

  @override
  String get paywallHeadline =>
      'Išsaugokite neribotą projektų skaičių ir sinchronizuokite tarp įrenginių. Nemokama versija visada veiks šiame įrenginyje.';

  @override
  String get benefitSyncTitle => 'Sinchronizavimas tarp įrenginių';

  @override
  String get benefitSyncBody =>
      'Pradėkite surinkimą telefone ir užbaikite planšetėje.';

  @override
  String get benefitUnlimitedTitle => 'Neriboti projektai';

  @override
  String get benefitUnlimitedBody =>
      'Sekite tiek rinkinių, kiek norite, vienu metu.';

  @override
  String get benefitBackupTitle => 'Niekada neprarasite savo darbo';

  @override
  String get benefitBackupBody =>
      'Jūsų suskaičiuoti kiekiai saugomi paskyroje.';

  @override
  String get benefitPartyTitle => 'Bendras režimas (netrukus)';

  @override
  String get benefitPartyBody =>
      'Kartu rūšiuokite didelį rinkinį realiu laiku.';

  @override
  String get paywallCtaHint =>
      'Prenumeratos apmokėjimas netrukus. Prisijunkite dabar, kad rezervuotumėte sinchronizavimą savo paskyrai.';

  @override
  String get signInTitle => 'Prisijungimas';

  @override
  String get signInHeadline => 'Įjungti sinchronizavimą debesyje';

  @override
  String get signInSubtitle =>
      'Prisijunkite, kad sinchronizuotumėte surinkimus tarp įrenginių ir atrakintumėte neribotus projektus. Jūsų vietinės krūvos bet kuriuo atveju lieka šiame įrenginyje.';

  @override
  String get continueWithApple => 'Tęsti su Apple';

  @override
  String get continueWithGoogle => 'Tęsti su Google';

  @override
  String get orDivider => 'arba';

  @override
  String get emailHint => 'vardas@pastas.lt';

  @override
  String get emailSignInLink => 'Atsiųsti prisijungimo nuorodą el. paštu';

  @override
  String get emailSentConfirm =>
      'Patikrinkite el. paštą – išsiuntėme prisijungimo nuorodą.';

  @override
  String get emailInvalid => 'Įveskite galiojantį el. pašto adresą.';

  @override
  String get signInFooter =>
      'Tęsdami sutinkate sinchronizuoti savo surinkimų duomenis su BrickBack paskyra. Paskyra nebūtina norint naudotis programa.';

  @override
  String couldntAddSet(String error) {
    return 'Nepavyko pridėti rinkinio: $error';
  }

  @override
  String get countCouldNotLoad => 'Nepavyko įkelti';

  @override
  String get countReview => 'Peržiūra';

  @override
  String countHaveOfPartsTypes(int have, int total, int types) {
    return '$have iš $total dalių · $types tipų';
  }

  @override
  String get countRemainingOnly => 'Tik likusios';

  @override
  String get countStep => 'Žingsnis';

  @override
  String get countNoInventoryTitle => 'Nėra dalių duomenų';

  @override
  String get countNoInventoryMessage =>
      'Šis rinkinys kataloge dar neturi dalių sąrašo.';

  @override
  String get countAllSortedTitle => 'Viskas surūšiuota!';

  @override
  String get countAllSortedMessage => 'Visos šio rinkinio dalys suskaičiuotos.';

  @override
  String countHaveOfNeeded(int have, int needed) {
    return '$have/$needed';
  }

  @override
  String get countUnknownColor => 'Nežinoma';

  @override
  String get countViewSettings => 'Rodinio nustatymai';

  @override
  String get countGroupBy => 'Grupuoti pagal';

  @override
  String get countGroupByColor => 'Spalvą';

  @override
  String get countGroupByType => 'Tipą';

  @override
  String get countGroupByStatus => 'Būseną';

  @override
  String get countGroupByNone => 'Nieko';

  @override
  String get countGroupAll => 'Visos detalės';

  @override
  String get countCategoryOther => 'Kita';

  @override
  String get countGroupRemaining => 'Liko';

  @override
  String get countGroupComplete => 'Surinkta';

  @override
  String get countExtras => 'Atsarginės';

  @override
  String get countShowExtras => 'Rodyti atsargines detales';

  @override
  String get countShowExtrasBody =>
      'Įtraukti atsargines detales, kurias pridėjo gamintojas — skaičiuojamos atskirai, neįeina į užbaigtumą.';

  @override
  String get countNoExtras => 'Šis rinkinys neturi atsarginių detalių.';

  @override
  String countStepIncrement(int value) {
    return '+$value';
  }

  @override
  String countHaveOfNeededSpaced(int have, int needed) {
    return '$have / $needed';
  }

  @override
  String get countViewOnBrickLink => 'Žiūrėti BrickLink';

  @override
  String get countAllAccountedFor => 'Viskas suskaičiuota';

  @override
  String get countSearchHint => 'Ieškokite pagal pavadinimą ar kodą…';

  @override
  String get countDone => 'Atlikta';

  @override
  String get countNoMatchesTitle => 'Nėra atitikmenų';

  @override
  String get countNoMatchesMessage =>
      'Pabandykite kitą pavadinimą ar dalies kodą.';

  @override
  String get reviewCouldntLoad => 'Nepavyko įkelti';

  @override
  String get reviewNothingMissing => 'Nieko netrūksta';

  @override
  String get reviewNothingMissingMessage =>
      'Visos šio rinkinio dalys suskaičiuotos.';

  @override
  String reviewPartsFound(int found, int needed) {
    return 'Rasta $found iš $needed dalių';
  }

  @override
  String get reviewAllPartsAccountedFor => 'Visos dalys suskaičiuotos';

  @override
  String reviewTypesStillMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dar trūksta $count tipų',
      few: 'dar trūksta $count tipų',
      one: 'dar trūksta $count tipo',
    );
    return '$_temp0';
  }

  @override
  String get reviewMinifigures => 'Minifigūrėlės';

  @override
  String get reviewMissingParts => 'Trūkstamos dalys';

  @override
  String reviewTypeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tipų',
      few: '$count tipai',
      one: '$count tipas',
    );
    return '$_temp0';
  }

  @override
  String reviewNotExportableFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dalių neturi BrickLink atitikmens ir nebus eksportuota.',
      few: '$count dalys neturi BrickLink atitikmens ir nebus eksportuotos.',
      one: '$count dalis neturi BrickLink atitikmens ir nebus eksportuota.',
    );
    return '$_temp0';
  }

  @override
  String get reviewViewReport => 'Peržiūrėti ataskaitą';

  @override
  String get reviewReverify => 'Tikrinti iš naujo';

  @override
  String get reviewMarkAsVerified => 'Pažymėti kaip patvirtintą';

  @override
  String get reviewUnknownColor => 'Nežinoma';

  @override
  String reviewNeedQty(int qty) {
    return 'reikia $qty';
  }

  @override
  String reviewMinifigPresent(int have, int needed) {
    return '$have iš $needed yra';
  }

  @override
  String get reviewNeededOne => 'Reikia ×1';

  @override
  String reviewPctAllParts(int pct) {
    return '$pct% — visos dalys';
  }

  @override
  String reviewPctOfParts(int pct) {
    return '$pct% dalių';
  }

  @override
  String get reviewNoMinifigures => 'Nėra minifigūrėlių';

  @override
  String get reviewMinifiguresIncluded => 'Minifigūrėlės įtrauktos';

  @override
  String get reviewMinifiguresIncomplete => 'Trūksta minifigūrėlių';

  @override
  String get reviewWhatElseInBox => 'Kas dar yra dėžutėje?';

  @override
  String get reviewBoxIncluded => 'Dėžutė įtraukta';

  @override
  String get reviewInstructionsIncluded => 'Instrukcijos įtrauktos';

  @override
  String get reviewStickersApplied => 'Lipdukai užklijuoti';

  @override
  String get reviewNotesOptional => 'Pastabos (nebūtina)';

  @override
  String get reviewNotesHint =>
      'pvz., viena padanga subraižyta, kitaip nepriekaištinga';

  @override
  String get reviewSaveVerification => 'Išsaugoti patvirtinimą';

  @override
  String get reportCouldntLoad => 'Nepavyko įkelti';

  @override
  String get reportNotVerifiedYet => 'Dar nepatvirtinta';

  @override
  String get reportNotVerifiedMessage =>
      'Užbaikite peržiūrą ir pažymėkite kaip patvirtintą, kad gautumėte ataskaitą.';

  @override
  String get reportDefaultSetName => 'Rinkinys';

  @override
  String get reportShareImage => 'Bendrinti paveikslėlį';

  @override
  String get reportSharePdf => 'Bendrinti PDF';

  @override
  String reportPctComplete(int pct) {
    return '$pct% UŽBAIGTA';
  }

  @override
  String reportPctPartsMissing(int pct, int count) {
    return '$pct% · trūksta $count dalių';
  }

  @override
  String get reportNoneInSet => 'Rinkinyje nėra';

  @override
  String get reportInventoryVerification => 'INVENTORIAUS PATVIRTINIMAS';

  @override
  String get reportPartsFound => 'Rasta dalių';

  @override
  String get reportMinifigures => 'Minifigūrėlės';

  @override
  String get reportAllPartsPresent => 'Visos dalys yra';

  @override
  String get reportMinifiguresIncluded => 'Minifigūrėlės įtrauktos';

  @override
  String get reportBoxIncluded => 'Dėžutė įtraukta';

  @override
  String get reportInstructionsIncluded => 'Instrukcijos įtrauktos';

  @override
  String get reportStickersApplied => 'Lipdukai užklijuoti';

  @override
  String reportVerifiedDate(String date) {
    return 'Patvirtinta $date';
  }

  @override
  String get reportVerifiedWithBrickback => 'Patvirtinta su BrickBack';

  @override
  String get partyModeTitle => 'Bendras režimas';

  @override
  String get partyModeBody =>
      'Rūšiuokite didelę krūvą kartu realiu laiku — prisijunkite su kodu.';

  @override
  String get partyJoinEntry => 'Prisijungti';

  @override
  String get partyJoinTitle => 'Prisijungti prie sesijos';

  @override
  String get partyJoinSubtitle =>
      'Įveskite kodą, kurį pasidalino organizatorius.';

  @override
  String get partyJoinCta => 'Prisijungti';

  @override
  String get partyJoinError => 'Tokia sesija nerasta. Patikrinkite kodą.';

  @override
  String get partyFallbackName => 'Bendras rūšiavimas';

  @override
  String partyCouldntStart(String error) {
    return 'Nepavyko pradėti sesijos: $error';
  }

  @override
  String get partyCouldntLoad => 'Nepavyko įkelti sesijos';

  @override
  String get partySomeone => 'Kažkas';

  @override
  String get partyRoleHost => 'Organizatorius';

  @override
  String get partyRoleMember => 'Narys';

  @override
  String partyCodeCaption(String code) {
    return 'Sesija · kodas $code';
  }

  @override
  String get partyCodeLabel => 'Prisijungimo kodas';

  @override
  String partyProgress(int have, int total) {
    return '$have iš $total detalių';
  }

  @override
  String partyMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count narių',
      few: '$count nariai',
      one: '$count narys',
    );
    return '$_temp0';
  }

  @override
  String get partyAddFound => 'Pridėti rastas detales';

  @override
  String get partyActivity => 'Veikla';

  @override
  String get partyNoActivity => 'Kol kas detalių nepridėta.';

  @override
  String partyActivityLine(String who, String what) {
    return '$who pridėjo $what';
  }

  @override
  String get partyInvite => 'Pakviesti';

  @override
  String partyInviteTitle(String name) {
    return 'Pakvieskite į „$name“';
  }

  @override
  String get partyInviteSubtitle =>
      'Nuskenuokite kodą arba pasidalinkite nuoroda, kad prisijungtų.';

  @override
  String get partyShareInvite => 'Dalintis kvietimu';

  @override
  String partyShareText(String code) {
    return 'Prisijunk prie mano BrickBack rūšiavimo sesijos — kodas $code';
  }

  @override
  String get partyAddTitle => 'Pridėti rastas detales';

  @override
  String get partyNothingLeftTitle => 'Nieko nebeliko ieškoti';

  @override
  String get partyNothingLeftBody => 'Visos šio rinkinio detalės surinktos.';

  @override
  String partyRemainingLabel(String color, int count) {
    return '$color · liko $count';
  }

  @override
  String partyAddNParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pridėti $count detalių',
      few: 'Pridėti $count detales',
      one: 'Pridėti $count detalę',
    );
    return '$_temp0';
  }

  @override
  String partyAddFailed(String error) {
    return 'Nepavyko pridėti detalių: $error';
  }

  @override
  String get partyEndAction => 'Užbaigti sesiją';

  @override
  String get partyEndConfirmTitle => 'Užbaigti šią sesiją?';

  @override
  String get partyEndConfirmBody => 'Nariai nebegalės pridėti detalių.';

  @override
  String get partyCancel => 'Atšaukti';

  @override
  String get partyEndedToast => 'Sesija užbaigta';

  @override
  String get partyStatusEnded => 'Užbaigta';

  @override
  String get partyStatusPaused => 'Pristabdyta';
}
