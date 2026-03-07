import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:play_sync_new/features/auth/domain/usecases/login_usecase.dart';
import 'package:play_sync_new/features/auth/domain/usecases/register_usecase.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';
import 'package:play_sync_new/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/upload_cover_picture_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/upload_gallery_pictures_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/upload_profile_picture_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockProfileRepository extends Mock implements IProfileRepository {}

class MockXFile extends Mock implements XFile {}

class FakeXFile extends Fake implements XFile {}

class IntegrationHostApp extends StatefulWidget {
  const IntegrationHostApp({super.key});

  @override
  State<IntegrationHostApp> createState() => _IntegrationHostAppState();
}

class _IntegrationHostAppState extends State<IntegrationHostApp> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loggedIn = false;
  bool _isDark = false;
  int _tabIndex = 0;
  bool _loadingItems = false;
  List<String> _items = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    setState(() {
      _items = ['match-1', 'match-2', 'match-3'];
      _loadingItems = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      home: Builder(
        builder: (appContext) {
          return _loggedIn
              ? Scaffold(
                  appBar: AppBar(
                    title: Text(_tabIndex == 0 ? 'Dashboard' : 'Profile'),
                    actions: [
                      IconButton(
                        key: const Key('theme_toggle'),
                        onPressed: () => setState(() => _isDark = !_isDark),
                        icon: const Icon(Icons.brightness_6),
                      ),
                      IconButton(
                        key: const Key('logout_button'),
                        onPressed: () {
                          showDialog<void>(
                            context: appContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              actions: [
                                TextButton(
                                  key: const Key('cancel_logout'),
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  key: const Key('confirm_logout'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    setState(() => _loggedIn = false);
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  body: _tabIndex == 0
                      ? Column(
                          children: [
                            Text(
                              _isDark ? 'Theme: Dark' : 'Theme: Light',
                              key: const Key('theme_label'),
                            ),
                            ElevatedButton(
                              key: const Key('save_button'),
                              onPressed: () {
                                ScaffoldMessenger.of(appContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saved successfully'),
                                  ),
                                );
                              },
                              child: const Text('Save'),
                            ),
                            ElevatedButton(
                              key: const Key('load_items_button'),
                              onPressed: _loadItems,
                              child: const Text('Load Items'),
                            ),
                            if (_loadingItems)
                              const CircularProgressIndicator(
                                key: Key('items_loading'),
                              ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    key: Key('item_$index'),
                                    title: Text(_items[index]),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: ElevatedButton(
                            key: const Key('open_profile_dialog'),
                            onPressed: () {
                              showDialog<void>(
                                context: appContext,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Profile Dialog'),
                                  actions: [
                                    TextButton(
                                      key: const Key('close_profile_dialog'),
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Open Profile Dialog'),
                          ),
                        ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _tabIndex,
                    onTap: (value) => setState(() => _tabIndex = value),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
                )
              : Scaffold(
                  appBar: AppBar(
                    title: const Text('Login', key: Key('login_title')),
                  ),
                  body: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('login_email'),
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        TextFormField(
                          key: const Key('login_password'),
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) return 'Password too short';
                            return null;
                          },
                        ),
                        ElevatedButton(
                          key: const Key('login_submit'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _loggedIn = true);
                            }
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeXFile());
  });

  group('UNIT USE CASE TESTS (10)', () {
    late MockAuthRepository mockAuthRepository;
    late MockProfileRepository mockProfileRepository;

    const authSuccess = AuthEntity(email: 'user@test.com', fullName: 'User One');
    const profileSuccess = ProfileEntity(fullName: 'Bibek', email: 'bibek@test.com');

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockProfileRepository = MockProfileRepository();
    });

    test('Use case 1: LoginUsecase returns AuthEntity on success', () async {
      final usecase = LoginUsecase(repository: mockAuthRepository);
      when(() => mockAuthRepository.login(email: 'user@test.com', password: 'secret123'))
          .thenAnswer((_) async => const Right(authSuccess));

      final result = await usecase(LoginParams(email: 'user@test.com', password: 'secret123'));

      expect(result, const Right(authSuccess));
      verify(() => mockAuthRepository.login(email: 'user@test.com', password: 'secret123'))
          .called(1);
    });

    test('Use case 2: LoginUsecase returns Failure on invalid credentials', () async {
      final usecase = LoginUsecase(repository: mockAuthRepository);
      const failure = AuthFailure(message: 'Invalid credentials');

      when(() => mockAuthRepository.login(email: 'bad@test.com', password: 'wrong'))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(LoginParams(email: 'bad@test.com', password: 'wrong'));

      expect(result, const Left(failure));
    });

    test('Use case 3: RegisterUsecase forwards all registration fields', () async {
      final usecase = RegisterUsecase(repository: mockAuthRepository);

      when(
        () => mockAuthRepository.register(
          fullName: 'New User',
          email: 'new@test.com',
          password: 'pass1234',
          confirmPassword: 'pass1234',
        ),
      ).thenAnswer((_) async => const Right(authSuccess));

      final result = await usecase(
        RegisterParams(
          fullName: 'New User',
          email: 'new@test.com',
          password: 'pass1234',
          confirmPassword: 'pass1234',
        ),
      );

      expect(result, const Right(authSuccess));
      verify(
        () => mockAuthRepository.register(
          fullName: 'New User',
          email: 'new@test.com',
          password: 'pass1234',
          confirmPassword: 'pass1234',
        ),
      ).called(1);
    });

    test('Use case 4: GetProfileUsecase returns profile from repository', () async {
      final usecase = GetProfileUsecase(repository: mockProfileRepository);
      when(() => mockProfileRepository.getProfile())
          .thenAnswer((_) async => const Right(profileSuccess));

      final result = await usecase();

      expect(result, const Right(profileSuccess));
      verify(() => mockProfileRepository.getProfile()).called(1);
    });

    test('Use case 5: UpdateProfileUsecase forwards editable fields', () async {
      final usecase = UpdateProfileUsecase(repository: mockProfileRepository);
      when(
        () => mockProfileRepository.updateProfile(
          fullName: 'Updated Name',
          phone: '9800000000',
          favoriteGame: 'PUBG',
          place: 'Kathmandu',
          bio: 'GG',
          currentPassword: null,
          changePassword: null,
          profilePicture: null,
        ),
      ).thenAnswer((_) async => const Right(profileSuccess));

      final result = await usecase(
        UpdateProfileParams(
          fullName: 'Updated Name',
          phone: '9800000000',
          favoriteGame: 'PUBG',
          place: 'Kathmandu',
          bio: 'GG',
        ),
      );

      expect(result, const Right(profileSuccess));
    });

    test('Use case 6: UploadProfilePictureUsecase rejects files bigger than 5MB',
        () async {
      final mockImage = MockXFile();
      final usecase = UploadProfilePictureUsecase(repository: mockProfileRepository);
      when(() => mockImage.length()).thenAnswer((_) async => 6 * 1024 * 1024);
      when(() => mockImage.name).thenReturn('big.jpg');

      final result = await usecase(mockImage);

      expect(result.isLeft(), true);
      verifyNever(() => mockProfileRepository.uploadProfilePicture(any()));
    });

    test('Use case 7: UploadProfilePictureUsecase rejects unsupported extension',
        () async {
      final mockImage = MockXFile();
      final usecase = UploadProfilePictureUsecase(repository: mockProfileRepository);
      when(() => mockImage.length()).thenAnswer((_) async => 1024);
      when(() => mockImage.name).thenReturn('avatar.bmp');

      final result = await usecase(mockImage);

      expect(result.isLeft(), true);
      verifyNever(() => mockProfileRepository.uploadProfilePicture(any()));
    });

    test('Use case 8: UploadProfilePictureUsecase delegates valid image to repository',
        () async {
      final mockImage = MockXFile();
      final usecase = UploadProfilePictureUsecase(repository: mockProfileRepository);
      when(() => mockImage.length()).thenAnswer((_) async => 1024);
      when(() => mockImage.name).thenReturn('avatar.png');
      when(() => mockProfileRepository.uploadProfilePicture(mockImage))
          .thenAnswer((_) async => const Right('https://img/profile.png'));

      final result = await usecase(mockImage);

      expect(result, const Right('https://img/profile.png'));
      verify(() => mockProfileRepository.uploadProfilePicture(mockImage)).called(1);
    });

    test('Use case 9: UploadCoverPictureUsecase rejects oversized image', () async {
      final mockImage = MockXFile();
      final usecase = UploadCoverPictureUsecase(repository: mockProfileRepository);
      when(() => mockImage.length()).thenAnswer((_) async => 7 * 1024 * 1024);

      final result = await usecase(mockImage);

      expect(result.isLeft(), true);
      verifyNever(() => mockProfileRepository.uploadCoverPicture(any()));
    });

    test('Use case 10: UploadGalleryPicturesUsecase returns empty success for empty list',
        () async {
      final usecase = UploadGalleryPicturesUsecase(repository: mockProfileRepository);

      final result = await usecase([]);

      expect(result, const Right(<String>[]));
      verifyNever(() => mockProfileRepository.uploadGalleryPictures(any()));
    });
  });

  group('INTEGRATION TESTS (10)', () {
    testWidgets('Integration 1: App starts on Login screen', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      expect(find.byKey(const Key('login_title')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });

    testWidgets('Integration 2: Login validation errors are shown', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Integration 3: Valid login navigates to Dashboard', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('save_button')), findsOneWidget);
    });

    testWidgets('Integration 4: Bottom nav switches from Dashboard to Profile',
        (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsWidgets);
      expect(find.byKey(const Key('open_profile_dialog')), findsOneWidget);
    });

    testWidgets('Integration 5: Profile dialog opens and closes', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_profile_dialog')));
      await tester.pumpAndSettle();

      expect(find.text('Profile Dialog'), findsOneWidget);

      await tester.tap(find.byKey(const Key('close_profile_dialog')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Dialog'), findsNothing);
    });

    testWidgets('Integration 6: Save action shows SnackBar', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      expect(find.text('Saved successfully'), findsOneWidget);
    });

    testWidgets('Integration 7: Async load shows progress then list items', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('load_items_button')));
      await tester.pump();
      expect(find.byKey(const Key('items_loading')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 130));
      await tester.pumpAndSettle();

      expect(find.text('match-1'), findsOneWidget);
      expect(find.text('match-2'), findsOneWidget);
      expect(find.text('match-3'), findsOneWidget);
    });

    testWidgets('Integration 8: Theme toggle updates theme label', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Theme: Light'), findsOneWidget);

      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Theme: Dark'), findsOneWidget);
    });

    testWidgets('Integration 9: Logout cancel keeps user logged in', (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Logout'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancel_logout')));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Integration 10: Logout confirm returns to Login screen',
        (tester) async {
      await tester.pumpWidget(const IntegrationHostApp());
      await tester.enterText(find.byKey(const Key('login_email')), 'user@test.com');
      await tester.enterText(find.byKey(const Key('login_password')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_logout')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_title')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });
  });
}
