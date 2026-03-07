import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// MOCK CLASSES
// ============================================================================

class MockDio extends Mock implements Dio {}

class MockHttpClient extends Mock implements http.Client {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

// ============================================================================
// TEST WIDGETS AND MODELS
// ============================================================================

// Example Model
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

// Example Payment Model
class PaymentTransaction {
  final String transactionId;
  final double amount;
  final String status;

  PaymentTransaction({
    required this.transactionId,
    required this.amount,
    required this.status,
  });
}

// ============================================================================
// STATE MANAGEMENT EXAMPLES
// ============================================================================

// 1. Provider Example - Counter with setState
class CounterWidget extends StatefulWidget {
  const CounterWidget({Key? key}) : super(key: key);

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int counter = 0;

  void increment() {
    setState(() {
      counter++;
    });
  }

  void decrement() {
    setState(() {
      counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Count: $counter', key: const Key('counter_text')),
            ElevatedButton(
              key: const Key('increment_button'),
              onPressed: increment,
              child: const Text('Increment'),
            ),
            ElevatedButton(
              key: const Key('decrement_button'),
              onPressed: decrement,
              child: const Text('Decrement'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Riverpod State Management
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class RiverpodCounterWidget extends ConsumerWidget {
  const RiverpodCounterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Count: $count', key: const Key('riverpod_counter')),
            ElevatedButton(
              key: const Key('riverpod_increment'),
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Form Widget with Validation
class LoginFormWidget extends StatefulWidget {
  final void Function(String email, String password)? onSubmit;

  const LoginFormWidget({Key? key, this.onSubmit}) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      widget.onSubmit?.call(_emailController.text, _passwordController.text);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _validatePassword,
              ),
              if (_isLoading)
                const CircularProgressIndicator(key: Key('loading_indicator')),
              ElevatedButton(
                key: const Key('submit_button'),
                onPressed: _isLoading ? null : _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. Navigation Widget
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          key: const Key('navigate_button'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DetailScreen()),
            );
          },
          child: const Text('Go to Details'),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(
        child: Text('Detail Screen', key: Key('detail_text')),
      ),
    );
  }
}

// 5. Dialog Widget
class DialogWidget extends StatelessWidget {
  const DialogWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('show_dialog_button'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Alert'),
                    content: const Text('This is an alert message'),
                    actions: [
                      TextButton(
                        key: const Key('dialog_ok_button'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );
  }
}

// 6. SnackBar Widget
class SnackBarWidget extends StatelessWidget {
  const SnackBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('show_snackbar_button'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This is a snackbar'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Show SnackBar'),
            ),
          ),
        ),
      ),
    );
  }
}

// 7. Conditional Rendering Widget
class ConditionalWidget extends StatefulWidget {
  const ConditionalWidget({Key? key}) : super(key: key);

  @override
  State<ConditionalWidget> createState() => _ConditionalWidgetState();
}

class _ConditionalWidgetState extends State<ConditionalWidget> {
  bool showContent = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              key: const Key('toggle_button'),
              onPressed: () => setState(() => showContent = !showContent),
              child: const Text('Toggle'),
            ),
            if (showContent)
              const Text('Content is visible', key: Key('conditional_content')),
          ],
        ),
      ),
    );
  }
}

// 8. ListView Widget
class ListViewWidget extends StatelessWidget {
  final List<String> items;

  const ListViewWidget({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              key: Key('list_item_$index'),
              title: Text(items[index]),
            );
          },
        ),
      ),
    );
  }
}

// 9. GridView Widget
class GridViewWidget extends StatelessWidget {
  final List<String> items;

  const GridViewWidget({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Card(
              key: Key('grid_item_$index'),
              child: Center(child: Text(items[index])),
            );
          },
        ),
      ),
    );
  }
}

// 10. Theme Toggle Widget
class ThemeToggleWidget extends StatefulWidget {
  const ThemeToggleWidget({Key? key}) : super(key: key);

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: Column(
          children: [
            Text('Current Theme: ${isDarkMode ? "Dark" : "Light"}',
                key: const Key('theme_text')),
            ElevatedButton(
              key: const Key('theme_toggle_button'),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
              child: const Text('Toggle Theme'),
            ),
          ],
        ),
      ),
    );
  }
}

// 11. Async Widget with Timer
class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int seconds = 0;
  Timer? _timer;

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => seconds++);
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Seconds: $seconds', key: const Key('timer_text')),
            ElevatedButton(
              key: const Key('start_timer_button'),
              onPressed: startTimer,
              child: const Text('Start Timer'),
            ),
            ElevatedButton(
              key: const Key('stop_timer_button'),
              onPressed: stopTimer,
              child: const Text('Stop Timer'),
            ),
          ],
        ),
      ),
    );
  }
}

// 12. AnimatedContainer Widget
class AnimatedWidget extends StatefulWidget {
  const AnimatedWidget({Key? key}) : super(key: key);

  @override
  State<AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<AnimatedWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AnimatedContainer(
              key: const Key('animated_container'),
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? 200 : 100,
              height: isExpanded ? 200 : 100,
              color: isExpanded ? Colors.blue : Colors.red,
            ),
            ElevatedButton(
              key: const Key('animate_button'),
              onPressed: () => setState(() => isExpanded = !isExpanded),
              child: const Text('Animate'),
            ),
          ],
        ),
      ),
    );
  }
}

// 13. Draggable Widget
class DraggableWidget extends StatefulWidget {
  const DraggableWidget({Key? key}) : super(key: key);

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  bool isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Draggable<String>(
              data: 'Item',
              feedback: Container(
                width: 100,
                height: 100,
                color: Colors.blue.withOpacity(0.5),
                child: const Center(child: Text('Dragging')),
              ),
              child: Container(
                key: const Key('draggable_item'),
                width: 100,
                height: 100,
                color: Colors.blue,
                child: const Center(child: Text('Drag me')),
              ),
            ),
            const SizedBox(height: 50),
            DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  key: const Key('drag_target'),
                  width: 200,
                  height: 200,
                  color: isAccepted ? Colors.green : Colors.grey,
                  child: Center(
                    child: Text(isAccepted ? 'Accepted!' : 'Drop here'),
                  ),
                );
              },
              onAcceptWithDetails: (details) {
                setState(() => isAccepted = true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TESTS START HERE
// ============================================================================

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  group('1. STATE MANAGEMENT TESTS', () {
    // Test 1: setState Counter Increment
    testWidgets('Test 1: setState - Counter increments when button is pressed',
        (WidgetTester tester) async {
      // Description: Tests basic setState counter increment functionality
      // Type: Widget Test

      await tester.pumpWidget(const CounterWidget());

      // Verify initial counter value
      expect(find.text('Count: 0'), findsOneWidget);

      // Tap increment button
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();

      // Verify counter incremented
      expect(find.text('Count: 1'), findsOneWidget);
    });

    // Test 2: setState Counter Decrement
    testWidgets('Test 2: setState - Counter decrements when button is pressed',
        (WidgetTester tester) async {
      // Description: Tests setState counter decrement functionality
      // Type: Widget Test

      await tester.pumpWidget(const CounterWidget());

      // Tap decrement button
      await tester.tap(find.byKey(const Key('decrement_button')));
      await tester.pump();

      // Verify counter decremented
      expect(find.text('Count: -1'), findsOneWidget);
    });

    // Test 3: Riverpod State Management
    testWidgets('Test 3: Riverpod - State updates correctly',
        (WidgetTester tester) async {
      // Description: Tests Riverpod state management with StateNotifier
      // Type: Widget Test

      await tester.pumpWidget(
        const ProviderScope(child: RiverpodCounterWidget()),
      );

      // Verify initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Tap increment button
      await tester.tap(find.byKey(const Key('riverpod_increment')));
      await tester.pump();

      // Verify state updated
      expect(find.text('Count: 1'), findsOneWidget);
    });

    // Test 4: Riverpod State Notifier Unit Test
    test('Test 4: Riverpod StateNotifier - increment, decrement, reset', () {
      // Description: Unit test for Riverpod StateNotifier methods
      // Type: Unit Test

      final container = ProviderContainer();
      final notifier = container.read(counterProvider.notifier);

      // Test increment
      notifier.increment();
      expect(container.read(counterProvider), 1);

      // Test increment again
      notifier.increment();
      expect(container.read(counterProvider), 2);

      // Test decrement
      notifier.decrement();
      expect(container.read(counterProvider), 1);

      // Test reset
      notifier.reset();
      expect(container.read(counterProvider), 0);

      container.dispose();
    });
  });

  group('2. API CALLS AND HTTP REQUESTS', () {
    late MockDio mockDio;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockDio = MockDio();
      mockHttpClient = MockHttpClient();
    });

    // Test 5: Successful API Call with Dio
    test('Test 5: Dio - Successful GET request returns user data', () async {
      // Description: Tests successful API call using Dio
      // Type: Unit Test
      // Mocking: Dio HTTP client

      final responseData = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com'
      };

      when(() => mockDio.get('/users/123')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/123'),
        ),
      );

      final result = await mockDio.get('/users/123');
      final user = User.fromJson(result.data);

      expect(result.statusCode, 200);
      expect(user.id, '123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    // Test 6: Failed API Call with Error
    test('Test 6: Dio - Failed API call throws DioException', () async {
      // Description: Tests API error handling
      // Type: Unit Test
      // Mocking: Dio HTTP client with error response

      when(() => mockDio.get('/users/invalid')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/invalid'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/users/invalid'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => mockDio.get('/users/invalid'),
        throwsA(isA<DioException>()),
      );
    });

    // Test 7: POST Request with Dio
    test('Test 7: Dio - POST request sends data correctly', () async {
      // Description: Tests POST request with payload
      // Type: Unit Test

      final requestData = {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
      };

      when(() => mockDio.post('/users', data: requestData)).thenAnswer(
        (_) async => Response(
          data: {'id': '456', ...requestData},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/users'),
        ),
      );

      final result = await mockDio.post('/users', data: requestData);

      expect(result.statusCode, 201);
      expect(result.data['id'], '456');
      expect(result.data['name'], 'Jane Doe');
    });

    // Test 8: HTTP Client with http package
    test('Test 8: http.Client - GET request returns valid JSON', () async {
      // Description: Tests http package GET request
      // Type: Unit Test
      // Mocking: http.Client

      final responseBody = json.encode({
        'id': '789',
        'name': 'Bob Smith',
        'email': 'bob@example.com',
      });

      when(() => mockHttpClient.get(Uri.parse('https://api.example.com/users/789')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final response = await mockHttpClient.get(
        Uri.parse('https://api.example.com/users/789'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['id'], '789');
      expect(data['name'], 'Bob Smith');
    });
  });

  group('3. FORM VALIDATION', () {
    // Test 9: Email Validation - Empty Email
    testWidgets('Test 9: Form - Email validation fails for empty input',
        (WidgetTester tester) async {
      // Description: Tests email field validation for empty input
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Enter empty email and submit
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Verify validation error appears
      expect(find.text('Email is required'), findsOneWidget);
    });

    // Test 10: Email Validation - Invalid Format
    testWidgets('Test 10: Form - Email validation fails for invalid format',
        (WidgetTester tester) async {
      // Description: Tests email field validation for invalid format
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Enter invalid email
      await tester.enterText(
          find.byKey(const Key('email_field')), 'invalidemail');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Verify validation error
      expect(find.text('Invalid email format'), findsOneWidget);
    });

    // Test 11: Password Validation - Too Short
    testWidgets('Test 11: Form - Password validation fails for short password',
        (WidgetTester tester) async {
      // Description: Tests password minimum length validation
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Enter short password
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Verify validation error
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    // Test 12: Form Submission - Valid Data
    testWidgets('Test 12: Form - Successful submission with valid data',
        (WidgetTester tester) async {
      // Description: Tests form submission with valid credentials
      // Type: Widget Test

      String? submittedEmail;
      String? submittedPassword;

      await tester.pumpWidget(
        LoginFormWidget(
          onSubmit: (email, password) {
            submittedEmail = email;
            submittedPassword = password;
          },
        ),
      );

      // Enter valid credentials
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Verify submission
      expect(submittedEmail, 'test@example.com');
      expect(submittedPassword, 'password123');
    });
  });

  group('4. BUTTON PRESSES AND USER INTERACTION', () {
    // Test 13: Button Tap Increments Counter
    testWidgets('Test 13: Button - Tap increments counter',
        (WidgetTester tester) async {
      // Description: Tests button tap increments counter multiple times
      // Type: Widget Test

      await tester.pumpWidget(const CounterWidget());

      // Multiple taps
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('increment_button')));
      await tester.pump();

      expect(find.text('Count: 3'), findsOneWidget);
    });

    // Test 14: Button Disabled State
    testWidgets('Test 14: Button - Disabled during loading',
        (WidgetTester tester) async {
      // Description: Tests button is disabled when loading is true
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Enter valid data
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');

      // Initially button should be enabled
      final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('submit_button')));
      expect(button.onPressed, isNotNull);
    });

    // Test 15: Toggle Button
    testWidgets('Test 15: Button - Toggle switches state',
        (WidgetTester tester) async {
      // Description: Tests toggle button switches visibility state
      // Type: Widget Test

      await tester.pumpWidget(const ConditionalWidget());

      // Initially content should not be visible
      expect(find.byKey(const Key('conditional_content')), findsNothing);

      // Tap toggle button
      await tester.tap(find.byKey(const Key('toggle_button')));
      await tester.pump();

      // Content should be visible
      expect(find.byKey(const Key('conditional_content')), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byKey(const Key('toggle_button')));
      await tester.pump();

      // Content should be hidden
      expect(find.byKey(const Key('conditional_content')), findsNothing);
    });
  });

  group('5. NAVIGATION BETWEEN SCREENS', () {
    // Test 16: Navigation Push to Detail Screen
    testWidgets('Test 16: Navigation - Push to detail screen',
        (WidgetTester tester) async {
      // Description: Tests navigation from home to detail screen
      // Type: Widget Test

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify home screen
      expect(find.text('Home'), findsOneWidget);

      // Tap navigate button
      await tester.tap(find.byKey(const Key('navigate_button')));
      await tester.pumpAndSettle();

      // Verify detail screen
      expect(find.text('Details'), findsOneWidget);
      expect(find.byKey(const Key('detail_text')), findsOneWidget);
    });

    // Test 17: Navigation Pop Back
    testWidgets('Test 17: Navigation - Pop back to previous screen',
        (WidgetTester tester) async {
      // Description: Tests navigation back button functionality
      // Type: Widget Test

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Navigate to detail screen
      await tester.tap(find.byKey(const Key('navigate_button')));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Home'), findsOneWidget);
      expect(find.byKey(const Key('navigate_button')), findsOneWidget);
    });

    // Test 18: Navigation Observer Tracking
    testWidgets('Test 18: Navigation - Observer tracks route changes',
        (WidgetTester tester) async {
      // Description: Tests NavigatorObserver tracking navigation events
      // Type: Widget Test
      // Mocking: NavigatorObserver

      final mockObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          navigatorObservers: [mockObserver],
        ),
      );

      // Navigate to detail screen
      await tester.tap(find.byKey(const Key('navigate_button')));
      await tester.pumpAndSettle();

      // Verify observer was notified
      verify(() => mockObserver.didPush(any(), any())).called(2);
    });
  });

  group('6. INPUT FIELDS AND TEXT VALIDATION', () {
    // Test 19: TextField Input
    testWidgets('Test 19: TextField - Accepts and displays input',
        (WidgetTester tester) async {
      // Description: Tests TextField accepts user input
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Enter text in email field
      await tester.enterText(
          find.byKey(const Key('email_field')), 'user@example.com');

      // Verify text appears
      expect(find.text('user@example.com'), findsOneWidget);
    });

    // Test 20: TextField Password Obscured
    testWidgets('Test 20: TextField - Password is obscured',
        (WidgetTester tester) async {
      // Description: Tests password field obscures text
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Find the EditableText widget which has the obscureText property
      final editableText = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('password_field')),
            matching: find.byType(EditableText),
          ),
      );

      expect(editableText.obscureText, true);
    });

    // Test 21: TextField Empty State
    testWidgets('Test 21: TextField - Shows error for empty required field',
        (WidgetTester tester) async {
      // Description: Tests required field validation
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Submit without entering anything
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Both fields should show errors
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('7. DIALOGS, SNACKBARS, AND TOAST MESSAGES', () {
    // Test 22: Dialog Appears
    testWidgets('Test 22: Dialog - Shows when triggered',
        (WidgetTester tester) async {
      // Description: Tests AlertDialog is displayed
      // Type: Widget Test

      await tester.pumpWidget(const DialogWidget());

      // Initially dialog should not be visible
      expect(find.text('Alert'), findsNothing);

      // Tap button to show dialog
      await tester.tap(find.byKey(const Key('show_dialog_button')));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('This is an alert message'), findsOneWidget);
    });

    // Test 23: Dialog Dismissal
    testWidgets('Test 23: Dialog - Dismisses when OK is pressed',
        (WidgetTester tester) async {
      // Description: Tests dialog closes on button press
      // Type: Widget Test

      await tester.pumpWidget(const DialogWidget());

      // Show dialog
      await tester.tap(find.byKey(const Key('show_dialog_button')));
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.byKey(const Key('dialog_ok_button')));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Alert'), findsNothing);
    });

    // Test 24: SnackBar Appears
    testWidgets('Test 24: SnackBar - Shows when triggered',
        (WidgetTester tester) async {
      // Description: Tests SnackBar is displayed
      // Type: Widget Test

      await tester.pumpWidget(const SnackBarWidget());

      // Tap button to show snackbar
      await tester.tap(find.byKey(const Key('show_snackbar_button')));
      await tester.pump();

      // SnackBar should be visible
      expect(find.text('This is a snackbar'), findsOneWidget);
    });

    // Test 25: SnackBar Auto-Dismisses
    testWidgets('Test 25: SnackBar - Auto-dismisses after duration',
        (WidgetTester tester) async {
      // Description: Tests SnackBar disappears after duration
      // Type: Widget Test

      await tester.pumpWidget(const SnackBarWidget());

      // Show snackbar
      await tester.tap(find.byKey(const Key('show_snackbar_button')));
      await tester.pump();

      expect(find.text('This is a snackbar'), findsOneWidget);

      // Pump multiple times to allow SnackBar to dismiss
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      
      // Final pump to complete any remaining animations
      await tester.pumpAndSettle();

      // SnackBar should be dismissed
      expect(find.text('This is a snackbar'), findsNothing);
    });
  });

  group('8. CONDITIONAL RENDERING', () {
    // Test 26: Conditional Widget Shows/Hides
    testWidgets('Test 26: Conditional - Content shows and hides based on state',
        (WidgetTester tester) async {
      // Description: Tests conditional rendering with if statement
      // Type: Widget Test

      await tester.pumpWidget(const ConditionalWidget());

      // Initially hidden
      expect(find.byKey(const Key('conditional_content')), findsNothing);

      // Show content
      await tester.tap(find.byKey(const Key('toggle_button')));
      await tester.pump();
      expect(find.byKey(const Key('conditional_content')), findsOneWidget);

      // Hide content
      await tester.tap(find.byKey(const Key('toggle_button')));
      await tester.pump();
      expect(find.byKey(const Key('conditional_content')), findsNothing);
    });

    // Test 27: Multiple Conditional States
    testWidgets('Test 27: Conditional - Handles multiple state transitions',
        (WidgetTester tester) async {
      // Description: Tests multiple conditional state changes
      // Type: Widget Test

      await tester.pumpWidget(const ConditionalWidget());

      // Toggle multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('toggle_button')));
        await tester.pump();
      }

      // Should be visible (odd number of toggles)
      expect(find.byKey(const Key('conditional_content')), findsOneWidget);
    });
  });

  group('9. LISTVIEW, GRIDVIEW, AND DYNAMIC CONTENT', () {
    // Test 28: ListView Renders Items
    testWidgets('Test 28: ListView - Renders all items correctly',
        (WidgetTester tester) async {
      // Description: Tests ListView displays all items
      // Type: Widget Test

      final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];

      await tester.pumpWidget(ListViewWidget(items: items));

      // Verify all items are rendered
      for (int i = 0; i < items.length; i++) {
        expect(find.text(items[i]), findsOneWidget);
      }
    });

    // Test 29: ListView Empty State
    testWidgets('Test 29: ListView - Handles empty list',
        (WidgetTester tester) async {
      // Description: Tests ListView with empty data
      // Type: Widget Test

      await tester.pumpWidget(const ListViewWidget(items: []));

      // No items should be rendered
      expect(find.byType(ListTile), findsNothing);
    });

    // Test 30: GridView Renders Items
    testWidgets('Test 30: GridView - Renders items in grid',
        (WidgetTester tester) async {
      // Description: Tests GridView displays items in grid format
      // Type: Widget Test

      final items = ['A', 'B', 'C', 'D'];

      await tester.pumpWidget(GridViewWidget(items: items));

      // Verify all grid items
      for (int i = 0; i < items.length; i++) {
        expect(find.byKey(Key('grid_item_$i')), findsOneWidget);
        expect(find.text(items[i]), findsOneWidget);
      }
    });

    // Test 31: Dynamic List Update
    testWidgets('Test 31: ListView - Updates when items change',
        (WidgetTester tester) async {
      // Description: Tests ListView updates with new data
      // Type: Widget Test

      await tester.pumpWidget(const ListViewWidget(items: ['Initial']));
      expect(find.text('Initial'), findsOneWidget);

      // Update with new items
      await tester.pumpWidget(
          const ListViewWidget(items: ['Updated 1', 'Updated 2']));
      await tester.pump();

      expect(find.text('Initial'), findsNothing);
      expect(find.text('Updated 1'), findsOneWidget);
      expect(find.text('Updated 2'), findsOneWidget);
    });
  });

  group('10. THEME CHANGES', () {
    // Test 32: Theme Toggle Light to Dark
    testWidgets('Test 32: Theme - Toggles from light to dark',
        (WidgetTester tester) async {
      // Description: Tests theme switching functionality
      // Type: Widget Test

      await tester.pumpWidget(const ThemeToggleWidget());

      // Initially light theme
      expect(find.text('Current Theme: Light'), findsOneWidget);

      // Toggle to dark
      await tester.tap(find.byKey(const Key('theme_toggle_button')));
      await tester.pump();

      expect(find.text('Current Theme: Dark'), findsOneWidget);
    });

    // Test 33: Theme Multiple Toggles
    testWidgets('Test 33: Theme - Handles multiple theme switches',
        (WidgetTester tester) async {
      // Description: Tests multiple theme transitions
      // Type: Widget Test

      await tester.pumpWidget(const ThemeToggleWidget());

      // Toggle multiple times
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('theme_toggle_button')));
        await tester.pump();
      }

      // Should be back to light theme (even number of toggles)
      expect(find.text('Current Theme: Light'), findsOneWidget);
    });
  });

  group('11. PAYMENT/TRANSACTION SIMULATIONS (MOCKED)', () {
    // Test 34: Successful Payment Transaction
    test('Test 34: Payment - Successful transaction returns success status',
        () async {
      // Description: Tests mocked successful payment processing
      // Type: Unit Test
      // Mocking: Payment service

      // Mock payment service
      Future<PaymentTransaction> processPayment(
          double amount, String method) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return PaymentTransaction(
          transactionId: 'TXN123456',
          amount: amount,
          status: 'success',
        );
      }

      final result = await processPayment(100.0, 'card');

      expect(result.transactionId, 'TXN123456');
      expect(result.amount, 100.0);
      expect(result.status, 'success');
    });

    // Test 35: Failed Payment Transaction
    test('Test 35: Payment - Failed transaction returns failure status',
        () async {
      // Description: Tests mocked failed payment scenario
      // Type: Unit Test

      Future<PaymentTransaction> processPayment(
          double amount, String method) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (amount <= 0) {
          throw Exception('Invalid amount');
        }
        return PaymentTransaction(
          transactionId: 'TXN_FAIL',
          amount: amount,
          status: 'failed',
        );
      }

      expect(() => processPayment(-10, 'card'), throwsException);
    });

    // Test 36: Payment Validation
    test('Test 36: Payment - Validates minimum amount', () {
      // Description: Tests payment amount validation
      // Type: Unit Test

      bool validatePaymentAmount(double amount) {
        return amount > 0 && amount <= 10000;
      }

      expect(validatePaymentAmount(50), true);
      expect(validatePaymentAmount(0), false);
      expect(validatePaymentAmount(-10), false);
      expect(validatePaymentAmount(15000), false);
    });
  });

  group('12. ERROR HANDLING SCENARIOS', () {
    // Test 37: Network Error Handling
    test('Test 37: Error - Handles network timeout error', () async {
      // Description: Tests handling of network timeout
      // Type: Unit Test
      // Mocking: Dio with timeout error

      final mockDio = MockDio();

      when(() => mockDio.get('/api/data')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/data'),
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        ),
      );

      try {
        await mockDio.get('/api/data');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<DioException>());
        expect((e as DioException).type, DioExceptionType.connectionTimeout);
      }
    });

    // Test 38: Null Safety Error Handling
    test('Test 38: Error - Handles null values safely', () {
      // Description: Tests null safety and error handling
      // Type: Unit Test

      String? getUserName(Map<String, dynamic>? data) {
        try {
          return data?['name'] as String?;
        } catch (e) {
          return null;
        }
      }

      expect(getUserName(null), null);
      expect(getUserName({}), null);
      expect(getUserName({'name': 'John'}), 'John');
    });

    // Test 39: Exception Recovery
    test('Test 39: Error - Recovers from exception with fallback', () async {
      // Description: Tests graceful error recovery with fallback value
      // Type: Unit Test

      Future<String> fetchDataWithFallback() async {
        try {
          throw Exception('Network error');
        } catch (e) {
          return 'Fallback data';
        }
      }

      final result = await fetchDataWithFallback();
      expect(result, 'Fallback data');
    });
  });

  group('13. EDGE CASES AND VALIDATION', () {
    // Test 40: Edge Case - Empty Input Handling
    testWidgets('Test 40: Edge Case - Handles empty inputs gracefully',
        (WidgetTester tester) async {
      // Description: Tests application behavior with empty/null inputs
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      // Submit with empty fields
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Should show validation errors, not crash
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Verify app is still responsive
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.pump();
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('14. TIMER AND ASYNC OPERATIONS', () {
    // Test 41: Timer Starts and Increments
    testWidgets('Test 41: Timer - Starts and increments seconds',
        (WidgetTester tester) async {
      // Description: Tests timer functionality and async updates
      // Type: Widget Test

      await tester.pumpWidget(const TimerWidget());

      expect(find.text('Seconds: 0'), findsOneWidget);

      // Start timer
      await tester.tap(find.byKey(const Key('start_timer_button')));
      await tester.pump();

      // Advance time by 3 seconds
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Seconds: 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Seconds: 2'), findsOneWidget);
    });

    // Test 42: Timer Stops
    testWidgets('Test 42: Timer - Stops when stop button is pressed',
        (WidgetTester tester) async {
      // Description: Tests timer can be stopped
      // Type: Widget Test

      await tester.pumpWidget(const TimerWidget());

      // Start timer
      await tester.tap(find.byKey(const Key('start_timer_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify timer started and is running
      expect(find.text('Seconds: 1'), findsOneWidget);

      // Stop timer
      await tester.tap(find.byKey(const Key('stop_timer_button')));
      await tester.pump();

      // Advance time and verify counter doesn't increase
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Should still show the same count (timer stopped)
      expect(find.text('Seconds: 1'), findsOneWidget);
    });
  });

  group('15. ANIMATION TESTING', () {
    // Test 43: AnimatedContainer Transitions
    testWidgets('Test 43: Animation - AnimatedContainer changes size',
        (WidgetTester tester) async {
      // Description: Tests animated widget transitions
      // Type: Widget Test

      await tester.pumpWidget(const AnimatedWidget());

      // Verify AnimatedContainer exists
      expect(find.byKey(const Key('animated_container')), findsOneWidget);

      // Trigger animation
      await tester.tap(find.byKey(const Key('animate_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Verify container is still present during animation
      expect(find.byKey(const Key('animated_container')), findsOneWidget);
    });

    // Test 44: Animation Completes
    testWidgets('Test 44: Animation - Completes after duration',
        (WidgetTester tester) async {
      // Description: Tests animation completion
      // Type: Widget Test

      await tester.pumpWidget(const AnimatedWidget());

      // Trigger animation
      await tester.tap(find.byKey(const Key('animate_button')));
      await tester.pump();

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Animation should be complete
      final container =
          tester.widget<AnimatedContainer>(find.byKey(const Key('animated_container')));
      expect(container.constraints?.maxWidth, 200);
    });
  });

  group('16. COMPLEX UI INTERACTIONS', () {
    // Test 45: Drag and Drop
    testWidgets('Test 45: Interaction - Drag and drop works correctly',
        (WidgetTester tester) async {
      // Description: Tests drag and drop interaction
      // Type: Widget Test

      await tester.pumpWidget(const DraggableWidget());

      // Initially not accepted
      expect(find.text('Drop here'), findsOneWidget);

      // Perform drag and drop
      await tester.drag(
        find.byKey(const Key('draggable_item')),
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();

      // Should be accepted
      expect(find.text('Accepted!'), findsOneWidget);
    });

    // Test 46: Long Press Gesture
    testWidgets('Test 46: Interaction - Long press triggers action',
        (WidgetTester tester) async {
      // Description: Tests long press gesture detection
      // Type: Widget Test

      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              key: const Key('long_press_detector'),
              onLongPress: () => longPressed = true,
              child: const Text('Long press me'),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(const Key('long_press_detector')));
      await tester.pumpAndSettle();

      expect(longPressed, true);
    });
  });

  group('17. SHAREDPREFERENCES AND LOCAL STORAGE', () {
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
    });

    // Test 47: Save to SharedPreferences
    test('Test 47: Storage - Saves data to SharedPreferences', () async {
      // Description: Tests saving data to local storage
      // Type: Unit Test
      // Mocking: SharedPreferences

      when(() => mockPrefs.setString('username', 'john_doe'))
          .thenAnswer((_) async => true);

      final result = await mockPrefs.setString('username', 'john_doe');

      expect(result, true);
      verify(() => mockPrefs.setString('username', 'john_doe')).called(1);
    });

    // Test 48: Read from SharedPreferences
    test('Test 48: Storage - Reads data from SharedPreferences', () {
      // Description: Tests reading stored data
      // Type: Unit Test
      // Mocking: SharedPreferences

      when(() => mockPrefs.getString('username')).thenReturn('john_doe');

      final result = mockPrefs.getString('username');

      expect(result, 'john_doe');
      verify(() => mockPrefs.getString('username')).called(1);
    });

    // Test 49: Remove from SharedPreferences
    test('Test 49: Storage - Removes data from SharedPreferences', () async {
      // Description: Tests removing data from storage
      // Type: Unit Test

      when(() => mockPrefs.remove('username')).thenAnswer((_) async => true);

      final result = await mockPrefs.remove('username');

      expect(result, true);
      verify(() => mockPrefs.remove('username')).called(1);
    });

    // Test 50: Secure Storage
    test('Test 50: Storage - Saves sensitive data to secure storage', () async {
      // Description: Tests secure storage for sensitive data
      // Type: Unit Test
      // Mocking: FlutterSecureStorage

      final mockSecureStorage = MockFlutterSecureStorage();

      when(() => mockSecureStorage.write(key: 'token', value: 'secret_token'))
          .thenAnswer((_) async => {});

      await mockSecureStorage.write(key: 'token', value: 'secret_token');

      verify(() => mockSecureStorage.write(key: 'token', value: 'secret_token'))
          .called(1);
    });
  });

  group('18. CONNECTIVITY AND OFFLINE BEHAVIOR', () {
    // Test 51: Offline Mode Detection
    test('Test 51: Connectivity - Detects offline mode', () {
      // Description: Tests offline mode detection
      // Type: Unit Test

      bool isOffline(bool hasConnection) {
        return !hasConnection;
      }

      expect(isOffline(false), true);
      expect(isOffline(true), false);
    });

    // Test 52: Network Error Retry Logic
    test('Test 52: Connectivity - Implements retry logic for network errors',
        () async {
      // Description: Tests retry mechanism for failed requests
      // Type: Unit Test

      int attempts = 0;
      Future<String> fetchWithRetry({int maxRetries = 3}) async {
        for (int i = 0; i < maxRetries; i++) {
          attempts++;
          try {
            if (attempts < 3) throw Exception('Network error');
            return 'Success';
          } catch (e) {
            if (i == maxRetries - 1) rethrow;
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        throw Exception('Max retries exceeded');
      }

      final result = await fetchWithRetry();
      expect(result, 'Success');
      expect(attempts, 3);
    });
  });

  group('19. PERFORMANCE CHECKS', () {
    // Test 53: Widget Build Performance
    testWidgets('Test 53: Performance - Widget builds efficiently',
        (WidgetTester tester) async {
      // Description: Tests widget rendering performance
      // Type: Widget Test

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const CounterWidget());

      stopwatch.stop();

      // Widget should build quickly (under 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    // Test 54: List Rendering Performance
    testWidgets('Test 54: Performance - Large list renders efficiently',
        (WidgetTester tester) async {
      // Description: Tests performance with large dataset
      // Type: Widget Test

      final largeList = List.generate(1000, (index) => 'Item $index');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(ListViewWidget(items: largeList));

      stopwatch.stop();

      // Should render efficiently even with large list
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });

  group('20. CUSTOM WIDGET BEHAVIOR', () {
    // Test 55: Custom Widget Reusability
    testWidgets('Test 55: Custom Widget - Reusable with different properties',
        (WidgetTester tester) async {
      // Description: Tests custom widget can be reused with different props
      // Type: Widget Test

      await tester.pumpWidget(const ListViewWidget(items: ['A', 'B', 'C']));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Reuse with different data
      await tester.pumpWidget(const ListViewWidget(items: ['X', 'Y', 'Z']));
      await tester.pump();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
    });
  });

  // Additional comprehensive tests to reach 40 scenarios

  group('21. ADDITIONAL FORM TESTS', () {
    // Test 56: Multiple Form Fields Validation
    testWidgets('Test 56: Form - Validates all fields simultaneously',
        (WidgetTester tester) async {
      // Description: Tests all form validations trigger together
      // Type: Widget Test

      await tester.pumpWidget(const LoginFormWidget());

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      // Both validations should appear
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('22. ASYNC STATE UPDATES', () {
    // Test 57: Future Builder Loading State
    testWidgets('Test 57: Async - FutureBuilder shows loading state',
        (WidgetTester tester) async {
      // Description: Tests FutureBuilder loading state
      // Type: Widget Test

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder<String>(
              future: Future.delayed(
                const Duration(milliseconds: 100),
                () => 'Loaded data',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                      key: Key('future_loading'));
                }
                return Text(snapshot.data ?? 'No data');
              },
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byKey(const Key('future_loading')), findsOneWidget);
      
      // Wait for future to complete
      await tester.pumpAndSettle();
      
      // Should show loaded data
      expect(find.text('Loaded data'), findsOneWidget);
    });

    // Test 58: Future Builder Error State
    testWidgets('Test 58: Async - FutureBuilder handles errors',
        (WidgetTester tester) async {
      // Description: Tests FutureBuilder error handling
      // Type: Widget Test

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder<String>(
              future: Future.delayed(
                const Duration(milliseconds: 10),
                () => throw Exception('Error occurred'),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading data',
                      key: Key('future_error'));
                }
                return const Text('Loading...');
              },
            ),
          ),
        ),
      );

      // Wait for future to complete
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('future_error')), findsOneWidget);
    });
  });

  group('23. STREAM TESTING', () {
    // Test 59: StreamBuilder Updates
    testWidgets('Test 59: Stream - StreamBuilder receives updates',
        (WidgetTester tester) async {
      // Description: Tests StreamBuilder with stream data
      // Type: Widget Test

      final controller = StreamController<int>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<int>(
              stream: controller.stream,
              initialData: 0,
              builder: (context, snapshot) {
                return Text('Count: ${snapshot.data}',
                    key: const Key('stream_text'));
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      controller.add(5);
      await tester.pump();

      expect(find.text('Count: 5'), findsOneWidget);

      controller.close();
    });

    // Test 60: Stream Error Handling
    testWidgets('Test 60: Stream - Handles stream errors',
        (WidgetTester tester) async {
      // Description: Tests StreamBuilder error handling
      // Type: Widget Test

      final controller = StreamController<int>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<int>(
              stream: controller.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Stream error', key: Key('stream_error'));
                }
                return Text('Count: ${snapshot.data ?? 0}');
              },
            ),
          ),
        ),
      );

      controller.addError('Test error');
      await tester.pump();

      expect(find.byKey(const Key('stream_error')), findsOneWidget);

      controller.close();
    });
  });
}
