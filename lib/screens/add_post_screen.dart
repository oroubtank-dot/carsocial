import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'home_screen.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  String _selectedService = 'cars';
  String _carCondition = 'used';
  bool _isNegotiable = true;
  List<File> _images = [];
  File? _video;
  bool _isVideo = false;
  bool _isLoading = false;

  final List<Map<String, String>> _services = [
    {'key': 'cars', 'label': 'cars'},
    {'key': 'workshops', 'label': 'workshops'},
    {'key': 'inspection', 'label': 'inspection'},
    {'key': 'films', 'label': 'films'},
    {'key': 'painting', 'label': 'painting'},
    {'key': 'electric', 'label': 'electric'},
    {'key': 'tires', 'label': 'tires'},
    {'key': 'spare_parts', 'label': 'spare_parts'},
    {'key': 'accessories', 'label': 'accessories'},
    {'key': 'exhaust', 'label': 'exhaust'},
    {'key': 'tuning', 'label': 'tuning'},
    {'key': 'ac', 'label': 'ac'},
    {'key': 'coating', 'label': 'coating'},
    {'key': 'license', 'label': 'license'},
    {'key': 'transport', 'label': 'transport'},
    {'key': 'driving', 'label': 'driving'},
    {'key': 'dealership', 'label': 'dealership'},
    {'key': 'finance', 'label': 'finance'},
    {'key': 'insurance', 'label': 'insurance'},
  ];

  Future<void> _pickMedia() async {
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Color(0xFF0A2E5C)),
            title: Text('choose_images'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final pickedImages = await picker.pickMultiImage();
              if (pickedImages.isNotEmpty && mounted) {
                setState(() {
                  _images = pickedImages.map((e) => File(e.path)).toList();
                  _isVideo = false;
                  _video = null;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Color(0xFFFF6B00)),
            title: Text('choose_video'.tr()),
            onTap: () async {
              Navigator.pop(context);
              final pickedVideo = await picker.pickVideo(
                source: ImageSource.gallery,
              );
              if (pickedVideo != null && mounted) {
                setState(() {
                  _video = File(pickedVideo.path);
                  _isVideo = true;
                  _images = [];
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPost() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('please_enter_title'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) _showSnackBar('please_login'.tr());
        return;
      }

      final firestore = FirebaseFirestore.instance;

      List<String> mediaUrls = [];
      String mediaType = 'image';

      if (_isVideo && _video != null) {
        try {
          final ref = FirebaseStorage.instance.ref().child(
            'posts/${user.uid}/video_${DateTime.now().millisecondsSinceEpoch}.mp4',
          );
          await ref.putFile(_video!);
          mediaUrls.add(await ref.getDownloadURL());
          mediaType = 'video';
        } catch (e) {
          debugPrint('فشل رفع الفيديو: $e');
        }
      } else if (_images.isNotEmpty) {
        try {
          for (var image in _images) {
            final ref = FirebaseStorage.instance.ref().child(
              'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putFile(image);
            mediaUrls.add(await ref.getDownloadURL());
          }
          mediaType = 'image';
        } catch (e) {
          debugPrint('فشل رفع الصور: $e');
        }
      }

      final postData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'user'.tr(),
        'userPhoto': user.photoURL ?? '',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': _priceController.text,
        'service': _selectedService.tr(),
        'serviceKey': _selectedService,
        'condition': _carCondition == 'new' ? 'new'.tr() : 'used'.tr(),
        'negotiable': _isNegotiable,
        'mediaUrls': mediaUrls,
        'mediaType': mediaType,
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'likes': [],
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('posts').add(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mediaUrls.isEmpty
                  ? 'post_published_no_media'.tr()
                  : 'post_published'.tr(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('error_occurred'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('add_post'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع الخدمة
            Text(
              'service_type'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              items: _services.map((service) {
                return DropdownMenuItem(
                  value: service['key'],
                  child: Text(service['label']!.tr()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedService = value!),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // حالة السيارة (لخدمة السيارات فقط)
            if (_selectedService == 'cars') ...[
              Text(
                'condition'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            ],

            // العنوان
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'title'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الوصف
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'description'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // السعر
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'price'.tr(),
                prefixText: '${'egp'.tr()} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // قابل للتفاوض
            SwitchListTile(
              title: Text('negotiable'.tr()),
              value: _isNegotiable,
              onChanged: (value) => setState(() => _isNegotiable = value),
              activeTrackColor: const Color(0xFFFF6B00),
              activeThumbColor: Colors.white,
            ),
            const SizedBox(height: 16),

            // معلومات التواصل
            Text(
              'contact_info'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'phone_number'.tr(),
                hintText: 'phone_hint'.tr(),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الصور والفيديو
            Text(
              'images'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isVideo && _video != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.videocam, size: 50, color: Colors.grey),
                ),
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
                        child: Image.file(
                          _images[index],
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: Icon(
                _isVideo ? Icons.videocam : Icons.image,
                color: _isVideo
                    ? const Color(0xFFFF6B00)
                    : const Color(0xFF0A2E5C),
              ),
              label: Text(
                _isVideo
                    ? 'change_video'.tr()
                    : (_images.isEmpty
                          ? 'add_media'.tr()
                          : 'change_media'.tr()),
              ),
            ),
            const SizedBox(height: 24),

            // زر النشر
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'publish'.tr(),
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
