import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _saveLastRoute();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _bioController = TextEditingController(text: user?.bio ?? "");
  }

  void _saveLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', 'profile');
    } catch (e) {
      print("Error saving last route: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final result = await Provider.of<AuthProvider>(context, listen: false).updateProfile({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'bio': _bioController.text,
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'), 
            backgroundColor: Color(0xFF065F46),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(user, lang),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('General Information', Icons.person_outline_rounded),
                    SizedBox(height: 16),
                    _buildTextField(lang.translate('name'), _nameController, Icons.person_rounded),
                    SizedBox(height: 16),
                    _buildTextField(lang.translate('phone_number') == 'phone_number' ? 'Phone Number' : lang.translate('phone_number'), _phoneController, Icons.phone_android_rounded),
                    
                    SizedBox(height: 32),
                    _buildSectionTitle('Preferences', Icons.settings_suggest_rounded),
                    SizedBox(height: 16),
                    _buildLanguageSelector(lang),
                    
                    if (user?.role == 'provider') ...[
                      SizedBox(height: 32),
                      _buildSectionTitle('Professional Bio', Icons.description_rounded),
                      SizedBox(height: 16),
                      _buildTextField(lang.translate('bio') == 'bio' ? 'Bio / Description' : lang.translate('bio'), _bioController, Icons.info_rounded, maxLines: 3),
                    ],
                    
                    SizedBox(height: 32),
                    _buildSectionTitle('Account Details', Icons.lock_person_rounded),
                    SizedBox(height: 16),
                    _buildReadOnlyField(lang.translate('email'), user?.email ?? "", Icons.email_rounded),
                    
                    SizedBox(height: 48),
                    _buildSaveButton(authProvider, lang),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(user, LanguageProvider lang) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Hero(
                    tag: 'profile-avatar',
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? "U",
                              style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                            child: Icon(Icons.camera_alt_rounded, color: Color(0xFF1E3C72), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user?.name ?? "",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      user?.role.toUpperCase() ?? "",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFF1E3C72)),
        SizedBox(width: 8),
        Text(
          title, 
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3)
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(LanguageProvider langProvider) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Color(0xFF1E3C72).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.translate_rounded, color: Color(0xFF1E3C72), size: 20),
        ),
        title: Text(
          langProvider.currentLocale.languageCode == 'en' ? 'English Language' : 'የአማርኛ ቋንቋ', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)
        ),
        trailing: Switch(
          value: langProvider.currentLocale.languageCode == 'am',
          activeColor: Color(0xFF1E3C72),
          activeTrackColor: Color(0xFF1E3C72).withOpacity(0.2),
          onChanged: (val) {
            langProvider.setLanguage(val ? 'am' : 'en');
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF94A3B8), size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          floatingLabelStyle: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold),
        ),
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF94A3B8), size: 20),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          Spacer(),
          Icon(Icons.lock_rounded, size: 14, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider, LanguageProvider lang) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3C72)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(0xFF1E3C72).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: authProvider.isLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(lang.translate('save').toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
