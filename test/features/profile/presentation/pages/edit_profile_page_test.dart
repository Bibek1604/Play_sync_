import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:play_sync_new/features/profile/presentation/state/profile_state.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';

// ────────────────────────────────────────────────
class MockProfileNotifier extends Mock implements ProfileNotifier {}

void main() {
  late MockProfileNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockProfileNotifier();

    // Default happy state (adjust fields to match your real ProfileState)
    when(() => mockNotifier.state).thenReturn(
      ProfileState(
        profile: ProfileEntity(
          fullName: 'Bibek Shrestha',
          phoneNumber: '+977987654321',
          location: 'Kathmandu',
          favouriteGame: 'Valorant',
          profilePicture: 'https://example.com/avatar.jpg',
        ),
        isUpdating: false,
        isUploadingPicture: false,
        // Add other required fields if your ProfileState has them
        // isLoading: false,
        // error: null,
        // successMessage: null,
      ),
    );

    when(
      () => mockNotifier.updateProfile(
        fullName: any(named: 'fullName'),
        phone: any(named: 'phone'),
        favouriteGame: any(named: 'favouriteGame'),
        place: any(named: 'place'),
        currentPassword: any(named: 'currentPassword'),
        changePassword: any(named: 'changePassword'),
        profilePicture: any(named: 'profilePicture'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => reset(mockNotifier));

  testWidgets('displays existing profile data in form fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bibek Shrestha'), findsOneWidget);
    expect(find.text('+977987654321'), findsOneWidget);
    expect(find.text('Kathmandu'), findsOneWidget);
    expect(find.text('Valorant'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // profile picture
  });

  testWidgets('shows loading indicator & disables save button during update', (tester) async {
    when(() => mockNotifier.state).thenReturn(
      ProfileState(
        profile: null,
        isUpdating: true,
        isUploadingPicture: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final saveButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ).evaluate().isEmpty
          ? find.byType(ElevatedButton)
          : find.byType(IconButton),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('calls updateProfile with changed values on save', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );

    await tester.pumpAndSettle();

    // Change full name field (first TextFormField)
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'New Bibek Name',
    );

    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    verify(
      () => mockNotifier.updateProfile(
        fullName: 'New Bibek Name',
        phone: '+977987654321',
        favouriteGame: 'Valorant',
        place: 'Kathmandu',
        currentPassword: null,
        changePassword: null,
        profilePicture: null,
      ),
    ).called(1);
  });
}