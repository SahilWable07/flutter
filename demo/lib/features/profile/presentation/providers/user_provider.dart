import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final userInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final url = Uri.parse('https://platform-development-dev.157.20.214.214.nip.io/auth/api/users/client/6be12980-7f17-45eb-a845-242ea806eaf1/user/afa1c7bd-9c1e-4f5c-8331-eeca29a586c1');
  
  final response = await http.get(
    url,
    headers: {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWZhMWM3YmQtOWMxZS00ZjVjLTgzMzEtZWVjYTI5YTU4NmMxIiwidXNlcl90eXBlIjoiQWRtaW4iLCJjbGllbnRzIjp7IjlkMTkyMmUwLTE3NmItNGZlNy1iNzNmLTU3Y2I2MmIyYTQ5YSI6ImExOTgwNjkxLWE1MmUtNDAxNC1hNDc3LTU1OWExZjdhYWJiNCIsImZlYzk4ZDQwLWIzNjEtNDU5ZS05N2RlLWU5Y2EyYmQwMjM5ZSI6ImExOTgwNjkxLWE1MmUtNDAxNC1hNDc3LTU1OWExZjdhYWJiNCIsImEzZWExY2RhLWM3MzUtNDc5OC04MjE5LTU0YmJiMDc3OTVhOSI6IjYyY2U3Y2JiLTU5MDctNGYyNy05NDkwLWQwYjY2MmZiZjU2NiIsIjZiZTEyOTgwLTdmMTctNDVlYi1hODQ1LTI0MmVhODA2ZWFmMSI6ImU0NjYyMzE5LWIyYzItNGQ0OS1hMTc5LWIzMTM0OGU2NjFlNyJ9LCJ0b2tlbl92ZXJzaW9uIjowLCJpYXQiOjE3NzUyMTE2MjIsImV4cCI6MTc3NTI5ODAyMn0.YklMlnCHP_fwszvFz4iAPGTyI5LWFIED6Ii3htis9dE',
      'Connection': 'keep-alive',
      'Origin': 'https://development.d3kq8oy4csoq2n.amplifyapp.com',
      'Referer': 'https://development.d3kq8oy4csoq2n.amplifyapp.com/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'cross-site',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['user'];
  } else {
    throw Exception('Failed to load user info');
  }
});
