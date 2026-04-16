import 'package:flutter/material.dart';

class CarReportScreen extends StatefulWidget {
  const CarReportScreen({super.key});

  @override
  State<CarReportScreen> createState() => _CarReportScreenState();
}

class _CarReportScreenState extends State<CarReportScreen> {
  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _report;

  Future<void> _checkCar() async {
    final vin = _vinController.text.trim();
    if (vin.isEmpty) {
      _showSnackBar('يرجى إدخال رقم الشاصي');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // محاكاة API (هنستخدم بيانات وهمية دلوقتي)
      await Future.delayed(const Duration(seconds: 2));

      // بيانات تجريبية
      setState(() {
        _report = {
          'make': 'تويوتا',
          'model': 'كورولا',
          'year': '2020',
          'color': 'أبيض',
          'engine': '1.6L',
          'transmission': 'أوتوماتيك',
          'mileage': '45,000 كم',
          'accidents': 'لا توجد حوادث',
          'owners': 'مالك واحد',
          'status': 'نظيفة',
          'marketValue': '450,000 - 500,000 ج.م',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('لم يتم العثور على السيارة');
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
      appBar: AppBar(title: const Text('تقرير السيارة'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فحص السيارة برقم الشاصي (VIN)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل رقم الشاصي المكون من 17 حرف ورقم',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // حقل إدخال رقم الشاصي
            TextField(
              controller: _vinController,
              decoration: InputDecoration(
                labelText: 'رقم الشاصي (VIN)',
                hintText: 'مثال: 1HGCM82633A123456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    _showSnackBar('خاصية المسح الضوئي قريباً');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // زر الفحص
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkCar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('فحص السيارة', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 30),

            // عرض التقرير
            if (_report != null) ...[
              const Text(
                'نتيجة الفحص',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // حالة السيارة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حالة السيارة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _report!['status'] ?? '',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // تفاصيل السيارة
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('الماركة', _report!['make'] ?? ''),
                      const Divider(),
                      _buildInfoRow('الموديل', _report!['model'] ?? ''),
                      const Divider(),
                      _buildInfoRow('السنة', _report!['year'] ?? ''),
                      const Divider(),
                      _buildInfoRow('اللون', _report!['color'] ?? ''),
                      const Divider(),
                      _buildInfoRow('المحرك', _report!['engine'] ?? ''),
                      const Divider(),
                      _buildInfoRow(
                        'ناقل الحركة',
                        _report!['transmission'] ?? '',
                      ),
                      const Divider(),
                      _buildInfoRow('الكيلومترات', _report!['mileage'] ?? ''),
                      const Divider(),
                      _buildInfoRow('الحوادث', _report!['accidents'] ?? ''),
                      const Divider(),
                      _buildInfoRow('عدد المالكين', _report!['owners'] ?? ''),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // القيمة السوقية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'القيمة السوقية التقريبية',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _report!['marketValue'] ?? '',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
