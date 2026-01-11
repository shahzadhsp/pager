
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
// import 'package:myapp/main.dart'; // Importa o teu ficheiro main

// import 'package:myapp/services/auth_service.dart';
// import 'package:myapp/providers/theme_provider.dart';
// import 'package:myapp/providers/user_provider.dart';
// import 'package:myapp/providers/chat_provider.dart';
// import 'package:myapp/providers/group_provider.dart';
// import 'package:myapp/providers/lora_service_provider.dart';
// import 'package:myapp/providers/map_provider.dart';

// void main() {
//   testWidgets('App builds without crashing', (WidgetTester tester) async {
//     // Cria um utilizador mock
//     final user = MockUser(
//       isAnonymous: false,
//       uid: 'someuid',
//       email: 'some@email.com',
//       displayName: 'Some Name',
//     );

//     // Configura o mock do FirebaseAuth
//     final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

//     // O googleSignInMock é necessário porque o auth_service tenta usá-lo
//     final googleSignIn = MockGoogleSignIn();

//     // Envolve a tua app com todos os providers necessários
//     await tester.pumpWidget(
//       MultiProvider(
//         providers: [
//           Provider<AuthService>(
//             create: (_) => AuthService(firebaseAuth: auth, googleSignIn: googleSignIn),
//           ),
//           ChangeNotifierProvider(create: (_) => ThemeProvider()),
//           ChangeNotifierProvider(create: (_) => UserProvider()),
//           ChangeNotifierProvider(create: (_) => ChatProvider()),
//           ChangeNotifierProvider(create: (_) => GroupProvider()),
//           ChangeNotifierProvider(create: (_) => LoraServiceProvider()),
//           ChangeNotifierProvider(create: (_) => MapProvider()),
//         ],
//         child: const MyApp(),
//       ),
//     );

//     // Verifica se o widget principal (MyApp) foi renderizado.
//     // A presença de um MaterialApp é um bom indicador.
//     expect(find.byType(MaterialApp), findsOneWidget);
//   });
// }
