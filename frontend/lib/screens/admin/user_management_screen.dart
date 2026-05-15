import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../config/api_config.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final String baseUrl = "${ApiConfig.adminUrl}/users";
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
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
          _users = data
              .map((json) => UserModel.fromJson(json))
              .where((user) => user.role.toLowerCase() == 'user')
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

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete User', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove this user from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Delete User'),
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
          _fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User removed successfully'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red[700]),
          );
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();
    });
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
            : _filteredUsers.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 16),
                        Text('No students found', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUserCard(_filteredUsers[index]),
                      childCount: _filteredUsers.length,
                    ),
                  ),
                ),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
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
        title: Text('Student Management', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
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
        onChanged: _filterUsers,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3C72)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
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
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.person_rounded, color: Colors.blue, size: 26),
        ),
        title: Text(
          user.name, 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16)
        ),
        subtitle: Text(user.email, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
        trailing: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.delete_outline_rounded, color: Colors.red[700], size: 20),
          ),
          onPressed: () => _deleteUser(user.id),
        ),
      ),
    );
  }
}
