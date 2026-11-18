import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App name in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Libre BM6'**
  String get appTitle;

  /// Button that accepts the Terms of Service on first launch.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Button that repeats a Bluetooth check after a failure.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Read aloud for the pull-to-refresh indicator.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// Shown in place of a reading that has not arrived yet.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get noValue;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Battery Monitors'**
  String get devicesTitle;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved battery monitors yet. Tap Add to find one.'**
  String get devicesEmpty;

  /// Button that opens the scanner.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addDevice;

  /// No description provided for @addDeviceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find and save a battery monitor'**
  String get addDeviceTooltip;

  /// No description provided for @deviceActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actions for {alias}'**
  String deviceActionsTooltip(String alias);

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Battery Monitor'**
  String get renameTitle;

  /// No description provided for @aliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aliasLabel;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Battery Monitor?'**
  String get deleteTitle;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'{alias} will be removed from this phone.'**
  String deleteMessage(String alias);

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a Battery Monitor'**
  String get scannerTitle;

  /// No description provided for @scannerChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking Bluetooth…'**
  String get scannerChecking;

  /// No description provided for @scannerSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for battery monitors. Please keep the battery monitor nearby.'**
  String get scannerSearching;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a battery monitor to save it.'**
  String get scannerHint;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Please turn it on.'**
  String get bluetoothOff;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'The app needs permission to find nearby devices. Please allow it in the system settings.'**
  String get permissionDenied;

  /// No description provided for @saveAsTitle.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAsTitle;

  /// Suggested name for a new battery monitor. The suffix is the last four characters of its address.
  ///
  /// In en, this message translates to:
  /// **'Battery monitor {suffix}'**
  String defaultAlias(String suffix);

  /// No description provided for @voltageLabel.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get voltageLabel;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @stateOfChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'State of charge'**
  String get stateOfChargeLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @voltageValue.
  ///
  /// In en, this message translates to:
  /// **'{volts} V'**
  String voltageValue(double volts);

  /// No description provided for @temperatureValue.
  ///
  /// In en, this message translates to:
  /// **'{celsius} °C / {fahrenheit} °F'**
  String temperatureValue(int celsius, int fahrenheit);

  /// No description provided for @stateOfChargeValue.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String stateOfChargeValue(int percent);

  /// No description provided for @statusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get statusNormal;

  /// No description provided for @statusLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statusLow;

  /// No description provided for @statusCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get statusCharging;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Voltage over the last few minutes, from {low} to {high}'**
  String chartSemantics(String low, String high);

  /// No description provided for @linkConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get linkConnecting;

  /// No description provided for @linkLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get linkLive;

  /// No description provided for @linkReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get linkReconnecting;

  /// No description provided for @errorDisconnected.
  ///
  /// In en, this message translates to:
  /// **'The battery monitor disconnected.'**
  String get errorDisconnected;

  /// No description provided for @errorStalled.
  ///
  /// In en, this message translates to:
  /// **'No reading for 10 seconds.'**
  String get errorStalled;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The battery monitor was not found. Is it in range?'**
  String get errorNotFound;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the battery monitor.'**
  String get errorConnection;

  /// No description provided for @errorBadReading.
  ///
  /// In en, this message translates to:
  /// **'The battery monitor sent a reading that could not be read.'**
  String get errorBadReading;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with Bluetooth.'**
  String get errorUnknown;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About Libre BM6'**
  String get drawerAbout;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Libre BM6 is a free, open-source reader for a Bluetooth car-battery monitor. It has no account, no ads, and no tracking. It is an independent project and is not affiliated with the battery monitor\'s manufacturer.'**
  String get aboutDescription;

  /// No description provided for @licensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open-Source Licenses'**
  String get licensesTitle;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Need help or found a problem? Please tell us on the project\'s GitHub page. Your browser opens with a draft that you can edit before you submit it.'**
  String get helpIntro;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'How can we help?\n\n\n{details}'**
  String supportBody(String details);

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @bugBody.
  ///
  /// In en, this message translates to:
  /// **'What happened:\n\nWhat you expected:\n\nSteps to reproduce:\n\n\n{details}'**
  String bugBody(String details);

  /// Details line at the end of a bug report. The OS part is not translated, for example Android 17 (API 37) or iOS 18.1.
  ///
  /// In en, this message translates to:
  /// **'App {version} ({build}) / {os}'**
  String bugDetails(String version, String build, String os);

  /// No description provided for @noBrowser.
  ///
  /// In en, this message translates to:
  /// **'Nothing could open the link. Please visit {url}.'**
  String noBrowser(String url);

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @termsSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'The Short Version'**
  String get termsSummaryHeading;

  /// No description provided for @termsSummary.
  ///
  /// In en, this message translates to:
  /// **'This app is free software. It comes with no warranty, and nobody who made it is liable for what happens when you use it. Please do not rely on it for safety, and never use it while driving.'**
  String get termsSummary;

  /// No description provided for @termsLicenseHeading.
  ///
  /// In en, this message translates to:
  /// **'Free Software'**
  String get termsLicenseHeading;

  /// No description provided for @termsLicense.
  ///
  /// In en, this message translates to:
  /// **'Libre BM6 is free and open-source software. Its source code is available under the Mozilla Public License, version 2.0 (\"MPL 2.0\"). By using the app, you agree to these terms. If you do not agree, please do not use the app.'**
  String get termsLicense;

  /// No description provided for @termsWarrantyHeading.
  ///
  /// In en, this message translates to:
  /// **'No Warranty'**
  String get termsWarrantyHeading;

  /// No description provided for @termsWarranty.
  ///
  /// In en, this message translates to:
  /// **'As section 6 of the MPL 2.0 says, the app is provided \"as is\", without any warranty, whether express, implied, or statutory. There is no promise that it is free of defects, fit for any particular purpose, or non-infringing. You take on the entire risk as to its quality and performance. If it turns out to be defective, you, and not any contributor, bear the cost of any servicing, repair, or correction.'**
  String get termsWarranty;

  /// No description provided for @termsLiabilityHeading.
  ///
  /// In en, this message translates to:
  /// **'No Liability'**
  String get termsLiabilityHeading;

  /// No description provided for @termsLiability.
  ///
  /// In en, this message translates to:
  /// **'As section 7 of the MPL 2.0 says, no contributor or distributor of the app is liable to you for any damages of any kind, under any legal theory, whether tort (including negligence), contract, or otherwise. This covers direct, indirect, special, incidental, and consequential damages, including lost profits, lost goodwill, work stoppage, and computer failure or malfunction. It does not limit liability for death or personal injury caused by a party\'s negligence where the law does not allow such a limit. Some jurisdictions do not allow incidental or consequential damages to be excluded or limited, so this part may not apply to you.'**
  String get termsLiability;

  /// No description provided for @termsIndependentHeading.
  ///
  /// In en, this message translates to:
  /// **'Independent Project'**
  String get termsIndependentHeading;

  /// No description provided for @termsIndependent.
  ///
  /// In en, this message translates to:
  /// **'Libre BM6 is an independent project. It is not affiliated with, endorsed by, or supported by the manufacturer of any battery monitor.'**
  String get termsIndependent;

  /// No description provided for @termsAccuracyHeading.
  ///
  /// In en, this message translates to:
  /// **'Readings May Be Wrong'**
  String get termsAccuracyHeading;

  /// No description provided for @termsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Readings are for information only and may be inaccurate. On one tested battery monitor, the voltage read ~0.1 V lower than a multimeter.'**
  String get termsAccuracy;

  /// No description provided for @termsSafetyHeading.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get termsSafetyHeading;

  /// No description provided for @termsSafety.
  ///
  /// In en, this message translates to:
  /// **'Do not rely on this app for any safety decision. Do not use it while driving. Please check your battery and vehicle with proper tools or a qualified professional.'**
  String get termsSafety;

  /// No description provided for @termsFullLicenseHeading.
  ///
  /// In en, this message translates to:
  /// **'The Full License'**
  String get termsFullLicenseHeading;

  /// No description provided for @termsFullLicense.
  ///
  /// In en, this message translates to:
  /// **'The complete text of the MPL 2.0 is available at https://mozilla.org/MPL/2.0/. It governs the software itself.'**
  String get termsFullLicense;

  /// No description provided for @termsChangesHeading.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get termsChangesHeading;

  /// No description provided for @termsChanges.
  ///
  /// In en, this message translates to:
  /// **'These terms may change in a future version of the app. The terms shown in the version you use are the ones that apply.'**
  String get termsChanges;

  /// No description provided for @termsContactHeading.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get termsContactHeading;

  /// No description provided for @termsContact.
  ///
  /// In en, this message translates to:
  /// **'Please ask questions about these terms on the project\'s issues page at {url}.'**
  String termsContact(String url);

  /// No description provided for @privacySummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'The Short Version'**
  String get privacySummaryHeading;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'We treat you and your data the way we want to be treated. There is no account, no ads, and no tracking. Nothing leaves your phone unless you choose to report a bug or ask for support.'**
  String get privacySummary;

  /// No description provided for @privacyStoredHeading.
  ///
  /// In en, this message translates to:
  /// **'What the App Stores'**
  String get privacyStoredHeading;

  /// No description provided for @privacyStored.
  ///
  /// In en, this message translates to:
  /// **'The app stores only the battery monitors you save: each one\'s Bluetooth identifier and the name you give it. It also remembers that you accepted the Terms of Service. This stays in the app\'s private storage on your phone. Where the system allows it, the app excludes this from backups. Otherwise, your phone\'s own backup may include it. Deleting a battery monitor removes it. Uninstalling the app removes everything from your phone.'**
  String get privacyStored;

  /// No description provided for @privacyNotDoneHeading.
  ///
  /// In en, this message translates to:
  /// **'What the App Does Not Do'**
  String get privacyNotDoneHeading;

  /// No description provided for @privacyNotDone.
  ///
  /// In en, this message translates to:
  /// **'There is no account, sign-in, advertising, analytics, or crash reporting. The app makes no network connections, so it sends nothing off your phone. It does not access your location.'**
  String get privacyNotDone;

  /// No description provided for @privacyBluetoothHeading.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Permissions'**
  String get privacyBluetoothHeading;

  /// No description provided for @privacyBluetooth.
  ///
  /// In en, this message translates to:
  /// **'The app asks for permission to find and connect to nearby Bluetooth devices. It uses that permission only to find your battery monitor and read it. It never uses Bluetooth to work out your location.'**
  String get privacyBluetooth;

  /// No description provided for @privacyBugReportHeading.
  ///
  /// In en, this message translates to:
  /// **'Bug Reports and Support'**
  String get privacyBugReportHeading;

  /// No description provided for @privacyBugReport.
  ///
  /// In en, this message translates to:
  /// **'If you tap Report a bug or Contact support, the app opens the project\'s GitHub page in your browser with a draft. This happens only when you tap one of them. The draft contains only the app version and build number and your phone\'s operating system version, and you can edit or remove them before you submit. GitHub\'s own terms and privacy policy apply there. The app itself still makes no network connections.'**
  String get privacyBugReport;

  /// No description provided for @privacySourceHeading.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get privacySourceHeading;

  /// No description provided for @privacySource.
  ///
  /// In en, this message translates to:
  /// **'The app is free software under the Mozilla Public License 2.0, available at https://mozilla.org/MPL/2.0/. Anyone can read its source code to check these statements.'**
  String get privacySource;

  /// No description provided for @privacyChangesHeading.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get privacyChangesHeading;

  /// No description provided for @privacyChanges.
  ///
  /// In en, this message translates to:
  /// **'This policy may change in a future version of the app. The policy shown in the version you use is the one that applies.'**
  String get privacyChanges;

  /// No description provided for @privacyContactHeading.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactHeading;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'Please ask questions about this policy on the project\'s issues page at {url}.'**
  String privacyContact(String url);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
