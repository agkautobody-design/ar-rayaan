import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'generated/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ar-Rayaan'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your companion for the journey'**
  String get appTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get loginSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUp;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get signUpNameHint;

  /// No description provided for @signUpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get signUpEmailHint;

  /// No description provided for @signUpPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signUpPasswordHint;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpButton;

  /// No description provided for @signUpHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpHasAccount;

  /// No description provided for @signUpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signUpSignIn;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a link to your email. Tap it to verify your account.'**
  String get verifySubtitle;

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyResend;

  /// No description provided for @verifyContinue.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get verifyContinue;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get resetSubtitle;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetButton;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the reset link.'**
  String get resetSuccess;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaykum'**
  String get homeGreeting;

  /// No description provided for @homeContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get homeContinueReading;

  /// No description provided for @homeDailyHadith.
  ///
  /// In en, this message translates to:
  /// **'Daily Hadith'**
  String get homeDailyHadith;

  /// No description provided for @homePrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get homePrayerTimes;

  /// No description provided for @homeAcademy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get homeAcademy;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerNext.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get prayerNext;

  /// No description provided for @prayerQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get prayerQibla;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @quranLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get quranLastRead;

  /// No description provided for @quranBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get quranBookmark;

  /// No description provided for @quranBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get quranBookmarks;

  /// No description provided for @quranJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get quranJuz;

  /// No description provided for @quranSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get quranSurah;

  /// No description provided for @hadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadithTitle;

  /// No description provided for @hadithForOurTimes.
  ///
  /// In en, this message translates to:
  /// **'Hadiths for Our Times'**
  String get hadithForOurTimes;

  /// No description provided for @hadithBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark hadith'**
  String get hadithBookmark;

  /// No description provided for @hadithNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get hadithNote;

  /// No description provided for @academyTitle.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get academyTitle;

  /// No description provided for @academyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get academyContinue;

  /// No description provided for @academySchools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get academySchools;

  /// No description provided for @academyQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran School'**
  String get academyQuran;

  /// No description provided for @academyArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic Language'**
  String get academyArabic;

  /// No description provided for @academyAqeedah.
  ///
  /// In en, this message translates to:
  /// **'Aqeedah'**
  String get academyAqeedah;

  /// No description provided for @academySeerah.
  ///
  /// In en, this message translates to:
  /// **'Seerah'**
  String get academySeerah;

  /// No description provided for @academyFiqh.
  ///
  /// In en, this message translates to:
  /// **'Fiqh'**
  String get academyFiqh;

  /// No description provided for @academyDawah.
  ///
  /// In en, this message translates to:
  /// **'Dawah'**
  String get academyDawah;

  /// No description provided for @academyHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get academyHealth;

  /// No description provided for @academyFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get academyFamily;

  /// No description provided for @academyYouth.
  ///
  /// In en, this message translates to:
  /// **'Youth'**
  String get academyYouth;

  /// No description provided for @academyWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get academyWomen;

  /// No description provided for @academyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get academyTransactions;

  /// No description provided for @academyEndOfLife.
  ///
  /// In en, this message translates to:
  /// **'End of Life'**
  String get academyEndOfLife;

  /// No description provided for @academyCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get academyCharacter;

  /// No description provided for @academyStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get academyStories;

  /// No description provided for @academyHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get academyHistory;

  /// No description provided for @academyHifz.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get academyHifz;

  /// No description provided for @academyTajweed.
  ///
  /// In en, this message translates to:
  /// **'Tajweed'**
  String get academyTajweed;

  /// No description provided for @academyDua.
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get academyDua;

  /// No description provided for @academyUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Understanding Islam'**
  String get academyUnderstanding;

  /// No description provided for @academyNasheed.
  ///
  /// In en, this message translates to:
  /// **'Nasheed'**
  String get academyNasheed;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTitle;

  /// No description provided for @familyAddChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get familyAddChild;

  /// No description provided for @familyInviteParent.
  ///
  /// In en, this message translates to:
  /// **'Invite Co-Parent'**
  String get familyInviteParent;

  /// No description provided for @familyInviteTeacher.
  ///
  /// In en, this message translates to:
  /// **'Invite Teacher'**
  String get familyInviteTeacher;

  /// No description provided for @familyNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No children added yet. Tap Add Child to get started.'**
  String get familyNoChildren;

  /// No description provided for @familySendCredentials.
  ///
  /// In en, this message translates to:
  /// **'Send credentials via text'**
  String get familySendCredentials;

  /// No description provided for @familyViewProgress.
  ///
  /// In en, this message translates to:
  /// **'View Progress'**
  String get familyViewProgress;

  /// No description provided for @familySpeakToWasia.
  ///
  /// In en, this message translates to:
  /// **'Speak to Wasia'**
  String get familySpeakToWasia;

  /// No description provided for @familyRemoveChild.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get familyRemoveChild;

  /// No description provided for @teacherReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Work'**
  String get teacherReviewTitle;

  /// No description provided for @teacherNoSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No pending submissions.'**
  String get teacherNoSubmissions;

  /// No description provided for @teacherScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get teacherScore;

  /// No description provided for @teacherFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get teacherFeedback;

  /// No description provided for @teacherStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get teacherStrengths;

  /// No description provided for @teacherImprovements.
  ///
  /// In en, this message translates to:
  /// **'Areas to Improve'**
  String get teacherImprovements;

  /// No description provided for @teacherSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get teacherSubmitReview;

  /// No description provided for @wasiaTitle.
  ///
  /// In en, this message translates to:
  /// **'Speak to Wasia'**
  String get wasiaTitle;

  /// No description provided for @wasiaPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask Wasia about your child...'**
  String get wasiaPlaceholder;

  /// No description provided for @wasiaWelcome.
  ///
  /// In en, this message translates to:
  /// **'Ask Wasia anything about your child\'s learning.'**
  String get wasiaWelcome;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsElderMode.
  ///
  /// In en, this message translates to:
  /// **'Elder mode'**
  String get settingsElderMode;

  /// No description provided for @settingsChildMode.
  ///
  /// In en, this message translates to:
  /// **'Child mode'**
  String get settingsChildMode;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get errorWrongPassword;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonDone;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ar-Rayaan'**
  String get onboardingWelcome;

  /// No description provided for @onboardingPrayer.
  ///
  /// In en, this message translates to:
  /// **'Track your prayers and never miss a salah'**
  String get onboardingPrayer;

  /// No description provided for @onboardingQuran.
  ///
  /// In en, this message translates to:
  /// **'Read, listen, and reflect on the Quran'**
  String get onboardingQuran;

  /// No description provided for @onboardingAcademy.
  ///
  /// In en, this message translates to:
  /// **'Learn with structured courses for every level'**
  String get onboardingAcademy;

  /// No description provided for @onboardingFamily.
  ///
  /// In en, this message translates to:
  /// **'Add your family and grow together in faith'**
  String get onboardingFamily;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
