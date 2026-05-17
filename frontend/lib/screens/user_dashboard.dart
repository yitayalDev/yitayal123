import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';
import 'booking_screen.dart';
import 'my_appointments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final ServiceService _serviceService = ServiceService();
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filteredServices = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "All";
  Set<String> _expandedProviderIds = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isDemo) {
      // Mock data for demo mode
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _allServices = [
          ServiceModel(
            id: '1',
            name: 'Academic Records Request',
            providerId: 'p1',
            providerName: 'Registrar Office',
            providerCategory: 'Administration',
            duration: 15,
            providerIsAvailable: true,
            category: 'Records',
          ),
          ServiceModel(
            id: '2',
            name: 'Course Registration Help',
            providerId: 'p1',
            providerName: 'Registrar Office',
            providerCategory: 'Administration',
            duration: 20,
            providerIsAvailable: true,
            category: 'Academic',
          ),
          ServiceModel(
            id: '3',
            name: 'Software Installation',
            providerId: 'p2',
            providerName: 'IT Support Center',
            providerCategory: 'Technical Support',
            duration: 30,
            providerIsAvailable: true,
            category: 'IT',
          ),
          ServiceModel(
            id: '4',
            name: 'Network Connection Issue',
            providerId: 'p2',
            providerName: 'IT Support Center',
            providerCategory: 'Technical Support',
            duration: 15,
            providerIsAvailable: false,
            category: 'IT',
          ),
          ServiceModel(
            id: '5',
            name: 'General Health Checkup',
            providerId: 'p3',
            providerName: 'University Health Clinic',
            providerCategory: 'Healthcare',
            duration: 20,
            providerIsAvailable: true,
            category: 'Health',
          ),
        ];
        _filteredServices = _allServices;
        _isLoading = false;
      });
      return;
    }

    try {
      final services = await _serviceService.getServices();
      setState(() {
        _allServices = services;
        _filteredServices = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterServices() {
    setState(() {
      _filteredServices = _allServices.where((service) {
        final matchesSearch = service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            service.providerName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == "All" || 
                              service.category == _selectedCategory || 
                              service.providerCategory == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterServices();
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    _filterServices();
  }

  Map<String, List<ServiceModel>> get _groupedServices {
    Map<String, List<ServiceModel>> groups = {};
    for (var service in _filteredServices) {
      if (!groups.containsKey(service.providerId)) {
        groups[service.providerId] = [];
      }
      groups[service.providerId]!.add(service);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: _buildSearchBar(context, lang),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.explore_rounded, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    lang.translate('explore_services'),
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1E293B), 
                      letterSpacing: -0.5
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildServiceList(lang),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, user) {
    final lang = Provider.of<LanguageProvider>(context);
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF1E3C72)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${lang.translate('welcome')},',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      user?.name ?? 'Student',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 28, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickAction(context, Icons.event_note_rounded, lang.translate('my_appointments'), () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MyAppointmentsScreen()));
                          }),
                          SizedBox(width: 12),
                          _buildNotificationAction(context, lang),
                          SizedBox(width: 12),
                          _buildQuickAction(context, Icons.person_rounded, lang.translate('profile') == 'profile' ? 'Profile' : lang.translate('profile'), () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                          }),
                          SizedBox(width: 12),
                          _buildQuickAction(context, Icons.logout_rounded, lang.translate('logout') == 'logout' ? 'Logout' : lang.translate('logout'), () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAction(BuildContext context, LanguageProvider lang) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          _buildQuickAction(context, Icons.notifications_rounded, lang.translate('notifications') == 'notifications' ? 'Alerts' : lang.translate('notifications'), () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
          }),
          if (provider.unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFFF43F5E), 
                  shape: BoxShape.circle, 
                  border: Border.all(color: Color(0xFF1E3C72), width: 1.5)
                ),
                constraints: BoxConstraints(minWidth: 14, minHeight: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: lang.translate('search_hint'),
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3C72)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    Set<String> usedCategories = {"All"};
    for (var service in _allServices) {
      if (service.category != null && service.category!.isNotEmpty) {
        usedCategories.add(service.category!);
      } else if (service.providerCategory != null && service.providerCategory!.isNotEmpty) {
        usedCategories.add(service.providerCategory!);
      }
    }
    
    final categories = usedCategories.toList();
    categories.sort((a, b) => a == "All" ? -1 : (b == "All" ? 1 : a.compareTo(b)));
    
    return Container(
      height: 44,
      margin: EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _onCategoryChanged(category),
              selectedColor: Color(0xFF1E3C72),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 12,
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : Color(0xFFF1F5F9))
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceList(LanguageProvider lang) {
    if (_isLoading) {
      return SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3C72))));
    }
    
    final grouped = _groupedServices;
    if (grouped.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(lang.translate('no_departments'), style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        )
      );
    }

    final providerIds = grouped.keys.toList();

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final providerId = providerIds[index];
            final services = grouped[providerId]!;
            final providerName = services.first.providerName;
            final providerCategory = services.first.providerCategory ?? "General";
            final bool isAvailable = services.first.providerIsAvailable;
            final bool isExpanded = _expandedProviderIds.contains(providerId);

            return Container(
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedProviderIds.remove(providerId);
                        } else {
                          _expandedProviderIds.add(providerId);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.account_balance_rounded, color: Color(0xFF1E3C72), size: 32),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  providerName,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.5),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  providerCategory,
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatusBadge(isAvailable, lang),
                              SizedBox(height: 4),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      itemBuilder: (context, sIndex) {
                        final service = services[sIndex];
                        return ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(service: service))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(color: Color(0xFF1E3C72).withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.bolt_rounded, color: Color(0xFF1E3C72), size: 18),
                          ),
                          title: Text(
                            service.name,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF334155)),
                          ),
                          subtitle: Text(
                            'Duration: ${service.duration} mins',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
          childCount: providerIds.length,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable, LanguageProvider lang) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Color(0xFF10B981).withOpacity(0.1) : Color(0xFFF43F5E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isAvailable ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFFF43F5E).withOpacity(0.2))),
      ),
      child: Text(
        isAvailable ? lang.translate('online').toUpperCase() : lang.translate('absent').toUpperCase(),
        style: TextStyle(
          color: isAvailable ? Color(0xFF059669) : Color(0xFFE11D48),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
