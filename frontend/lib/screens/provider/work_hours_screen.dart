import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class WorkHoursScreen extends StatefulWidget {
  @override
  _WorkHoursScreenState createState() => _WorkHoursScreenState();
}

class _WorkHoursScreenState extends State<WorkHoursScreen> {
  final List<String> _allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  List<String> _selectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  String _startTime = "09:00";
  String _endTime = "17:00";
  List<Map<String, dynamic>> _recurringSlots = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentHours();
  }

  Future<void> _loadCurrentHours() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user')!);
    if (user['workingHours'] != null) {
      setState(() {
        _selectedDays = List<String>.from(user['workingHours']['days']);
        _startTime = user['workingHours']['startTime'];
        _endTime = user['workingHours']['endTime'];
      });
    }
    if (user['recurringBusySlots'] != null) {
      setState(() {
        _recurringSlots = List<Map<String, dynamic>>.from(user['recurringBusySlots']);
      });
    }
  }

  Future<void> _saveHours() async {
    setState(() => _isSaving = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse("${ApiConfig.authUrl}/profile"),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'workingHours': {
            'days': _selectedDays,
            'startTime': _startTime,
            'endTime': _endTime
          },
          'recurringBusySlots': _recurringSlots
        }),
      );

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        await prefs.setString('user', jsonEncode(updatedUser));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schedules updated successfully!')));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving changes.')));
    }
    setState(() => _isSaving = false);
  }

  void _addRecurringSlot() {
    setState(() {
      _recurringSlots.add({
        'startTime': '12:00',
        'endTime': '13:00',
        'reason': 'Lunch Break',
        'active': true
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Availability & Breaks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
              titlePadding: EdgeInsetsDirectional.only(start: 56, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(Icons.access_time_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
                    ),
                  ],
                ),
              ),
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernCard(
                    title: 'Standard Working Days',
                    icon: Icons.calendar_today_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDays.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) _selectedDays.add(day);
                              else _selectedDays.remove(day);
                            });
                          },
                          selectedColor: Color(0xFF1E3C72).withOpacity(0.1),
                          checkmarkColor: Color(0xFF1E3C72),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? Color(0xFF1E3C72) : Colors.grey[200]!),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Color(0xFF1E3C72) : Color(0xFF64748B),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildModernCard(
                    title: 'Daily Operational Hours',
                    icon: Icons.timer_rounded,
                    child: Row(
                      children: [
                        Expanded(child: _buildTimePicker('Starts At', _startTime, (val) => setState(() => _startTime = val))),
                        SizedBox(width: 16),
                        Expanded(child: _buildTimePicker('Ends At', _endTime, (val) => setState(() => _endTime = val))),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildModernCard(
                    title: 'Daily Recurring Breaks',
                    icon: Icons.coffee_rounded,
                    action: IconButton(
                      icon: Icon(Icons.add_circle_rounded, color: Color(0xFF1E3C72), size: 28),
                      onPressed: _addRecurringSlot,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'These times will be blocked automatically every day (e.g., Lunch Time).', 
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        SizedBox(height: 16),
                        ..._recurringSlots.asMap().entries.map((entry) {
                          return _buildRecurringSlotItem(entry.key, entry.value);
                        }).toList(),
                        if (_recurringSlots.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 30),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!, style: BorderStyle.none),
                            ),
                            child: Center(
                              child: Text(
                                'No recurring breaks set.', 
                                style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveHours,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isSaving 
                          ? CircularProgressIndicator(color: Colors.white) 
                          : Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required String title, required IconData icon, required Widget child, Widget? action}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Color(0xFF1E3C72).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Color(0xFF1E3C72), size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              if (action != null) action,
            ],
          ),
          SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRecurringSlotItem(int index, Map<String, dynamic> slot) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'Reason (e.g. Lunch)', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                  controller: TextEditingController(text: slot['reason'])..selection = TextSelection.fromPosition(TextPosition(offset: (slot['reason'] ?? "").length)),
                  onChanged: (val) => _recurringSlots[index]['reason'] = val,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Switch(
                value: slot['active'] ?? true,
                onChanged: (val) => setState(() => _recurringSlots[index]['active'] = val),
                activeColor: Color(0xFF1E3C72),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                onPressed: () => setState(() => _recurringSlots.removeAt(index)),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Expanded(child: _buildTimePickerSmall('From', slot['startTime'], (val) => setState(() => _recurringSlots[index]['startTime'] = val))),
              SizedBox(width: 12),
              Expanded(child: _buildTimePickerSmall('To', slot['endTime'], (val) => setState(() => _recurringSlots[index]['endTime'] = val))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, String currentTime, Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(currentTime.split(':')[0]),
                minute: int.parse(currentTime.split(':')[1]),
              ),
            );
            if (picked != null) {
              onSelected("${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentTime, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.access_time_filled_rounded, size: 20, color: Color(0xFF1E3C72)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerSmall(String label, String currentTime, Function(String) onSelected) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(currentTime.split(':')[0]),
                minute: int.parse(currentTime.split(':')[1]),
              ),
            );
            if (picked != null) {
              onSelected("${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text(currentTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
