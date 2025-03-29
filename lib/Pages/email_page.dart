import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  List<gmail.Message> _emails = [];
  bool _isLoading = true;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/gmail.readonly'],
    clientId:
        '440107397512-1a5io0viggvaplfli9chd4ebj420l26b.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _handleSignIn();
  }

  Future<void> _handleSignIn() async {
    try {
      print('Starting Google Sign-In...');
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign-in canceled by user.")),
          );
        }
        return;
      }
      print('Sign-in successful: ${account.email}');
      await _fetchEmails(account);
    } on PlatformException catch (e) {
      print(
          'Sign-in failed: Code: ${e.code}, Message: ${e.message}, Details: ${e.details}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Sign-in failed: ${e.message} (Code: ${e.code})")),
        );
      }
    } catch (error) {
      print('Unexpected error: $error');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in error: $error")),
        );
      }
    }
  }

  Future<void> _fetchEmails(GoogleSignInAccount account) async {
    try {
      final googleAuth = await account.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to get access token.")),
          );
        }
        return;
      }
      print('Access token: $accessToken');

      final client = http.Client();
      final authClient = auth.autoRefreshingClient(
        auth.ClientId(
            '440107397512-1a5io0viggvaplfli9chd4ebj420l26b.apps.googleusercontent.com',
            ''),
        auth.AccessCredentials(
          auth.AccessToken('Bearer', accessToken,
              DateTime.now().add(const Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/gmail.readonly'],
        ),
        client,
      );

      final gmailApi = gmail.GmailApi(authClient);
      final messages = await gmailApi.users.messages.list('me', maxResults: 10);
      if (messages.messages != null) {
        final emailList = <gmail.Message>[];
        for (var message in messages.messages!) {
          final fullMessage =
              await gmailApi.users.messages.get('me', message.id!);
          emailList.add(fullMessage);
        }
        if (mounted) {
          setState(() {
            _emails = emailList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      authClient.close();
    } catch (e) {
      print('Error fetching emails: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch emails: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emails"),
        backgroundColor: Colors.yellow.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emails.isEmpty
              ? const Center(child: Text("No emails found."))
              : ListView.builder(
                  itemCount: _emails.length,
                  itemBuilder: (context, index) {
                    final email = _emails[index];
                    final headers = email.payload?.headers ?? [];
                    final from = headers
                            .firstWhere(
                              (h) => h.name == 'From',
                              orElse: () =>
                                  gmail.MessagePartHeader()..value = 'Unknown',
                            )
                            .value ??
                        'Unknown';
                    final subject = headers
                            .firstWhere(
                              (h) => h.name == 'Subject',
                              orElse: () => gmail.MessagePartHeader()
                                ..value = 'No Subject',
                            )
                            .value ??
                        'No Subject';
                    return Card(
                      color: Colors.white,
                      elevation: 4,
                      child: ListTile(
                        title: Text(from,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(subject),
                        trailing: Text(
                          email.internalDate != null
                              ? DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(email.internalDate!))
                                  .toString()
                                  .substring(0, 10)
                              : '',
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
    );
  }
}
