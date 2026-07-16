import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lt'),
  ];

  /// No description provided for @navRebuilds.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds'**
  String get navRebuilds;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring LEGO sets back from a pile of bricks.'**
  String get homeSubtitle;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @addASet.
  ///
  /// In en, this message translates to:
  /// **'Add a set'**
  String get addASet;

  /// No description provided for @couldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get couldntLoad;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sets yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add one to start sorting your pile.'**
  String get homeEmptyMessage;

  /// No description provided for @continueRebuilding.
  ///
  /// In en, this message translates to:
  /// **'Continue rebuilding'**
  String get continueRebuilding;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified ✓'**
  String get verifiedBadge;

  /// No description provided for @completeParts.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{Complete · {count} part} other{Complete · {count} parts}}'**
  String completeParts(int count);

  /// No description provided for @partsProgress.
  ///
  /// In en, this message translates to:
  /// **'{have} / {total} parts · {pct}%'**
  String partsProgress(int have, int total, int pct);

  /// No description provided for @shortProgress.
  ///
  /// In en, this message translates to:
  /// **'{have} / {total} · {pct}%'**
  String shortProgress(int have, int total, int pct);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signedInSyncOn.
  ///
  /// In en, this message translates to:
  /// **'Signed in · sync on'**
  String get signedInSyncOn;

  /// No description provided for @localNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Local-first · not signed in'**
  String get localNotSignedIn;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @syncBodyPremium.
  ///
  /// In en, this message translates to:
  /// **'Your rebuilds sync to your account across devices.'**
  String get syncBodyPremium;

  /// No description provided for @syncBodySignedInFree.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Cloud sync unlocks with Premium.'**
  String get syncBodySignedInFree;

  /// No description provided for @syncBodySignedOut.
  ///
  /// In en, this message translates to:
  /// **'Your rebuilds stay on this device. Sign in to sync across devices.'**
  String get syncBodySignedOut;

  /// No description provided for @turnOnCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Turn on Cloud Sync'**
  String get turnOnCloudSync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncedToast.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedToast;

  /// No description provided for @seePremium.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get seePremium;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @designGallery.
  ///
  /// In en, this message translates to:
  /// **'Design gallery'**
  String get designGallery;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageLithuanian.
  ///
  /// In en, this message translates to:
  /// **'Lietuvių'**
  String get languageLithuanian;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by set number or name…'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search the catalog'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Find a LEGO set by name or number, e.g. “911” or “Millennium Falcon”.'**
  String get searchEmptyMessage;

  /// No description provided for @searchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailedTitle;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatchesTitle;

  /// No description provided for @searchNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or set number.'**
  String get searchNoMatchesMessage;

  /// No description provided for @partsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{no parts} one{{count} part} other{{count} parts}}'**
  String partsCount(int count);

  /// No description provided for @setHeader.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setHeader;

  /// No description provided for @uniqueParts.
  ///
  /// In en, this message translates to:
  /// **'Unique parts'**
  String get uniqueParts;

  /// No description provided for @minifigs.
  ///
  /// In en, this message translates to:
  /// **'Minifigs'**
  String get minifigs;

  /// No description provided for @startSorting.
  ///
  /// In en, this message translates to:
  /// **'Start sorting'**
  String get startSorting;

  /// No description provided for @setCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load set'**
  String get setCouldntLoad;

  /// No description provided for @startSortingHint.
  ///
  /// In en, this message translates to:
  /// **'Adds a local copy you can sort offline. Add the same set again for a second physical copy.'**
  String get startSortingHint;

  /// No description provided for @partsCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load parts'**
  String get partsCouldntLoad;

  /// No description provided for @partsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No parts'**
  String get partsEmptyTitle;

  /// No description provided for @partsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This set has no part list in the catalog.'**
  String get partsEmptyMessage;

  /// No description provided for @uniquePartsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} unique part} other{{count} unique parts}}'**
  String uniquePartsCount(int count);

  /// No description provided for @quantityTimes.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String quantityTimes(int count);

  /// No description provided for @colorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get colorUnknown;

  /// No description provided for @minifigsCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load minifigs'**
  String get minifigsCouldntLoad;

  /// No description provided for @minifigsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No minifigs'**
  String get minifigsEmptyTitle;

  /// No description provided for @minifigsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This set has no minifigs.'**
  String get minifigsEmptyMessage;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'BrickBack Premium'**
  String get paywallTitle;

  /// No description provided for @paywallHeadline.
  ///
  /// In en, this message translates to:
  /// **'Save unlimited projects and sync across devices. The free tier keeps working on this device, forever.'**
  String get paywallHeadline;

  /// No description provided for @benefitSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get benefitSyncTitle;

  /// No description provided for @benefitSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Pick up a rebuild on your phone and finish on your tablet.'**
  String get benefitSyncBody;

  /// No description provided for @benefitUnlimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited projects'**
  String get benefitUnlimitedTitle;

  /// No description provided for @benefitUnlimitedBody.
  ///
  /// In en, this message translates to:
  /// **'Track as many sets as you want at once.'**
  String get benefitUnlimitedBody;

  /// No description provided for @benefitBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Never lose your work'**
  String get benefitBackupTitle;

  /// No description provided for @benefitBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Your counts are backed up to your account.'**
  String get benefitBackupBody;

  /// No description provided for @benefitPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Party mode (soon)'**
  String get benefitPartyTitle;

  /// No description provided for @benefitPartyBody.
  ///
  /// In en, this message translates to:
  /// **'Sort a big set together in real time.'**
  String get benefitPartyBody;

  /// No description provided for @paywallCtaHint.
  ///
  /// In en, this message translates to:
  /// **'Subscription billing arrives soon. Sign in now to reserve sync for your account.'**
  String get paywallCtaHint;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn on Cloud Sync'**
  String get signInHeadline;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your rebuilds across devices and unlock unlimited projects. Your local piles stay on this device either way.'**
  String get signInSubtitle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in link'**
  String get emailSignInLink;

  /// No description provided for @emailSentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a sign-in link.'**
  String get emailSentConfirm;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @signInFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to sync your rebuild data to your BrickBack account. No account is required to use the app.'**
  String get signInFooter;

  /// No description provided for @couldntAddSet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add set: {error}'**
  String couldntAddSet(String error);

  /// No description provided for @countCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get countCouldNotLoad;

  /// No description provided for @countReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get countReview;

  /// No description provided for @countHaveOfPartsTypes.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total} parts · {types} types'**
  String countHaveOfPartsTypes(int have, int total, int types);

  /// No description provided for @countRemainingOnly.
  ///
  /// In en, this message translates to:
  /// **'Remaining only'**
  String get countRemainingOnly;

  /// No description provided for @countStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get countStep;

  /// No description provided for @countNoInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory data'**
  String get countNoInventoryTitle;

  /// No description provided for @countNoInventoryMessage.
  ///
  /// In en, this message translates to:
  /// **'The catalog has no part list for this set yet.'**
  String get countNoInventoryMessage;

  /// No description provided for @countAllSortedTitle.
  ///
  /// In en, this message translates to:
  /// **'All sorted!'**
  String get countAllSortedTitle;

  /// No description provided for @countAllSortedMessage.
  ///
  /// In en, this message translates to:
  /// **'Every part for this set is accounted for.'**
  String get countAllSortedMessage;

  /// No description provided for @countHaveOfNeeded.
  ///
  /// In en, this message translates to:
  /// **'{have}/{needed}'**
  String countHaveOfNeeded(int have, int needed);

  /// No description provided for @countUnknownColor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get countUnknownColor;

  /// No description provided for @countViewSettings.
  ///
  /// In en, this message translates to:
  /// **'View settings'**
  String get countViewSettings;

  /// No description provided for @countGroupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get countGroupBy;

  /// No description provided for @countGroupByColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get countGroupByColor;

  /// No description provided for @countGroupByType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get countGroupByType;

  /// No description provided for @countGroupByStatus.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get countGroupByStatus;

  /// No description provided for @countGroupByNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get countGroupByNone;

  /// No description provided for @countGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All parts'**
  String get countGroupAll;

  /// No description provided for @countCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get countCategoryOther;

  /// No description provided for @countGroupRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get countGroupRemaining;

  /// No description provided for @countGroupComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get countGroupComplete;

  /// No description provided for @countExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get countExtras;

  /// No description provided for @countShowExtras.
  ///
  /// In en, this message translates to:
  /// **'Show extra parts'**
  String get countShowExtras;

  /// No description provided for @countShowExtrasBody.
  ///
  /// In en, this message translates to:
  /// **'Include the spare pieces the set ships with — counted separately, not part of completion.'**
  String get countShowExtrasBody;

  /// No description provided for @countNoExtras.
  ///
  /// In en, this message translates to:
  /// **'This set has no extra parts.'**
  String get countNoExtras;

  /// No description provided for @countStepIncrement.
  ///
  /// In en, this message translates to:
  /// **'+{value}'**
  String countStepIncrement(int value);

  /// No description provided for @countHaveOfNeededSpaced.
  ///
  /// In en, this message translates to:
  /// **'{have} / {needed}'**
  String countHaveOfNeededSpaced(int have, int needed);

  /// No description provided for @countViewOnBrickLink.
  ///
  /// In en, this message translates to:
  /// **'View on BrickLink'**
  String get countViewOnBrickLink;

  /// No description provided for @countAllAccountedFor.
  ///
  /// In en, this message translates to:
  /// **'All accounted for'**
  String get countAllAccountedFor;

  /// No description provided for @countSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code…'**
  String get countSearchHint;

  /// No description provided for @countDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get countDone;

  /// No description provided for @countNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get countNoMatchesTitle;

  /// No description provided for @countNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or part code.'**
  String get countNoMatchesMessage;

  /// No description provided for @reviewCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get reviewCouldntLoad;

  /// No description provided for @reviewNothingMissing.
  ///
  /// In en, this message translates to:
  /// **'Nothing missing'**
  String get reviewNothingMissing;

  /// No description provided for @reviewNothingMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Every part for this set is accounted for.'**
  String get reviewNothingMissingMessage;

  /// No description provided for @reviewPartsFound.
  ///
  /// In en, this message translates to:
  /// **'{found} of {needed} parts found'**
  String reviewPartsFound(int found, int needed);

  /// No description provided for @reviewAllPartsAccountedFor.
  ///
  /// In en, this message translates to:
  /// **'All parts accounted for'**
  String get reviewAllPartsAccountedFor;

  /// No description provided for @reviewTypesStillMissing.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} type still missing} other{{count} types still missing}}'**
  String reviewTypesStillMissing(int count);

  /// No description provided for @reviewMinifigures.
  ///
  /// In en, this message translates to:
  /// **'Minifigures'**
  String get reviewMinifigures;

  /// No description provided for @reviewMissingParts.
  ///
  /// In en, this message translates to:
  /// **'Missing parts'**
  String get reviewMissingParts;

  /// No description provided for @reviewTypeCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} type} other{{count} types}}'**
  String reviewTypeCount(int count);

  /// No description provided for @reviewNotExportableFootnote.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} part has no BrickLink mapping and won\'\'t be in the export.} other{{count} parts have no BrickLink mapping and won\'\'t be in the export.}}'**
  String reviewNotExportableFootnote(int count);

  /// No description provided for @reviewViewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get reviewViewReport;

  /// No description provided for @reviewReverify.
  ///
  /// In en, this message translates to:
  /// **'Re-verify'**
  String get reviewReverify;

  /// No description provided for @reviewMarkAsVerified.
  ///
  /// In en, this message translates to:
  /// **'Mark as verified'**
  String get reviewMarkAsVerified;

  /// No description provided for @reviewUnknownColor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get reviewUnknownColor;

  /// No description provided for @reviewNeedQty.
  ///
  /// In en, this message translates to:
  /// **'need {qty}'**
  String reviewNeedQty(int qty);

  /// No description provided for @reviewMinifigPresent.
  ///
  /// In en, this message translates to:
  /// **'{have} of {needed} present'**
  String reviewMinifigPresent(int have, int needed);

  /// No description provided for @reviewNeededOne.
  ///
  /// In en, this message translates to:
  /// **'Needed ×1'**
  String get reviewNeededOne;

  /// No description provided for @reviewPctAllParts.
  ///
  /// In en, this message translates to:
  /// **'{pct}% — all parts'**
  String reviewPctAllParts(int pct);

  /// No description provided for @reviewPctOfParts.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of parts'**
  String reviewPctOfParts(int pct);

  /// No description provided for @reviewNoMinifigures.
  ///
  /// In en, this message translates to:
  /// **'No minifigures'**
  String get reviewNoMinifigures;

  /// No description provided for @reviewMinifiguresIncluded.
  ///
  /// In en, this message translates to:
  /// **'Minifigures included'**
  String get reviewMinifiguresIncluded;

  /// No description provided for @reviewMinifiguresIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Minifigures incomplete'**
  String get reviewMinifiguresIncomplete;

  /// No description provided for @reviewWhatElseInBox.
  ///
  /// In en, this message translates to:
  /// **'What else is in the box?'**
  String get reviewWhatElseInBox;

  /// No description provided for @reviewBoxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Box included'**
  String get reviewBoxIncluded;

  /// No description provided for @reviewInstructionsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Instructions included'**
  String get reviewInstructionsIncluded;

  /// No description provided for @reviewStickersApplied.
  ///
  /// In en, this message translates to:
  /// **'Stickers applied'**
  String get reviewStickersApplied;

  /// No description provided for @reviewNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get reviewNotesOptional;

  /// No description provided for @reviewNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. one tyre scuffed, otherwise mint'**
  String get reviewNotesHint;

  /// No description provided for @reviewSaveVerification.
  ///
  /// In en, this message translates to:
  /// **'Save verification'**
  String get reviewSaveVerification;

  /// No description provided for @reportCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get reportCouldntLoad;

  /// No description provided for @reportNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get reportNotVerifiedYet;

  /// No description provided for @reportNotVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Finish a review and mark it verified to get a report.'**
  String get reportNotVerifiedMessage;

  /// No description provided for @reportDefaultSetName.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get reportDefaultSetName;

  /// No description provided for @reportShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get reportShareImage;

  /// No description provided for @reportSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get reportSharePdf;

  /// No description provided for @reportPctComplete.
  ///
  /// In en, this message translates to:
  /// **'{pct}% COMPLETE'**
  String reportPctComplete(int pct);

  /// No description provided for @reportPctPartsMissing.
  ///
  /// In en, this message translates to:
  /// **'{pct}% · {count} parts missing'**
  String reportPctPartsMissing(int pct, int count);

  /// No description provided for @reportNoneInSet.
  ///
  /// In en, this message translates to:
  /// **'None in set'**
  String get reportNoneInSet;

  /// No description provided for @reportInventoryVerification.
  ///
  /// In en, this message translates to:
  /// **'INVENTORY VERIFICATION'**
  String get reportInventoryVerification;

  /// No description provided for @reportPartsFound.
  ///
  /// In en, this message translates to:
  /// **'Parts found'**
  String get reportPartsFound;

  /// No description provided for @reportMinifigures.
  ///
  /// In en, this message translates to:
  /// **'Minifigures'**
  String get reportMinifigures;

  /// No description provided for @reportAllPartsPresent.
  ///
  /// In en, this message translates to:
  /// **'All parts present'**
  String get reportAllPartsPresent;

  /// No description provided for @reportMinifiguresIncluded.
  ///
  /// In en, this message translates to:
  /// **'Minifigures included'**
  String get reportMinifiguresIncluded;

  /// No description provided for @reportBoxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Box included'**
  String get reportBoxIncluded;

  /// No description provided for @reportInstructionsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Instructions included'**
  String get reportInstructionsIncluded;

  /// No description provided for @reportStickersApplied.
  ///
  /// In en, this message translates to:
  /// **'Stickers applied'**
  String get reportStickersApplied;

  /// No description provided for @reportVerifiedDate.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String reportVerifiedDate(String date);

  /// No description provided for @reportVerifiedWithBrickback.
  ///
  /// In en, this message translates to:
  /// **'Verified with BrickBack'**
  String get reportVerifiedWithBrickback;

  /// No description provided for @partyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Party mode'**
  String get partyModeTitle;

  /// No description provided for @partyModeBody.
  ///
  /// In en, this message translates to:
  /// **'Sort a big pile together in real time — join by code.'**
  String get partyModeBody;

  /// No description provided for @partyJoinEntry.
  ///
  /// In en, this message translates to:
  /// **'Join a party'**
  String get partyJoinEntry;

  /// No description provided for @partyJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a party'**
  String get partyJoinTitle;

  /// No description provided for @partyJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code the host shared with you.'**
  String get partyJoinSubtitle;

  /// No description provided for @partyJoinCta.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get partyJoinCta;

  /// No description provided for @partyJoinError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that party. Check the code.'**
  String get partyJoinError;

  /// No description provided for @partyFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Sort party'**
  String get partyFallbackName;

  /// No description provided for @partyCouldntStart.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start party: {error}'**
  String partyCouldntStart(String error);

  /// No description provided for @partyCouldntLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load party'**
  String get partyCouldntLoad;

  /// No description provided for @partySomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get partySomeone;

  /// No description provided for @partyRoleHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get partyRoleHost;

  /// No description provided for @partyRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get partyRoleMember;

  /// No description provided for @partyCodeCaption.
  ///
  /// In en, this message translates to:
  /// **'Party · code {code}'**
  String partyCodeCaption(String code);

  /// No description provided for @partyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get partyCodeLabel;

  /// No description provided for @partyProgress.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total} parts'**
  String partyProgress(int have, int total);

  /// No description provided for @partyMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} member} other{{count} members}}'**
  String partyMemberCount(int count);

  /// No description provided for @partyAddFound.
  ///
  /// In en, this message translates to:
  /// **'Add found parts'**
  String get partyAddFound;

  /// No description provided for @partyActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get partyActivity;

  /// No description provided for @partyNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No parts added yet.'**
  String get partyNoActivity;

  /// No description provided for @partyActivityLine.
  ///
  /// In en, this message translates to:
  /// **'{who} added {what}'**
  String partyActivityLine(String who, String what);

  /// No description provided for @partyInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get partyInvite;

  /// No description provided for @partyInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite to {name}'**
  String partyInviteTitle(String name);

  /// No description provided for @partyInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the code or share the link to join the sort.'**
  String get partyInviteSubtitle;

  /// No description provided for @partyShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get partyShareInvite;

  /// No description provided for @partyShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my BrickBack sort party — code {code}'**
  String partyShareText(String code);

  /// No description provided for @partyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add found parts'**
  String get partyAddTitle;

  /// No description provided for @partyNothingLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to find'**
  String get partyNothingLeftTitle;

  /// No description provided for @partyNothingLeftBody.
  ///
  /// In en, this message translates to:
  /// **'Every part for this set is accounted for.'**
  String get partyNothingLeftBody;

  /// No description provided for @partyRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'{color} · {count} left'**
  String partyRemainingLabel(String color, int count);

  /// No description provided for @partyAddNParts.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{Add {count} part} other{Add {count} parts}}'**
  String partyAddNParts(int count);

  /// No description provided for @partyAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add parts: {error}'**
  String partyAddFailed(String error);

  /// No description provided for @partyEndAction.
  ///
  /// In en, this message translates to:
  /// **'End party'**
  String get partyEndAction;

  /// No description provided for @partyEndConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End this party?'**
  String get partyEndConfirmTitle;

  /// No description provided for @partyEndConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Members won\'t be able to add parts anymore.'**
  String get partyEndConfirmBody;

  /// No description provided for @partyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get partyCancel;

  /// No description provided for @partyEndedToast.
  ///
  /// In en, this message translates to:
  /// **'Party ended'**
  String get partyEndedToast;

  /// No description provided for @partyStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get partyStatusEnded;

  /// No description provided for @partyStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get partyStatusPaused;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lt':
      return AppLocalizationsLt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
