// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animation/animation_utils.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/empty_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserModel? _user;
  List<OrderModel> _orders = [];
  bool _loadingUser = true;
  bool _loadingOrders = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    final loggedIn = await ApiService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);

    if (loggedIn) {
      await Future.wait([_loadUser(), _loadOrders()]);
    } else {
      setState(() {
        _loadingUser = false;
        _loadingOrders = false;
      });
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final data = await ApiService.get('/orders/');
      final orders = (data as List).map((o) => OrderModel.fromJson(o)).toList();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontFamily: 'Playfair', fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        context.read<WishlistProvider>().reset();
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(
            fontFamily: 'Playfair',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
              tooltip: 'Log Out',
              onPressed: _logout,
            ),
        ],
      ),
      body: _isLoggedIn ? _loggedInBody() : _loggedOutBody(),
    );
  }

  // ── Not logged in ─────────────────────────────────────────────────────────
  Widget _loggedOutBody() {
    return CustomEmptyState(
      icon: Icons.person_outline_rounded,
      title: "Welcome to Noor's Attire",
      description: "Sign in to access your saved wishlist items, track orders, and manage account details.",
      buttonText: "SIGN IN TO ACCOUNT",
      onButtonPressed: () => Navigator.pushNamed(context, '/login'),
    );
  }

  // ── Logged in ─────────────────────────────────────────────────────────────
  Widget _loggedInBody() {
    return Column(
      children: [
        _profileHeader(),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textGrey,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'My Profile'),
              Tab(text: 'Order History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_infoTab(), _ordersTab()],
          ),
        ),
      ],
    );
  }

  // ── Profile Header ────────────────────────────────────────────────────────
  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B0606), Color(0xFF8B1A1A)],
        ),
      ),
      child: _loadingUser
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _user != null && _user!.name.isNotEmpty
                          ? _user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontFamily: 'Playfair',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.name ?? 'Customer',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Playfair',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Info Tab ──────────────────────────────────────────────────────────────
  Widget _infoTab() {
    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_user == null) {
      return const Center(child: Text('Could not load profile details'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeInSlide(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),

            _infoCard([
              _infoRow(Icons.person_outline_rounded, 'Full Name', _user!.name),
              _dividerLine(),
              _infoRow(Icons.email_outlined, 'Email Address', _user!.email),
              if (_user!.phone != null) ...[
                _dividerLine(),
                _infoRow(Icons.phone_outlined, 'Phone Number', _user!.phone!),
              ],
            ]),

            const SizedBox(height: 28),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),

            _actionTile(
              Icons.shopping_bag_outlined,
              'My Orders',
              'Track active and past purchases',
              onTap: () => _tabController.animateTo(1),
            ),
            const SizedBox(height: 10),
            _actionTile(
              Icons.favorite_border_rounded,
              'Saved Wishlist',
              'View your saved dresses & shirts',
              onTap: () => Navigator.pushNamed(context, '/wishlist'),
            ),
            const SizedBox(height: 10),
            _actionTile(
              Icons.logout_rounded,
              'Sign Out',
              'Log out of this device',
              color: AppTheme.error,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() => const Divider(height: 1, indent: 50, endIndent: 16);

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppTheme.primary;
    return ScaleHoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  // ── Orders Tab ────────────────────────────────────────────────────────────
  Widget _ordersTab() {
    if (_loadingOrders) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_orders.isEmpty) {
      return CustomEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Orders Yet',
        description: 'When you place an order, its progress and history will be tracked here.',
        buttonText: 'START SHOPPING',
        onButtonPressed: () => Navigator.pushNamed(context, '/products'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => FadeInSlide(
          delay: Duration(milliseconds: 50 * index),
          child: _orderCard(_orders[index]),
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final statusColor = _statusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (order.createdAt != null)
                      Text(
                        _formatDate(order.createdAt!),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.productName} × ${item.quantity}'
                        '${item.size != null ? ' (${item.size})' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                      ),
                    ),
                    Text(
                      'PKR ${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cash on Delivery',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'delivered':
        return AppTheme.success;
      case 'shipped':
        return Colors.blue;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.accent;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
