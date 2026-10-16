// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TareaLog';

  @override
  String get appSubtitle => 'Organiza tus tareas';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Crear Cuenta';

  @override
  String get signIn => 'Ingresar';

  @override
  String get signUp => 'Registrar Cuenta';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get selectRole => 'Selecciona tu Rol';

  @override
  String get student => 'Estudiante';

  @override
  String get verifier => 'Verificador';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get noAccount => '¿No tienes cuenta? Regístrate aquí';

  @override
  String get haveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get acceptPolicy => 'Acepto la ';

  @override
  String get privacyPolicy => 'Política de Tratamiento de Datos';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get resetPasswordMessage =>
      'Ingresa tu correo para recibir un enlace de recuperación.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get send => 'Enviar';

  @override
  String get welcomeBack => 'Bienvenido de vuelta,';

  @override
  String get myTasks => 'Mis Tareas';

  @override
  String get progress => 'Progreso general';

  @override
  String get pending => 'Pendientes';

  @override
  String get approved => 'Aprobadas';

  @override
  String get rejected => 'Rechazadas';

  @override
  String get total => 'Total';

  @override
  String get newTask => 'Nueva Tarea';

  @override
  String get taskTitle => 'Título de la tarea';

  @override
  String get taskDescription => 'Descripción (Opcional)';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get status => 'Estado';

  @override
  String get tasks => 'tareas';

  @override
  String get task => 'tarea';

  @override
  String get verifierLinked => 'Verificador Vinculado';

  @override
  String get bindingCode => 'Código de Vinculación';

  @override
  String get generateCode => 'Generar';

  @override
  String get newCode => 'Nuevo';

  @override
  String get linkedStudents => 'Estudiantes Vinculados';

  @override
  String get linkStudent => 'Vincular Estudiante';

  @override
  String get link => 'Vincular';

  @override
  String get review => 'Revisar';

  @override
  String get approve => 'Aprobar';

  @override
  String get reject => 'Desestimar';

  @override
  String get observations => 'Observaciones / Retroalimentación';

  @override
  String get download => 'Opciones';

  @override
  String get downloadPdf => 'Descargar PDF';

  @override
  String get downloadExcel => 'Descargar Excel';

  @override
  String get createBackup => 'Hacer Backup';

  @override
  String get restoreBackup => 'Restaurar Backup';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get generatingPdf => 'Generando PDF...';

  @override
  String get generatingExcel => 'Generando Excel...';

  @override
  String get creatingBackup => 'Creando backup...';

  @override
  String get backupCreated => '✅ Backup generado correctamente';

  @override
  String get restoringBackup => 'Restaurando backup...';

  @override
  String get backupRestored => '✅ Backup restaurado';

  @override
  String get restore => 'Restaurar';

  @override
  String get restoreWarning =>
      '⚠️ Se sobrescribirán los datos actuales con los del backup.\n\n¿Deseas continuar?';

  @override
  String get sessionLocked => 'Sesión bloqueada';

  @override
  String get sessionLockedMessage =>
      'Por seguridad, ingresa tu contraseña para continuar.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get unlocked => '¡Desbloqueado!';

  @override
  String get enterPassword => 'Ingresa tu contraseña';

  @override
  String get wrongPassword => 'Contraseña incorrecta';

  @override
  String get verifyError => 'Error al verificar. Intenta de nuevo.';

  @override
  String get unexpectedError => 'Error inesperado';

  @override
  String get logoutInactivityMessage =>
      'Sesión cerrada por inactividad (5 minutos sin uso)';

  @override
  String get noTasksYet =>
      'No tienes tareas aún.\n¡Presiona + para agregar una!';

  @override
  String get noLinkedStudents =>
      'No tienes estudiantes vinculados.\nUsa el botón \"Vincular\" para agregar uno.';

  @override
  String get studentHasNoTasks => 'Este estudiante no tiene tareas aún.';

  @override
  String tasksCompleted(Object completed, Object total) {
    return '$completed de $total tareas completadas';
  }

  @override
  String tasksCount(Object count) {
    return '$count tareas';
  }

  @override
  String get tasksCountOne => '1 tarea';

  @override
  String get taskCreated => 'Nueva tarea creada';

  @override
  String get taskDeleted => 'Tarea eliminada';

  @override
  String get taskCompletedStatus => 'Completada';

  @override
  String get taskInProgress => 'En progreso';

  @override
  String taskStatusStudent(Object status) {
    return 'Estado alumno: $status';
  }

  @override
  String feedback(Object feedback) {
    return 'Feedback: $feedback';
  }

  @override
  String observationsLabel(Object obs) {
    return 'Obs: $obs';
  }

  @override
  String get welcomeUser => 'Bienvenido de vuelta,';

  @override
  String get generateCodeButton => 'Generar';

  @override
  String get newCodeButton => 'Nuevo';

  @override
  String generateNewCode(Object code) {
    return 'Nuevo código generado: $code';
  }

  @override
  String get errorGeneratingCode => 'Error al generar el código';

  @override
  String get errorCreatingTask => 'Error al crear la tarea';

  @override
  String get errorUpdatingTask => 'Error al actualizar la tarea';

  @override
  String get errorDeletingTask => 'Error al eliminar la tarea';

  @override
  String errorLinking(Object error) {
    return 'Error al vincular estudiante: $error';
  }

  @override
  String get errorUpdatingStatus => 'Error al actualizar estado';

  @override
  String studentLinked(Object name) {
    return '$name vinculado con éxito';
  }

  @override
  String get invalidCode =>
      'Código no válido o ya fue usado. Pídele al estudiante que genere uno nuevo.';

  @override
  String get studentAlreadyLinked =>
      'Este estudiante ya está vinculado a tu cuenta';

  @override
  String get studentLinkedToOther =>
      'Este estudiante ya está vinculado a otro verificador';

  @override
  String get enterCode => 'Ingresa un código válido';

  @override
  String get linkStudentTitle => 'Vincular Estudiante';

  @override
  String get linkStudentMessage =>
      'Pídele al estudiante su código de vinculación (formato TRG-XXXXXX).';

  @override
  String get codeLabel => 'Código (ej. TRG-8A92)';

  @override
  String reviewTask(Object title) {
    return 'Revisar: $title';
  }

  @override
  String taskMarked(Object status) {
    return 'Tarea marcada como: $status';
  }

  @override
  String get observationRequired => 'Agrega una observación para rechazar';

  @override
  String get startNow => '¡Empieza ya! 💪';

  @override
  String get startingOut => '¡Vas empezando! 🚀';

  @override
  String get goodPace => '¡Buen ritmo! 🔥';

  @override
  String get doingGreat => '¡Vas muy bien! ⭐';

  @override
  String get almostThere => '¡Casi lo logras! 🎯';

  @override
  String get completed => '¡Completado! 🏆';
}
