import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _kilometersController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  late String _selectedService;
  String _carCondition = 'used'; // تغيير إلى مفتاح الترجمة
  bool _isLoading = false;
  List<XFile> _images = [];
  XFile? _video;
  bool _isVideo = false;
  
  final ImagePicker _picker = ImagePicker();

  // قائمة الخدمات - استخدام المفاتيح فقط
  List<String> get _servicesKeys => [
    'cars', 'workshops', 'inspection', 'films',
    'painting', 'electric', 'tires', 'spare_parts',
    'accessories', 'exhaust', 'tuning', 'ac',
    'coating', 'license', 'transport', 'driving',
    'dealership', 'finance', 'insurance',
  ];

  // الحصول على النص المترجم للخدمة
  String _getServiceText(String key) {
    return key.tr();
  }

  @override
  void initState() {
    super.initState();
    _selectedService = 'cars';
  }

  bool get _isCarService {
    final carServices = ['cars', 'dealership'];
    return carServices.contains(_selectedService);
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Color(0xFF0A2E5C)),
            title: Text('choose_images'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final images = await _picker.pickMultiImage();
              if (images.isNotEmpty) {
                setState(() {
                  _images = images;
                  _video = null;
                  _isVideo = false;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Color(0xFFFF6B00)),
            title: Text('choose_video'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final video = await _picker.pickVideo(source: ImageSource.gallery);
              if (video != null) {
                setState(() {
                  _video = video;
                  _images = [];
                  _isVideo = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _publishPost() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('enter_title'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> mediaUrls = [];
      String mediaType = 'image';

      if (_isVideo && _video != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('posts/${user.uid}/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await ref.putFile(File(_video!.path));
        mediaUrls.add(await ref.getDownloadURL());
        mediaType = 'video';
      } else if (_images.isNotEmpty) {
        for (var image in _images) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(File(image.path));
          mediaUrls.add(await ref.getDownloadURL());
        }
        mediaType = 'image';
      }

      final postData = <String, dynamic>{
        'userId': user.uid,
        'userName': user.displayName ?? 'user'.tr(),
        'userPhoto': user.photoURL ?? '',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'service': _getServiceText(_selectedService), // حفظ النص المترجم
        'serviceKey': _selectedService, // حفظ المفتاح للاستخدام لاحقاً
        'mediaUrls': mediaUrls,
        'mediaType': mediaType,
        'likes': [],
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
      };

      if (_isCarService) {
        postData.addAll({
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'year': _yearController.text.trim(),
          'price': _priceController.text.trim(),
          'condition': _carCondition.tr(), // حفظ النص المترجم
          'kilometers': _kilometersController.text.trim(),
        });
      } else {
        postData.addAll({
          'price': _servicePriceController.text.trim(),
          'location': _locationController.text.trim(),
        });
      }

      await FirebaseFirestore.instance.collection('posts').add(postData);

      _showSnackBar('post_published'.tr(), isError: false);
      
      // تنظيف الحقول
      _clearFields();
      
    } catch (e) {
      _showSnackBar('error_occurred'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _titleController.clear();
    _descriptionController.clear();
    _phoneController.clear();
    _whatsappController.clear();
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
    _priceController.clear();
    _kilometersController.clear();
    _servicePriceController.clear();
    _locationController.clear();
    _images = [];
    _video = null;
    _isVideo = false;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('add_post'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع الخدمة
            Text('service_type'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedService,
                isExpanded: true,
                underline: const SizedBox(),
                items: _servicesKeys.map((serviceKey) {
                  return DropdownMenuItem(
                    value: serviceKey, 
                    child: Text(_getServiceText(serviceKey)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedService = value!),
              ),
            ),
            const SizedBox(height: 16),
            
            // العنوان
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isCarService ? 'car_title'.tr() : 'title'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // حقل السيارات
            if (_isCarService) ...[
              Text('condition'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('new'.tr()),
                    selected: _carCondition == 'new',
                    onSelected: (_) => setState(() => _carCondition = 'new'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('used'.tr()),
                    selected: _carCondition == 'used',
                    onSelected: (_) => setState(() => _carCondition = 'used'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _brandController, 
                decoration: InputDecoration(
                  labelText: 'brand'.tr(), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modelController, 
                decoration: InputDecoration(
                  labelText: 'model'.tr(), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _yearController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'year'.tr(), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kilometersController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'kilometers'.tr(), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'price'.tr(), 
                  prefixText: '${'egp'.tr()} ', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              // حقل الخدمات
              TextField(
                controller: _servicePriceController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'price'.tr(), 
                  prefixText: '${'egp'.tr()} ', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController, 
                decoration: InputDecoration(
                  labelText: 'location'.tr(), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // الوصف
            TextField(
              controller: _descriptionController, 
              maxLines: 3, 
              decoration: InputDecoration(
                labelText: 'description'.tr(), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // معلومات التواصل
            Text('contact_info'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController, 
              keyboardType: TextInputType.phone, 
              decoration: InputDecoration(
                labelText: 'phone_number'.tr(), 
                hintText: 'phone_hint'.tr(), 
                prefixIcon: const Icon(Icons.phone), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsappController, 
              keyboardType: TextInputType.phone, 
              decoration: InputDecoration(
                labelText: 'whatsapp_number'.tr(), 
                hintText: 'whatsapp_hint'.tr(), 
                prefixIcon: const Icon(Icons.chat), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // الميديا
            Text('media'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isVideo && _video != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.videocam, size: 50, color: Colors.grey)),
              )
            else if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_images[index].path), width: 100, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: Icon(_isVideo ? Icons.videocam : Icons.image, color: _isVideo ? const Color(0xFFFF6B00) : const Color(0xFF0A2E5C)),
              label: Text(_isVideo ? 'change_video'.tr() : (_images.isEmpty ? 'add_media'.tr() : 'change_media'.tr())),
            ),
            const SizedBox(height: 24),
            
            // زر النشر
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publishPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text('publish'.tr(), style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}