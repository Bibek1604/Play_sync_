import 'package:flutter/material.dart';

class ThemeScreen extends StatefulWidget {
	const ThemeScreen({super.key});

	@override
	State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
	bool isDarkMode = false;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Theme Settings'),
				backgroundColor: const Color(0xFF2E7D32),
				foregroundColor: Colors.white,
			),
			body: Padding(
				padding: const EdgeInsets.all(24.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'Choose your theme:',
							style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 24),
						ListTile(
							leading: Icon(Icons.light_mode, color: Colors.amber[700]),
							title: const Text('Light Theme'),
							trailing: Radio<bool>(
								value: false,
								groupValue: isDarkMode,
								onChanged: (value) {
									setState(() {
										isDarkMode = value!;
									});
								},
							),
						),
						ListTile(
							leading: Icon(Icons.dark_mode, color: Colors.grey[800]),
							title: const Text('Dark Theme'),
							trailing: Radio<bool>(
								value: true,
								groupValue: isDarkMode,
								onChanged: (value) {
									setState(() {
										isDarkMode = value!;
									});
								},
							),
						),
						const SizedBox(height: 32),
						Center(
							child: ElevatedButton(
								style: ElevatedButton.styleFrom(
									backgroundColor: const Color(0xFF2E7D32),
									foregroundColor: Colors.white,
								),
								onPressed: () {
									// You can add logic here to apply the theme globally
									ScaffoldMessenger.of(context).showSnackBar(
										SnackBar(
											content: Text(isDarkMode ? 'Dark theme applied!' : 'Light theme applied!'),
										),
									);
								},
								child: const Text('Apply Theme'),
							),
						),
					],
				),
			),
		);
	}
}
