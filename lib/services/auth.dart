import 'package:google_sign_in/google_sign_in.dart';

class GoogleUser {
  const GoogleUser(this.id, this.name, this.email);
  final String id;
  final String? name;
  final String email;
}

/// Inicio de sesión con Google directo desde el teléfono (sin backend).
/// Requiere crear un cliente OAuth de Android en Google Cloud Console con el
/// paquete com.alexa.puzzle_deslizante y la huella SHA-1 de la app. Mientras
/// no esté configurado, [signIn] lanza un error y la app ofrece modo invitado.
class AuthService {
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  static Future<GoogleUser> signIn() async {
    await _init();
    final account = await GoogleSignIn.instance.authenticate();
    return GoogleUser(account.id, account.displayName, account.email);
  }

  static Future<void> signOut() async {
    try {
      await _init();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Sin sesión de Google (invitado): nada que cerrar.
    }
  }
}
