import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/service_model.dart';
import '../../config/api_config.dart';

class ManageServicesScreen extends StatefulWidget {
  @override
  _ManageServicesScreenState createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final String baseUrl = ApiConfig.servicesUrl;
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('user');
        if (userStr == null) return;
        final user = jsonDecode(userStr);
        final String currentUserId = (user['id'] ?? user['_id'] ?? "").toString();
        
        setState(() {
          _services = data
              .map((json) => ServiceModel.fromJson(json))
              .where((s) => s.providerId == currentUserId && currentUserId.isNotEmpty)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Service?'),
        content: Text('Are you sure you want to permanently delete this service and all of its booked appointments?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Delete', style: TextStyle(color: Colors.red))
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
          headers: ApiConfig.getHeaders(token),
        );

        if (response.statusCode == 200) {
          _fetchServices();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service and associated appointments deleted successfully!'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            )
          );
        } else {
          final err = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['msg'] ?? 'Delete failed')));
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void _showServiceDialog({ServiceModel? service}) {
    final _nameController = TextEditingController(text: service?.name ?? '');
    final _descController = TextEditingController(text: service?.description ?? '');
    final _durController = TextEditingController(text: service?.duration.toString() ?? '30');
    final bool isEdit = service != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          isEdit ? 'Edit Service' : 'Add New Service', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, 'Service Name', 'e.g. ID Card Processing', Icons.label_outline_rounded),
              SizedBox(height: 16),
              _buildTextField(_descController, 'Description', 'What is this service about?', Icons.description_outlined),
              SizedBox(height: 16),
              _buildTextField(_durController, 'Duration (minutes)', 'e.g. 30', Icons.timer_outlined, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0F172A), 
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? token = prefs.getString('token');

              final body = jsonEncode({
                'name': _nameController.text,
                'description': _descController.text,
                'duration': int.parse(_durController.text),
              });

              http.Response response;
              if (isEdit) {
                response = await http.put(
                  Uri.parse('$baseUrl/${service.id}'),
                  headers: ApiConfig.getHeaders(token),
                  body: body,
                );
              } else {
                response = await http.post(
                  Uri.parse(baseUrl),
                  headers: ApiConfig.getHeaders(token),
                  body: body,
                );
              }

              if (response.statusCode == 200) {
                Navigator.pop(context);
                _fetchServices();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Service Updated!' : 'Service Added!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green[700],
                  )
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        floatingLabelStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text('Manage Services', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: Colors.white), 
            onPressed: () => _showServiceDialog()
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : RefreshIndicator(
              onRefresh: () => _fetchServices(),
              child: _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text('No services found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          TextButton(
                            onPressed: () => _showServiceDialog(), 
                            child: Text('Create your first service', style: TextStyle(fontWeight: FontWeight.bold))
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: Offset(0, 8))
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF0F172A).withOpacity(0.05), 
                                borderRadius: BorderRadius.circular(16)
                              ),
                              child: Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF0F172A)),
                            ),
                            title: Text(
                              service.name, 
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B))
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${service.duration} mins • ${service.description ?? "No description"}',
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit_rounded, color: Colors.blue[700], size: 20),
                                  ),
                                  onPressed: () => _showServiceDialog(service: service),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, color: Colors.red[700], size: 20),
                                  ),
                                  onPressed: () => _deleteService(service.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
