// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Libre BM6';

  @override
  String get accept => 'Accept';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get retry => 'Try again';

  @override
  String get noValue => '–';

  @override
  String get devicesTitle => 'Saved monitors';

  @override
  String get devicesEmpty => 'No saved monitors yet. Tap Add to find one.';

  @override
  String get addDevice => 'Add';

  @override
  String get addDeviceTooltip => 'Find and save a monitor';

  @override
  String deviceActionsTooltip(String alias) {
    return 'Actions for $alias';
  }

  @override
  String get renameTitle => 'Rename monitor';

  @override
  String get aliasLabel => 'Name';

  @override
  String get deleteTitle => 'Delete monitor?';

  @override
  String deleteMessage(String alias) {
    return '$alias will be removed from this phone.';
  }

  @override
  String get scannerTitle => 'Find a monitor';

  @override
  String get scannerChecking => 'Checking Bluetooth…';

  @override
  String get scannerSearching =>
      'Looking for monitors. Please keep the monitor nearby.';

  @override
  String get scannerHint => 'Tap a monitor to save it.';

  @override
  String get bluetoothOff => 'Bluetooth is off. Please turn it on.';

  @override
  String get permissionDenied =>
      'The app needs permission to find nearby devices. Please allow it in the system settings.';

  @override
  String get saveAsTitle => 'Save as';

  @override
  String defaultAlias(String suffix) {
    return 'Monitor $suffix';
  }

  @override
  String get voltageLabel => 'Voltage';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get stateOfChargeLabel => 'State of charge';

  @override
  String get statusLabel => 'Status';

  @override
  String voltageValue(double volts) {
    final intl.NumberFormat voltsNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String voltsString = voltsNumberFormat.format(volts);

    return '$voltsString V';
  }

  @override
  String temperatureValue(int celsius, int fahrenheit) {
    final intl.NumberFormat celsiusNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String celsiusString = celsiusNumberFormat.format(celsius);
    final intl.NumberFormat fahrenheitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String fahrenheitString = fahrenheitNumberFormat.format(fahrenheit);

    return '$celsiusString °C / $fahrenheitString °F';
  }

  @override
  String stateOfChargeValue(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$percentString %';
  }

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusLow => 'Low';

  @override
  String get statusCharging => 'Charging';

  @override
  String chartSemantics(String low, String high) {
    return 'Voltage over the last few minutes, from $low to $high';
  }

  @override
  String get linkConnecting => 'Connecting…';

  @override
  String get linkLive => 'Live';

  @override
  String get linkReconnecting => 'Reconnecting…';

  @override
  String get errorDisconnected => 'The monitor disconnected.';

  @override
  String get errorStalled => 'No reading for 10 seconds.';

  @override
  String get errorNotFound => 'The monitor was not found. Is it in range?';

  @override
  String get errorConnection => 'Could not connect to the monitor.';

  @override
  String get errorBadReading =>
      'The monitor sent a reading that could not be read.';

  @override
  String get errorUnknown => 'Something went wrong with Bluetooth.';

  @override
  String get drawerAbout => 'About Libre BM6';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutDescription =>
      'Libre BM6 is a free, open-source reader for a Bluetooth car-battery monitor. It has no account, no ads, and no tracking. It is an independent project and is not affiliated with the monitor\'s manufacturer.';

  @override
  String get licensesTitle => 'Open-source licenses';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpIntro =>
      'Need help or found a problem? Please tell us on the project\'s GitHub page. Your browser opens with a draft that you can edit before you submit it.';

  @override
  String get contactSupport => 'Contact support';

  @override
  String supportBody(String details) {
    return 'How can we help?\n\n\n$details';
  }

  @override
  String get reportBug => 'Report a bug';

  @override
  String bugBody(String details) {
    return 'What happened:\n\nWhat you expected:\n\nSteps to reproduce:\n\n\n$details';
  }

  @override
  String bugDetails(String version, String build, String release, int sdk) {
    final intl.NumberFormat sdkNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sdkString = sdkNumberFormat.format(sdk);

    return 'App $version ($build) / Android $release (API $sdkString)';
  }

  @override
  String noBrowser(String url) {
    return 'Nothing could open the link. Please visit $url.';
  }

  @override
  String get termsTitle => 'Terms of Service';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get termsSummaryHeading => 'The short version';

  @override
  String get termsSummary =>
      'This app is free software. It comes with no warranty, and nobody who made it is liable for what happens when you use it. Please do not rely on it for safety, and never use it while driving.';

  @override
  String get termsLicenseHeading => 'Free software';

  @override
  String get termsLicense =>
      'Libre BM6 is free and open-source software. Its source code is available under the Mozilla Public License, version 2.0 (\"MPL 2.0\"). By using the app, you agree to these terms. If you do not agree, please do not use the app.';

  @override
  String get termsWarrantyHeading => 'No warranty';

  @override
  String get termsWarranty =>
      'As section 6 of the MPL 2.0 says, the app is provided \"as is\", without any warranty, whether express, implied, or statutory. There is no promise that it is free of defects, fit for any particular purpose, or non-infringing. You take on the entire risk as to its quality and performance. If it turns out to be defective, you, and not any contributor, bear the cost of any servicing, repair, or correction.';

  @override
  String get termsLiabilityHeading => 'No liability';

  @override
  String get termsLiability =>
      'As section 7 of the MPL 2.0 says, no contributor or distributor of the app is liable to you for any damages of any kind, under any legal theory, whether tort (including negligence), contract, or otherwise. This covers direct, indirect, special, incidental, and consequential damages, including lost profits, lost goodwill, work stoppage, and computer failure or malfunction. It does not limit liability for death or personal injury caused by a party\'s negligence where the law does not allow such a limit. Some jurisdictions do not allow incidental or consequential damages to be excluded or limited, so this part may not apply to you.';

  @override
  String get termsIndependentHeading => 'Independent project';

  @override
  String get termsIndependent =>
      'Libre BM6 is an independent project. It is not affiliated with, endorsed by, or supported by the manufacturer of any battery monitor.';

  @override
  String get termsAccuracyHeading => 'Readings may be wrong';

  @override
  String get termsAccuracy =>
      'Readings are for information only and may be inaccurate. On one tested monitor, the voltage read ~0.1 V lower than a multimeter.';

  @override
  String get termsSafetyHeading => 'Safety';

  @override
  String get termsSafety =>
      'Do not rely on this app for any safety decision. Do not use it while driving. Please check your battery and vehicle with proper tools or a qualified professional.';

  @override
  String get termsFullLicenseHeading => 'The full license';

  @override
  String get termsFullLicense =>
      'The complete text of the MPL 2.0 is available at https://mozilla.org/MPL/2.0/. It governs the software itself.';

  @override
  String get termsChangesHeading => 'Changes';

  @override
  String get termsChanges =>
      'These terms may change in a future version of the app. The terms shown in the version you use are the ones that apply.';

  @override
  String get termsContactHeading => 'Contact';

  @override
  String termsContact(String url) {
    return 'Please ask questions about these terms on the project\'s issues page at $url.';
  }

  @override
  String get privacySummaryHeading => 'The short version';

  @override
  String get privacySummary =>
      'We treat you and your data the way we want to be treated. There is no account, no ads, and no tracking. Nothing leaves your phone unless you choose to report a bug or ask for support.';

  @override
  String get privacyStoredHeading => 'What the app stores';

  @override
  String get privacyStored =>
      'The app stores only the monitors you save: each one\'s Bluetooth address and the name you give it. It also remembers that you accepted the Terms of Service. This stays in the app\'s private storage on your phone and is excluded from backups. Deleting a monitor removes it. Uninstalling the app removes everything.';

  @override
  String get privacyNotDoneHeading => 'What the app does not do';

  @override
  String get privacyNotDone =>
      'There is no account, sign-in, advertising, analytics, or crash reporting. The app does not request internet access, so it cannot send anything off your phone. It does not access your location.';

  @override
  String get privacyBluetoothHeading => 'Bluetooth permissions';

  @override
  String get privacyBluetooth =>
      'The app asks for permission to find and connect to nearby Bluetooth devices. It uses that permission only to find your battery monitor and read it. It tells the system that Bluetooth scans are never used to work out your location.';

  @override
  String get privacyBugReportHeading => 'Bug reports and support';

  @override
  String get privacyBugReport =>
      'If you tap Report a bug or Contact support, the app opens the project\'s GitHub page in your browser with a draft. This happens only when you tap one of them. The draft contains only the app version and the Android version, and you can edit or remove them before you submit. GitHub\'s own terms and privacy policy apply there. The app itself still has no network access.';

  @override
  String get privacySourceHeading => 'Source code';

  @override
  String get privacySource =>
      'The app is free software under the Mozilla Public License 2.0, available at https://mozilla.org/MPL/2.0/. Anyone can read its source code to check these statements.';

  @override
  String get privacyChangesHeading => 'Changes';

  @override
  String get privacyChanges =>
      'This policy may change in a future version of the app. The policy shown in the version you use is the one that applies.';

  @override
  String get privacyContactHeading => 'Contact';

  @override
  String privacyContact(String url) {
    return 'Please ask questions about this policy on the project\'s issues page at $url.';
  }
}
