import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

/// Admin dashboard screen
///
/// This screen is **completely isolated** from the normal user dashboard.
/// It focuses purely on admin-level user management powers:
/// - List users with verificationStatus == "pending"
/// - Verify users (set verificationStatus = "verified")
/// - Reject users  (set verificationStatus = "rejected")
/// - Promote users to admin (set role = "admin")
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isProcessingAction = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentAdmin = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            // Navigation for admins is controlled by AuthWrapperScreen.
            // Popping simply returns to the previous route.
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Admin info header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentAdmin?.email ?? currentAdmin?.phone ?? 'Admin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Pending users list
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: UserService.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                        '[ERROR] [AdminDashboard] Failed to load users: ${snapshot.error}');
                    return _buildMessageState(
                      context,
                      title: 'Failed to load users',
                      message: 'Please check your connection and try again.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = snapshot.data ?? <UserModel>[];
                  // Filter users with verificationStatus == pending
                  final pendingUsers = allUsers
                      .where((u) => u.verificationStatus == VerificationStatus.pending)
                      .toList();

                  if (pendingUsers.isEmpty) {
                    return _buildMessageState(
                      context,
                      title: 'No pending users',
                      message:
                          'There are currently no users waiting for verification.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Stream will push updates automatically; delay for UX only.
                      await Future.delayed(const Duration(milliseconds: 300));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: pendingUsers.length,
                      itemBuilder: (context, index) {
                        final user = pendingUsers[index];
                        return _buildUserCard(context, user);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (user.name ?? user.email ?? user.phone ?? 'U')
                        .characters
                        .first
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? user.email ?? user.phone ?? 'Unnamed user',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'UID: ${user.uid}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleChip(user),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  label: 'Verification: ${user.verificationStatus.name}',
                  color: Colors.orange,
                ),
                _buildStatusChip(
                  label: user.kycRequired ? 'KYC Required' : 'KYC Not Required',
                  color: user.kycRequired ? Colors.red : Colors.green,
                ),
                _buildStatusChip(
                  label:
                      'Agreement: ${user.agreementAccepted ? 'Accepted' : 'Not accepted'}',
                  color: user.agreementAccepted ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Reject'),
                  onPressed: _isProcessingAction
                      ? null
                      : () => _handleUpdateVerification(
                            user,
                            VerificationStatus.rejected,
                          ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text('Verify'),
                  onPressed: _isProcessingAction
                      ? null
                      : () => _handleUpdateVerification(
                            user,
                            VerificationStatus.verified,
                          ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Promote'),
                  onPressed: _isProcessingAction
                      ? null
                      : () => _handlePromoteToAdmin(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserModel user) {
    final isAdmin = user.role == UserRole.admin;
    return Chip(
      label: Text(isAdmin ? 'Admin' : 'User'),
      backgroundColor: isAdmin ? Colors.deepPurple[100] : Colors.grey[200],
      avatar: Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.person,
        size: 18,
        color: isAdmin ? Colors.deepPurple : Colors.grey[700],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _handleUpdateVerification(
      UserModel user, VerificationStatus status) async {
    setState(() {
      _isProcessingAction = true;
    });

    try {
      debugPrint(
          '[INFO] [AdminDashboard] Updating verification for UID=${user.uid} to $status');

      // Preserve existing document metadata fields; only update verification-related keys.
      await UserService.updateVerification(
        uid: user.uid,
        status: status,
        documentType: user.verificationDocumentType ?? 'admin_update',
        maskedDocumentNumber:
            user.verificationDocumentNumber ?? '****', // keep within existing field set
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == VerificationStatus.verified
                ? 'User verified successfully'
                : 'User rejected successfully',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
          '[ERROR] [AdminDashboard] Failed to update verification for UID=${user.uid}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  Future<void> _handlePromoteToAdmin(UserModel user) async {
    setState(() {
      _isProcessingAction = true;
    });

    try {
      debugPrint('[INFO] [AdminDashboard] Promoting UID=${user.uid} to admin');
      await UserService.updateRole(user.uid, UserRole.admin);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User promoted to admin successfully'),
        ),
      );
    } catch (e) {
      debugPrint(
          '[ERROR] [AdminDashboard] Failed to promote UID=${user.uid} to admin: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to promote user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }
}
