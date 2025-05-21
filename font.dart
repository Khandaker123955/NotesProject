import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchNotes() async {
  try {
    // Use Uri.parse for the URL
    final Uri url = Uri.parse('https://example.com/api/notes');

    // Make the GET request
    final http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      // Decode the JSON response
      final List<dynamic> notes = jsonDecode(response.body);
      print('Notes fetched successfully: $notes');
      // Process notes as needed
    } else {
      print('Failed to fetch notes. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching notes: $e');
  }
}
