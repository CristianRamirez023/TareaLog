import 'package:flutter/material.dart';

class PoliticaDatosScreen extends StatelessWidget {
  const PoliticaDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Tratamiento de Datos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // ENCABEZADO
            // ============================================================
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Política de Tratamiento\nde Datos Personales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'TareaLog',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última actualización: 22 de Septiembre de 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ============================================================
            // 1. RESPONSABLE
            // ============================================================
            _buildSection(
              context,
              number: '1',
              title: 'Responsable del Tratamiento',
              content:
                  'El responsable del tratamiento de los datos personales recolectados a través de la aplicación TareaLog es Cristian Esneider Ramírez López, con domicilio en Colombia, correo electrónico de contacto cristianramirez222005@gmail.com y teléfono de contacto 3015103885.',
            ),

            // ============================================================
            // 2. DATOS Y FINALIDAD
            // ============================================================
            _buildSection(
              context,
              number: '2',
              title: 'Datos Recolectados y Finalidad',
              content:
                  'Los datos personales que TareaLog recolecta son: nombre completo, correo electrónico y el rol seleccionado (Estudiante o Verificador).\n\n'
                  'La finalidad del tratamiento de estos datos es exclusivamente:\n\n'
                  '• Gestionar el registro y acceso de los usuarios a la aplicación.\n'
                  '• Diferenciar las funcionalidades disponibles según el rol (Estudiante o Verificador).\n'
                  '• Permitir la vinculación entre estudiantes y verificadores para la gestión y revisión de tareas.\n'
                  '• Enviar notificaciones relacionadas con la actividad de la cuenta.',
            ),

            // ============================================================
            // 3. DERECHOS
            // ============================================================
            _buildSection(
              context,
              number: '3',
              title: 'Derechos del Titular',
              content:
                  'Como titular de tus datos personales, tienes derecho a:\n\n'
                  '• Conocer, actualizar y rectificar tus datos personales frente a TareaLog.\n'
                  '• Solicitar prueba de la autorización otorgada para el tratamiento de tus datos.\n'
                  '• Ser informado sobre el uso que se le ha dado a tus datos personales.\n'
                  '• Presentar quejas ante la Superintendencia de Industria y Comercio (SIC) por infracciones a la ley.\n'
                  '• Revocar la autorización y/o solicitar la supresión de tus datos cuando no se respeten los principios, derechos y garantías legales.\n'
                  '• Acceder de forma gratuita a tus datos personales que hayan sido objeto de tratamiento.',
            ),

            // ============================================================
            // 4. ÁREA RESPONSABLE
            // ============================================================
            _buildSection(
              context,
              number: '4',
              title: 'Área Responsable de la Atención de Peticiones',
              content:
                  'La persona responsable de atender tus peticiones, consultas y reclamos para ejercer tus derechos es el creador de TareaLog, a través del correo electrónico cristianramirez222005@gmail.com.',
            ),

            // ============================================================
            // 5. PROCEDIMIENTO
            // ============================================================
            _buildSection(
              context,
              number: '5',
              title: 'Procedimiento para Ejercer tus Derechos',
              content:
                  'Para ejercer tus derechos de conocer, actualizar, rectificar, suprimir información o revocar la autorización, puedes enviar una solicitud al correo electrónico cristianramirez222005@gmail.com indicando:\n\n'
                  '• Tu nombre completo.\n'
                  '• El derecho que deseas ejercer.\n'
                  '• Una descripción clara de tu solicitud.\n\n'
                  'Tu solicitud será atendida en un plazo máximo de 15 días hábiles contados a partir de la fecha de recibo.',
            ),

            // ============================================================
            // 6. SEGURIDAD DE LA INFORMACIÓN
            // ============================================================
            _buildSection(
              context,
              number: '6',
              title: 'Seguridad de la Información',
              content:
                  'TareaLog se compromete a proteger la información personal de sus usuarios. Como parte de nuestras buenas prácticas de seguridad, seguimos los principios de la norma internacional ISO 27001 para garantizar:\n\n'
                  '• Confidencialidad: solo las personas autorizadas acceden a los datos.\n'
                  '• Integridad: los datos están completos y no han sido alterados.\n'
                  '• Disponibilidad: los datos están accesibles cuando se necesitan.\n\n'
                  'Los datos son almacenados de forma segura en los servidores de Google Firebase, que cuenta con altos estándares de seguridad y cifrado.',
            ),

            // ============================================================
            // 7. VIGENCIA
            // ============================================================
            _buildSection(
              context,
              number: '7',
              title: 'Vigencia',
              content:
                  'Esta política entra en vigencia a partir del 22 de Septiembre de 2026.\n\n'
                  'Los datos personales serán conservados durante el tiempo que el usuario mantenga una cuenta activa en TareaLog. Una vez el usuario solicite la supresión de su cuenta, los datos serán eliminados de nuestras bases de datos en un plazo máximo de 30 días hábiles.',
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ============================================================
            // ACEPTACIÓN
            // ============================================================
            Center(
              child: Text(
                'Al usar TareaLog, aceptas los términos\nde esta Política de Tratamiento de Datos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // BOTÓN CERRAR
            // ============================================================
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Entendido'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPER: Sección con número, título y contenido
  // ===========================================================================
  Widget _buildSection(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}