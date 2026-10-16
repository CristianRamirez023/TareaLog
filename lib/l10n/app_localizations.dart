import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'TareaLog'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Organiza tus tareas'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get register;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrar Cuenta'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @selectRole.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu Rol'**
  String get selectRole;

  /// No description provided for @student.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get student;

  /// No description provided for @verifier.
  ///
  /// In es, this message translates to:
  /// **'Verificador'**
  String get verifier;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate aquí'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get haveAccount;

  /// No description provided for @acceptPolicy.
  ///
  /// In es, this message translates to:
  /// **'Acepto la '**
  String get acceptPolicy;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Tratamiento de Datos'**
  String get privacyPolicy;

  /// No description provided for @resetPassword.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get resetPassword;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo para recibir un enlace de recuperación.'**
  String get resetPasswordMessage;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @welcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta,'**
  String get welcomeBack;

  /// No description provided for @myTasks.
  ///
  /// In es, this message translates to:
  /// **'Mis Tareas'**
  String get myTasks;

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso general'**
  String get progress;

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobadas'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas'**
  String get rejected;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @newTask.
  ///
  /// In es, this message translates to:
  /// **'Nueva Tarea'**
  String get newTask;

  /// No description provided for @taskTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la tarea'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (Opcional)'**
  String get taskDescription;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @tasks.
  ///
  /// In es, this message translates to:
  /// **'tareas'**
  String get tasks;

  /// No description provided for @task.
  ///
  /// In es, this message translates to:
  /// **'tarea'**
  String get task;

  /// No description provided for @verifierLinked.
  ///
  /// In es, this message translates to:
  /// **'Verificador Vinculado'**
  String get verifierLinked;

  /// No description provided for @bindingCode.
  ///
  /// In es, this message translates to:
  /// **'Código de Vinculación'**
  String get bindingCode;

  /// No description provided for @generateCode.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get generateCode;

  /// No description provided for @newCode.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newCode;

  /// No description provided for @linkedStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes Vinculados'**
  String get linkedStudents;

  /// No description provided for @linkStudent.
  ///
  /// In es, this message translates to:
  /// **'Vincular Estudiante'**
  String get linkStudent;

  /// No description provided for @link.
  ///
  /// In es, this message translates to:
  /// **'Vincular'**
  String get link;

  /// No description provided for @review.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get review;

  /// No description provided for @approve.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In es, this message translates to:
  /// **'Desestimar'**
  String get reject;

  /// No description provided for @observations.
  ///
  /// In es, this message translates to:
  /// **'Observaciones / Retroalimentación'**
  String get observations;

  /// No description provided for @download.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get download;

  /// No description provided for @downloadPdf.
  ///
  /// In es, this message translates to:
  /// **'Descargar PDF'**
  String get downloadPdf;

  /// No description provided for @downloadExcel.
  ///
  /// In es, this message translates to:
  /// **'Descargar Excel'**
  String get downloadExcel;

  /// No description provided for @createBackup.
  ///
  /// In es, this message translates to:
  /// **'Hacer Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurar Backup'**
  String get restoreBackup;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @lightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo claro'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get darkMode;

  /// No description provided for @changeLanguage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar idioma'**
  String get changeLanguage;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @generatingPdf.
  ///
  /// In es, this message translates to:
  /// **'Generando PDF...'**
  String get generatingPdf;

  /// No description provided for @generatingExcel.
  ///
  /// In es, this message translates to:
  /// **'Generando Excel...'**
  String get generatingExcel;

  /// No description provided for @creatingBackup.
  ///
  /// In es, this message translates to:
  /// **'Creando backup...'**
  String get creatingBackup;

  /// No description provided for @backupCreated.
  ///
  /// In es, this message translates to:
  /// **'✅ Backup generado correctamente'**
  String get backupCreated;

  /// No description provided for @restoringBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurando backup...'**
  String get restoringBackup;

  /// No description provided for @backupRestored.
  ///
  /// In es, this message translates to:
  /// **'✅ Backup restaurado'**
  String get backupRestored;

  /// No description provided for @restore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @restoreWarning.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Se sobrescribirán los datos actuales con los del backup.\n\n¿Deseas continuar?'**
  String get restoreWarning;

  /// No description provided for @sessionLocked.
  ///
  /// In es, this message translates to:
  /// **'Sesión bloqueada'**
  String get sessionLocked;

  /// No description provided for @sessionLockedMessage.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, ingresa tu contraseña para continuar.'**
  String get sessionLockedMessage;

  /// No description provided for @unlock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get unlock;

  /// No description provided for @unlocked.
  ///
  /// In es, this message translates to:
  /// **'¡Desbloqueado!'**
  String get unlocked;

  /// No description provided for @enterPassword.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get enterPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get wrongPassword;

  /// No description provided for @verifyError.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar. Intenta de nuevo.'**
  String get verifyError;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado'**
  String get unexpectedError;

  /// No description provided for @logoutInactivityMessage.
  ///
  /// In es, this message translates to:
  /// **'Sesión cerrada por inactividad (5 minutos sin uso)'**
  String get logoutInactivityMessage;

  /// No description provided for @noTasksYet.
  ///
  /// In es, this message translates to:
  /// **'No tienes tareas aún.\n¡Presiona + para agregar una!'**
  String get noTasksYet;

  /// No description provided for @noLinkedStudents.
  ///
  /// In es, this message translates to:
  /// **'No tienes estudiantes vinculados.\nUsa el botón \"Vincular\" para agregar uno.'**
  String get noLinkedStudents;

  /// No description provided for @studentHasNoTasks.
  ///
  /// In es, this message translates to:
  /// **'Este estudiante no tiene tareas aún.'**
  String get studentHasNoTasks;

  /// No description provided for @tasksCompleted.
  ///
  /// In es, this message translates to:
  /// **'{completed} de {total} tareas completadas'**
  String tasksCompleted(Object completed, Object total);

  /// No description provided for @tasksCount.
  ///
  /// In es, this message translates to:
  /// **'{count} tareas'**
  String tasksCount(Object count);

  /// No description provided for @tasksCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 tarea'**
  String get tasksCountOne;

  /// No description provided for @taskCreated.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea creada'**
  String get taskCreated;

  /// No description provided for @taskDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tarea eliminada'**
  String get taskDeleted;

  /// No description provided for @taskCompletedStatus.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get taskCompletedStatus;

  /// No description provided for @taskInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get taskInProgress;

  /// No description provided for @taskStatusStudent.
  ///
  /// In es, this message translates to:
  /// **'Estado alumno: {status}'**
  String taskStatusStudent(Object status);

  /// No description provided for @feedback.
  ///
  /// In es, this message translates to:
  /// **'Feedback: {feedback}'**
  String feedback(Object feedback);

  /// No description provided for @observationsLabel.
  ///
  /// In es, this message translates to:
  /// **'Obs: {obs}'**
  String observationsLabel(Object obs);

  /// No description provided for @welcomeUser.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta,'**
  String get welcomeUser;

  /// No description provided for @generateCodeButton.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get generateCodeButton;

  /// No description provided for @newCodeButton.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newCodeButton;

  /// No description provided for @generateNewCode.
  ///
  /// In es, this message translates to:
  /// **'Nuevo código generado: {code}'**
  String generateNewCode(Object code);

  /// No description provided for @errorGeneratingCode.
  ///
  /// In es, this message translates to:
  /// **'Error al generar el código'**
  String get errorGeneratingCode;

  /// No description provided for @errorCreatingTask.
  ///
  /// In es, this message translates to:
  /// **'Error al crear la tarea'**
  String get errorCreatingTask;

  /// No description provided for @errorUpdatingTask.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar la tarea'**
  String get errorUpdatingTask;

  /// No description provided for @errorDeletingTask.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la tarea'**
  String get errorDeletingTask;

  /// No description provided for @errorLinking.
  ///
  /// In es, this message translates to:
  /// **'Error al vincular estudiante: {error}'**
  String errorLinking(Object error);

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar estado'**
  String get errorUpdatingStatus;

  /// No description provided for @studentLinked.
  ///
  /// In es, this message translates to:
  /// **'{name} vinculado con éxito'**
  String studentLinked(Object name);

  /// No description provided for @invalidCode.
  ///
  /// In es, this message translates to:
  /// **'Código no válido o ya fue usado. Pídele al estudiante que genere uno nuevo.'**
  String get invalidCode;

  /// No description provided for @studentAlreadyLinked.
  ///
  /// In es, this message translates to:
  /// **'Este estudiante ya está vinculado a tu cuenta'**
  String get studentAlreadyLinked;

  /// No description provided for @studentLinkedToOther.
  ///
  /// In es, this message translates to:
  /// **'Este estudiante ya está vinculado a otro verificador'**
  String get studentLinkedToOther;

  /// No description provided for @enterCode.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un código válido'**
  String get enterCode;

  /// No description provided for @linkStudentTitle.
  ///
  /// In es, this message translates to:
  /// **'Vincular Estudiante'**
  String get linkStudentTitle;

  /// No description provided for @linkStudentMessage.
  ///
  /// In es, this message translates to:
  /// **'Pídele al estudiante su código de vinculación (formato TRG-XXXXXX).'**
  String get linkStudentMessage;

  /// No description provided for @codeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código (ej. TRG-8A92)'**
  String get codeLabel;

  /// No description provided for @reviewTask.
  ///
  /// In es, this message translates to:
  /// **'Revisar: {title}'**
  String reviewTask(Object title);

  /// No description provided for @taskMarked.
  ///
  /// In es, this message translates to:
  /// **'Tarea marcada como: {status}'**
  String taskMarked(Object status);

  /// No description provided for @observationRequired.
  ///
  /// In es, this message translates to:
  /// **'Agrega una observación para rechazar'**
  String get observationRequired;

  /// No description provided for @startNow.
  ///
  /// In es, this message translates to:
  /// **'¡Empieza ya! 💪'**
  String get startNow;

  /// No description provided for @startingOut.
  ///
  /// In es, this message translates to:
  /// **'¡Vas empezando! 🚀'**
  String get startingOut;

  /// No description provided for @goodPace.
  ///
  /// In es, this message translates to:
  /// **'¡Buen ritmo! 🔥'**
  String get goodPace;

  /// No description provided for @doingGreat.
  ///
  /// In es, this message translates to:
  /// **'¡Vas muy bien! ⭐'**
  String get doingGreat;

  /// No description provided for @almostThere.
  ///
  /// In es, this message translates to:
  /// **'¡Casi lo logras! 🎯'**
  String get almostThere;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'¡Completado! 🏆'**
  String get completed;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
