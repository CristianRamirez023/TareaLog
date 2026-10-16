// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TareaLog';

  @override
  String get appSubtitle => 'Organize your tasks';

  @override
  String get login => 'Sign In';

  @override
  String get register => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get selectRole => 'Select your Role';

  @override
  String get student => 'Student';

  @override
  String get verifier => 'Verifier';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get noAccount => 'Don\'t have an account? Sign up here';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get acceptPolicy => 'I accept the ';

  @override
  String get privacyPolicy => 'Data Treatment Policy';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordMessage =>
      'Enter your email to receive a recovery link.';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get progress => 'General progress';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get total => 'Total';

  @override
  String get newTask => 'New Task';

  @override
  String get taskTitle => 'Task title';

  @override
  String get taskDescription => 'Description (Optional)';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get status => 'Status';

  @override
  String get tasks => 'tasks';

  @override
  String get task => 'task';

  @override
  String get verifierLinked => 'Verifier Linked';

  @override
  String get bindingCode => 'Binding Code';

  @override
  String get generateCode => 'Generate';

  @override
  String get newCode => 'New';

  @override
  String get linkedStudents => 'Linked Students';

  @override
  String get linkStudent => 'Link Student';

  @override
  String get link => 'Link';

  @override
  String get review => 'Review';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get observations => 'Observations / Feedback';

  @override
  String get download => 'Options';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadExcel => 'Download Excel';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get logout => 'Logout';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get generatingExcel => 'Generating Excel...';

  @override
  String get creatingBackup => 'Creating backup...';

  @override
  String get backupCreated => '✅ Backup created successfully';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String get backupRestored => '✅ Backup restored';

  @override
  String get restore => 'Restore';

  @override
  String get restoreWarning =>
      '⚠️ Current data will be overwritten with the backup.\n\nDo you want to continue?';

  @override
  String get sessionLocked => 'Session locked';

  @override
  String get sessionLockedMessage =>
      'For security, enter your password to continue.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlocked => 'Unlocked!';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get verifyError => 'Verification error. Try again.';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get logoutInactivityMessage =>
      'Session closed due to inactivity (5 minutes)';

  @override
  String get noTasksYet => 'You have no tasks yet.\nPress + to add one!';

  @override
  String get noLinkedStudents =>
      'You have no linked students.\nUse the \"Link\" button to add one.';

  @override
  String get studentHasNoTasks => 'This student has no tasks yet.';

  @override
  String tasksCompleted(Object completed, Object total) {
    return '$completed of $total tasks completed';
  }

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get tasksCountOne => '1 task';

  @override
  String get taskCreated => 'New task created';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get taskCompletedStatus => 'Completed';

  @override
  String get taskInProgress => 'In progress';

  @override
  String taskStatusStudent(Object status) {
    return 'Student status: $status';
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
  String get welcomeUser => 'Welcome back,';

  @override
  String get generateCodeButton => 'Generate';

  @override
  String get newCodeButton => 'New';

  @override
  String generateNewCode(Object code) {
    return 'New code generated: $code';
  }

  @override
  String get errorGeneratingCode => 'Error generating code';

  @override
  String get errorCreatingTask => 'Error creating task';

  @override
  String get errorUpdatingTask => 'Error updating task';

  @override
  String get errorDeletingTask => 'Error deleting task';

  @override
  String errorLinking(Object error) {
    return 'Error linking student: $error';
  }

  @override
  String get errorUpdatingStatus => 'Error updating status';

  @override
  String studentLinked(Object name) {
    return '$name linked successfully';
  }

  @override
  String get invalidCode =>
      'Invalid or used code. Ask the student to generate a new one.';

  @override
  String get studentAlreadyLinked =>
      'This student is already linked to your account';

  @override
  String get studentLinkedToOther =>
      'This student is already linked to another verifier';

  @override
  String get enterCode => 'Enter a valid code';

  @override
  String get linkStudentTitle => 'Link Student';

  @override
  String get linkStudentMessage =>
      'Ask the student for their binding code (format TRG-XXXXXX).';

  @override
  String get codeLabel => 'Code (e.g. TRG-8A92)';

  @override
  String reviewTask(Object title) {
    return 'Review: $title';
  }

  @override
  String taskMarked(Object status) {
    return 'Task marked as: $status';
  }

  @override
  String get observationRequired => 'Add an observation to reject';

  @override
  String get startNow => 'Start now! 💪';

  @override
  String get startingOut => 'You\'re starting! 🚀';

  @override
  String get goodPace => 'Good pace! 🔥';

  @override
  String get doingGreat => 'Doing great! ⭐';

  @override
  String get almostThere => 'Almost there! 🎯';

  @override
  String get completed => 'Completed! 🏆';
}
