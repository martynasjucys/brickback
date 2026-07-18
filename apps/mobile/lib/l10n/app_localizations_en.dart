// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRebuilds => 'Rebuilds';

  @override
  String get navParty => 'Party';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeTitle => 'Rebuilds';

  @override
  String get homeSubtitle => 'Bring LEGO sets back from a pile of bricks.';

  @override
  String get addSet => 'Add set';

  @override
  String get addASet => 'Add a set';

  @override
  String get couldntLoad => 'Couldn\'t load';

  @override
  String get homeEmptyTitle => 'No rebuilds yet';

  @override
  String get homeEmptyMessage =>
      'Search a set to start counting its parts back into place.';

  @override
  String get continueRebuilding => 'Continue rebuilding';

  @override
  String get continueBuilding => 'Continue building';

  @override
  String get allSets => 'All sets';

  @override
  String partsHaveTotal(int have, int total) {
    return '$have / $total parts';
  }

  @override
  String get homeNoMatchTitle => 'No matching sets';

  @override
  String get homeNoMatchMessage =>
      'None of your added sets match the current filter.';

  @override
  String get filter => 'Filter';

  @override
  String get filterSets => 'Filter sets';

  @override
  String filterSetsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filter sets, $count active',
      one: 'Filter sets, $count active',
    );
    return '$_temp0';
  }

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get clearAll => 'Clear all';

  @override
  String get statusLabel => 'Status';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncomplete => 'Incomplete';

  @override
  String get filterComplete => 'Complete';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeFilterHint => 'Add sets to filter them by LEGO theme.';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get remove => 'Remove';

  @override
  String get verifiedBadge => 'Verified ✓';

  @override
  String completeParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complete · $count parts',
      one: 'Complete · $count part',
    );
    return '$_temp0';
  }

  @override
  String partsProgress(int have, int total, int pct) {
    return '$have / $total parts · $pct%';
  }

  @override
  String shortProgress(int have, int total, int pct) {
    return '$have / $total · $pct%';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get statSetsBuilt => 'Sets built';

  @override
  String get statPartsCollected => 'Parts collected';

  @override
  String get nameLabel => 'Name';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get profileSignInPrompt =>
      'Sign in to unlock premium cloud sync and party mode. Everything else works offline.';

  @override
  String get nameEditorTitle => 'Your name';

  @override
  String get nameEditorSubtitle => 'Shown to others in party mode.';

  @override
  String get nameEditorHint => 'Enter a name';

  @override
  String get shuffleName => 'Shuffle name';

  @override
  String get save => 'Save';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get guest => 'Guest';

  @override
  String get signedIn => 'Signed in';

  @override
  String get signedInSyncOn => 'Signed in · sync on';

  @override
  String get localNotSignedIn => 'Local-first · not signed in';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Free';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get syncBodyPremium =>
      'Your rebuilds sync to your account across devices.';

  @override
  String get syncBodySignedInFree =>
      'Signed in. Cloud sync unlocks with Premium.';

  @override
  String get syncBodySignedOut =>
      'Your rebuilds stay on this device. Sign in to sync across devices.';

  @override
  String get turnOnCloudSync => 'Turn on Cloud Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncedToast => 'Synced';

  @override
  String get seePremium => 'See Premium';

  @override
  String get signOut => 'Sign out';

  @override
  String get designGallery => 'Design gallery';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageLithuanian => 'Lietuvių';

  @override
  String get searchHint => 'Search by set number or name…';

  @override
  String get searchEmptyTitle => 'Search the catalog';

  @override
  String get searchEmptyMessage =>
      'Find a LEGO set by name or number, e.g. “911” or “Millennium Falcon”.';

  @override
  String get searchFailedTitle => 'Search failed';

  @override
  String get noMatchesTitle => 'No matches';

  @override
  String get searchNoMatchesMessage => 'Try a different name or set number.';

  @override
  String partsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '$count part',
      zero: 'no parts',
    );
    return '$_temp0';
  }

  @override
  String get setHeader => 'Set';

  @override
  String get uniqueParts => 'Unique parts';

  @override
  String get minifigs => 'Minifigs';

  @override
  String get startSorting => 'Start sorting';

  @override
  String get setCouldntLoad => 'Couldn\'t load set';

  @override
  String get startSortingHint =>
      'Adds a local copy you can sort offline. Add the same set again for a second physical copy.';

  @override
  String get lifecycleUpcoming => 'Coming soon';

  @override
  String get lifecycleAvailable => 'Available';

  @override
  String get lifecycleRetiringSoon => 'Retiring soon';

  @override
  String get lifecycleRetired => 'Retired';

  @override
  String get availabilityTitle => 'Availability';

  @override
  String get dateReleases => 'Releases';

  @override
  String get dateReleased => 'Released';

  @override
  String get dateRetired => 'Retired';

  @override
  String get dateRetiring => 'Retiring';

  @override
  String get valueTitle => 'Value';

  @override
  String get valueNew => 'New';

  @override
  String get valueUsed => 'Used';

  @override
  String get partsCouldntLoad => 'Couldn\'t load parts';

  @override
  String get partsEmptyTitle => 'No parts';

  @override
  String get partsEmptyMessage => 'This set has no part list in the catalog.';

  @override
  String uniquePartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unique parts',
      one: '$count unique part',
    );
    return '$_temp0';
  }

  @override
  String quantityTimes(int count) {
    return '×$count';
  }

  @override
  String get colorUnknown => 'Unknown';

  @override
  String get minifigsCouldntLoad => 'Couldn\'t load minifigs';

  @override
  String get minifigsEmptyTitle => 'No minifigs';

  @override
  String get minifigsEmptyMessage => 'This set has no minifigs.';

  @override
  String get paywallTitle => 'BrickBack Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get paywallHeadline =>
      'Keep every rebuild in sync and backed up. Everything you\'ve sorted so far comes with you.';

  @override
  String get benefitSyncTitle => 'Cloud sync';

  @override
  String get benefitSyncBody =>
      'Your rebuilds follow you to every device, always up to date.';

  @override
  String get benefitBackupTitle => 'Safe backup';

  @override
  String get benefitBackupBody =>
      'Never lose your progress if you lose your phone.';

  @override
  String get benefitPartyBody =>
      'Sort a big set together with friends in real time.';

  @override
  String get paywallCtaHint =>
      'You\'ll sign in first — your local rebuilds upload automatically.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInHeadline => 'Sync across your devices';

  @override
  String get signInSubtitle =>
      'Sign in to unlock premium cloud sync and party mode. Everything else works offline — you can skip this.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailSignInLink => 'Email me a sign-in link';

  @override
  String get emailSentConfirm => 'Check your email for a sign-in link.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get signInFooter =>
      'We only use your account to sync your rebuilds. No spam.';

  @override
  String couldntAddSet(String error) {
    return 'Couldn\'t add set: $error';
  }

  @override
  String get countCouldNotLoad => 'Couldn\'t load';

  @override
  String get countReview => 'Review';

  @override
  String countHaveOfPartsTypes(int have, int total, int types) {
    return '$have of $total parts · $types types';
  }

  @override
  String get countRemainingOnly => 'Remaining only';

  @override
  String get countRemainingOnlyHint =>
      'Hide the parts you\'ve already counted in full — show only what\'s left to find.';

  @override
  String get menuReview => 'Review & verify';

  @override
  String get menuStartParty => 'Start party';

  @override
  String get menuSearchParts => 'Search parts';

  @override
  String get menuSetDetails => 'Set details';

  @override
  String get menuMore => 'More';

  @override
  String get back => 'Back';

  @override
  String get a11yTileAddHint => 'Adds one';

  @override
  String get a11yDetails => 'Details';

  @override
  String a11yNameColor(String name, String color) {
    return '$name, $color';
  }

  @override
  String a11yCount(int have, int needed) {
    return '$have of $needed';
  }

  @override
  String a11yCountComplete(int have, int needed) {
    return '$have of $needed, complete';
  }

  @override
  String get countStep => 'Step';

  @override
  String get countNoInventoryTitle => 'No inventory data';

  @override
  String get countNoInventoryMessage =>
      'The catalog has no part list for this set yet.';

  @override
  String get countAllSortedTitle => 'All sorted!';

  @override
  String get countAllSortedMessage =>
      'Every part for this set is accounted for.';

  @override
  String countHaveOfNeeded(int have, int needed) {
    return '$have/$needed';
  }

  @override
  String get countUnknownColor => 'Unknown';

  @override
  String get countViewSettings => 'View settings';

  @override
  String get countGroupBy => 'Group by';

  @override
  String get countGroupByColor => 'Color';

  @override
  String get countGroupByType => 'Type';

  @override
  String get countGroupByStatus => 'Progress';

  @override
  String get countGroupByNone => 'None';

  @override
  String get countGroupAll => 'All parts';

  @override
  String get countCategoryOther => 'Other';

  @override
  String get countGroupRemaining => 'Remaining';

  @override
  String get countGroupComplete => 'Complete';

  @override
  String get countExtras => 'Extras';

  @override
  String get countShowExtras => 'Show extra parts';

  @override
  String get countShowExtrasBody =>
      'Include the spare pieces the set ships with — counted separately, not part of completion.';

  @override
  String get countNoExtras => 'This set has no extra parts.';

  @override
  String countStepIncrement(int value) {
    return '+$value';
  }

  @override
  String countHaveOfNeededSpaced(int have, int needed) {
    return '$have / $needed';
  }

  @override
  String get countViewOnBrickLink => 'View on BrickLink';

  @override
  String get countAllAccountedFor => 'All accounted for';

  @override
  String get countSearchHint => 'Search by name or code…';

  @override
  String get countDone => 'Done';

  @override
  String get countNoMatchesTitle => 'No matches';

  @override
  String get countNoMatchesMessage => 'Try a different name or part code.';

  @override
  String get reviewCouldntLoad => 'Couldn\'t load';

  @override
  String get reviewNothingMissing => 'Nothing missing';

  @override
  String get reviewNothingMissingMessage =>
      'Every part for this set is accounted for.';

  @override
  String reviewPartsFound(int found, int needed) {
    return '$found of $needed parts found';
  }

  @override
  String get reviewAllPartsAccountedFor => 'All parts accounted for';

  @override
  String reviewTypesStillMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count types still missing',
      one: '$count type still missing',
    );
    return '$_temp0';
  }

  @override
  String get reviewMinifigures => 'Minifigures';

  @override
  String get reviewMissingParts => 'Missing parts';

  @override
  String reviewTypeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count types',
      one: '$count type',
    );
    return '$_temp0';
  }

  @override
  String reviewNotExportableFootnote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count parts have no BrickLink mapping and won\'\'t be in the export.',
      one:
          '$count part has no BrickLink mapping and won\'\'t be in the export.',
    );
    return '$_temp0';
  }

  @override
  String get reviewViewReport => 'View report';

  @override
  String get reviewReverify => 'Re-verify';

  @override
  String get reviewMarkAsVerified => 'Mark as verified';

  @override
  String get reviewUnknownColor => 'Unknown';

  @override
  String reviewNeedQty(int qty) {
    return 'need $qty';
  }

  @override
  String reviewMinifigPresent(int have, int needed) {
    return '$have of $needed present';
  }

  @override
  String get reviewNeededOne => 'Needed ×1';

  @override
  String reviewPctAllParts(int pct) {
    return '$pct% — all parts';
  }

  @override
  String reviewPctOfParts(int pct) {
    return '$pct% of parts';
  }

  @override
  String get reviewNoMinifigures => 'No minifigures';

  @override
  String get reviewMinifiguresIncluded => 'Minifigures included';

  @override
  String get reviewMinifiguresIncomplete => 'Minifigures incomplete';

  @override
  String get reviewWhatElseInBox => 'What else is in the box?';

  @override
  String get reviewBoxIncluded => 'Box included';

  @override
  String get reviewInstructionsIncluded => 'Instructions included';

  @override
  String get reviewStickersApplied => 'Stickers applied';

  @override
  String get reviewNotesOptional => 'Notes (optional)';

  @override
  String get reviewNotesHint => 'e.g. one tyre scuffed, otherwise mint';

  @override
  String get reviewSaveVerification => 'Save verification';

  @override
  String get reportCouldntLoad => 'Couldn\'t load';

  @override
  String get reportNotVerifiedYet => 'Not verified yet';

  @override
  String get reportNotVerifiedMessage =>
      'Finish a review and mark it verified to get a report.';

  @override
  String get reportDefaultSetName => 'Set';

  @override
  String get reportShareImage => 'Share image';

  @override
  String get reportSharePdf => 'Share PDF';

  @override
  String reportPctComplete(int pct) {
    return '$pct% COMPLETE';
  }

  @override
  String reportPctPartsMissing(int pct, int count) {
    return '$pct% · $count parts missing';
  }

  @override
  String get reportNoneInSet => 'None in set';

  @override
  String get reportInventoryVerification => 'INVENTORY VERIFICATION';

  @override
  String get reportPartsFound => 'Parts found';

  @override
  String get reportMinifigures => 'Minifigures';

  @override
  String get reportAllPartsPresent => 'All parts present';

  @override
  String get reportMinifiguresIncluded => 'Minifigures included';

  @override
  String get reportBoxIncluded => 'Box included';

  @override
  String get reportInstructionsIncluded => 'Instructions included';

  @override
  String get reportStickersApplied => 'Stickers applied';

  @override
  String reportVerifiedDate(String date) {
    return 'Verified $date';
  }

  @override
  String get reportVerifiedWithBrickback => 'Verified with BrickBack';

  @override
  String get partyModeTitle => 'Party mode';

  @override
  String get partyModeBody =>
      'Sort a big pile together in real time — join by code.';

  @override
  String get partyJoinEntry => 'Join a party';

  @override
  String get partyJoinTitle => 'Join a party';

  @override
  String get partyJoinSubtitle => 'Enter the code the host shared with you.';

  @override
  String get partyJoinCta => 'Join';

  @override
  String get partyJoinError => 'Couldn\'t find that party. Check the code.';

  @override
  String get partyJoinOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get partyJoinFailed => 'Couldn\'t join that party. Try again.';

  @override
  String get partyHostNote =>
      'Hosting a party is Premium — start one from a rebuild\'s counting screen.';

  @override
  String partyAppearAs(String name) {
    return 'You\'ll appear as $name';
  }

  @override
  String get partyFallbackName => 'Sort party';

  @override
  String partyCouldntStart(String error) {
    return 'Couldn\'t start party: $error';
  }

  @override
  String get partyCouldntLoad => 'Couldn\'t load party';

  @override
  String get partySomeone => 'Someone';

  @override
  String get partyRoleHost => 'Host';

  @override
  String get partyRoleMember => 'Member';

  @override
  String partyCodeCaption(String code) {
    return 'Party · code $code';
  }

  @override
  String get partyCodeLabel => 'Join code';

  @override
  String partyProgress(int have, int total) {
    return '$have of $total parts';
  }

  @override
  String partyMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get partyAddFound => 'Add found parts';

  @override
  String get partyActivity => 'Activity';

  @override
  String get partyNoActivity => 'No parts added yet.';

  @override
  String partyActivityLine(String who, String what) {
    return '$who added $what';
  }

  @override
  String get partyInvite => 'Invite';

  @override
  String partyInviteTitle(String name) {
    return 'Invite to $name';
  }

  @override
  String get partyInviteSubtitle =>
      'Scan the code or share the link to join the sort.';

  @override
  String get partyShareInvite => 'Share invite';

  @override
  String partyShareText(String code) {
    return 'Join my BrickBack sort party — code $code';
  }

  @override
  String get partyAddTitle => 'Add found parts';

  @override
  String get partyNothingLeftTitle => 'Nothing left to find';

  @override
  String get partyNothingLeftBody =>
      'Every part for this set is accounted for.';

  @override
  String partyRemainingLabel(String color, int count) {
    return '$color · $count left';
  }

  @override
  String partyAddNParts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count parts',
      one: 'Add $count part',
    );
    return '$_temp0';
  }

  @override
  String partyAddFailed(String error) {
    return 'Couldn\'t add parts: $error';
  }

  @override
  String get partyEndAction => 'End party';

  @override
  String get partyEndConfirmTitle => 'End this party?';

  @override
  String get partyEndConfirmBody =>
      'Members won\'t be able to add parts anymore.';

  @override
  String get partyCancel => 'Cancel';

  @override
  String get partyEndedToast => 'Party ended';

  @override
  String get partyStatusEnded => 'Ended';

  @override
  String get partyStatusPaused => 'Paused';
}
