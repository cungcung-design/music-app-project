import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import 'user_detail_page.dart';
import '../../utils/toast.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.black, // DARK BACKGROUND
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Profile>>(
          future: db.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return Card(
                  color: Colors.grey[850], // DARK CARD
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    onTap: () {
                      // Navigate to user detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(user: user),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // Navigate to edit page (you can create an EditUserPage)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailPage(user: user),
                            ),
                          );
                        } else if (value == 'delete') {
                          try {
                            await db.deleteUser(user.id);
                            showToast(context, 'User deleted successfully');
                            // Force rebuild
                            (context as Element).reassemble();
                          } catch (e) {
                            showToast(context, 'Failed to delete user: $e',
                                isError: true);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
