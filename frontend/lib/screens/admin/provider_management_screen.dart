import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../config/api_config.dart';

class ProviderManagementScreen extends StatefulWidget {
  @override
  _ProviderManagementScreenState createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen> {
  final String baseUrl = "${ApiConfig.adminUrl}/users";
  List<UserModel> _providers = [];
  List<UserModel> _filteredProviders = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _providers = data
              .map((json) => UserModel.fromJson(json))
              .where((user) => user.role.toLowerCase() == 'provider')
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  void _filterProviders(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProviders = _providers.where((provider) {
        final matchesSearch = provider.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             provider.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             provider.category.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();
    });
  }

  void _showCreateProviderDialog() {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController();
    final _bioController = TextEditingController();
    String _selectedCategory = 'Academic Affairs';

    final List<String> _categories = [
      'Academic Affairs',
      'Student Services',
      'Registrar Office',
      'Financial Services',
      'Health & Wellness',
      'Library & Research',
      'IT Support',
      'Security & Safety',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: EdgeInsets.all(0),
          title: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3C72)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                SizedBox(width: 16),
                Text('Register Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  _buildDialogField('Service Name', 'e.g. Registrar Office', _nameController, Icons.business_rounded),
                  SizedBox(height: 16),
                  _buildCategorySelector(_categories, _selectedCategory, (val) => setDialogState(() => _selectedCategory = val!)),
                  SizedBox(height: 16),
                  _buildDialogField('Contact Phone', '+251...', _phoneController, Icons.phone_rounded),
                  SizedBox(height: 16),
                  _buildDialogField('Description', 'What does this service do?', _bioController, Icons.description_rounded, maxLines: 2),
                  SizedBox(height: 16),
                  _buildDialogField('Admin Email', 'email@university.edu', _emailController, Icons.email_rounded),
                  SizedBox(height: 16),
                  _buildDialogField('Password', '••••••••', _passwordController, Icons.lock_rounded, obscure: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3C72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill required fields')));
                  return;
                }

                final response = await http.post(
                  Uri.parse(ApiConfig.authUrl + "/register"),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'password': _passwordController.text,
                    'role': 'provider',
                    'category': _selectedCategory,
                    'phone': _phoneController.text,
                    'bio': _bioController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  _fetchProviders();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service Registered Successfully!'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF047857)));
                } else {
                  final err = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['msg'] ?? 'Registration failed')));
                }
              },
              child: Text('REGISTER', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, String hint, TextEditingController controller, IconData icon, {int maxLines = 1, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscure,
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(List<String> categories, String selected, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              onChanged: onChanged,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: _buildSearchBar(),
            ),
          ),
          _isLoading
              ? SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))))
              : _filteredProviders.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_center_rounded, size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 16),
                            Text('No service providers found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProviderCard(_filteredProviders[index]),
                          childCount: _filteredProviders.length,
                        ),
                      ),
                    ),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProviderDialog,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: Text('REGISTER PROVIDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, bottom: 16),
        title: Text('Provider Management', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: TextField(
        onChanged: _filterProviders,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search departments or categories...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3C72)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProviderCard(UserModel provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 26),
        ),
        title: Text(
          provider.name, 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.email, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
              child: Text(provider.category, style: TextStyle(color: Colors.indigo[700], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red[700], size: 18),
              ),
              onPressed: () => _deleteProvider(provider.id),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailScreen(providerId: provider.id, providerName: provider.name),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteProvider(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove Provider', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove this department? This will also remove their services.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        final response = await http.delete(
          Uri.parse('$baseUrl/$id'),
          headers: {'x-auth-token': token ?? ''},
        );

        if (response.statusCode == 200) {
          _fetchProviders();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Department removed successfully'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red[700]),
          );
        }
      } catch (e) {
        print(e);
      }
    }
  }
}

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  ProviderDetailScreen({required this.providerId, required this.providerName});

  @override
  _ProviderDetailScreenState createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Fetch all appointments and filter for this provider
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/appointments/my"),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        List<dynamic> allAppts = jsonDecode(response.body);
        setState(() {
          _appointments = allAppts.where((a) => a['providerId']['_id'] == widget.providerId).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Color(0xFF0F172A),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.providerName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E3C72)]
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(),
                  SizedBox(height: 32),
                  Text('APPOINTMENT HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _isLoading 
            ? SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _appointments.isEmpty
              ? SliverFillRemaining(child: Center(child: Text('No appointments found for this provider')))
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildApptCard(_appointments[index]),
                      childCount: _appointments.length,
                    ),
                  ),
                ),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    int approved = _appointments.where((a) => a['status'] == 'approved').length;
    int pending = _appointments.where((a) => a['status'] == 'pending').length;

    return Row(
      children: [
        _buildStatCard('Total', _appointments.length.toString(), Colors.blue),
        SizedBox(width: 12),
        _buildStatCard('Approved', approved.toString(), Colors.green),
        SizedBox(width: 12),
        _buildStatCard('Pending', pending.toString(), Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildApptCard(dynamic appt) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B))),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt['userId']['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${appt['date'].toString().split('T')[0]} @ ${appt['timeSlot']}', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _getStatusColor(appt['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(appt['status'].toString().toUpperCase(), style: TextStyle(color: _getStatusColor(appt['status']), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
