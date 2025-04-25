import 'package:flutter/material.dart';
import 'package:oxygen/utils/hive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'package:oxygen/models/subscriber.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveHelper.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscriber App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            return snapshot.data! ? HomePage() : LoginPage();
          }
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Subscriber> subscribers = [];

  List<Subscriber> filteredSubscribers = [];
  TextEditingController searchController = TextEditingController();
  String selectedStatus = 'الكل';
  String selectedAmountOrder = 'الافتراضي';

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
    searchController.addListener(_filterSubscribers);
  }

  void _loadFromDatabase() async {
    final data = await HiveHelper.getSubscribers();
    setState(() {
      subscribers = data;
      filteredSubscribers = data;
    });
  }

  Future<void> _deleteSubscriber(Subscriber subscriber) async {
    await HiveHelper.deleteSubscriber(subscriber.name);
    _loadFromDatabase();
  }

  void _filterSubscribers() {
    final query = searchController.text.toLowerCase();
    List<Subscriber> temp =
        subscribers.where((s) => s.name.toLowerCase().contains(query)).toList();

    if (selectedStatus != 'الكل') {
      temp = temp.where((s) => s.status == selectedStatus).toList();
    }

    if (selectedAmountOrder == 'الأعلى مبلغاً') {
      temp.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (selectedAmountOrder == 'الأقل مبلغاً') {
      temp.sort((a, b) => a.amount.compareTo(b.amount));
    }

    setState(() {
      filteredSubscribers = temp;
    });
  }

  void _addSubscriber() async {
    final newSubscriber = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditSubscriberPage()),
    );

    if (newSubscriber != null && newSubscriber is Subscriber) {
      await HiveHelper.insertSubscriber(newSubscriber);
      print("✅ تمت الإضافة: ${newSubscriber.name}");
      _loadFromDatabase(); // تحديث القائمة
      print("✅ تمت الإضافة: ${newSubscriber.name}"); // للطباعة
    }
  }

  void _showSubscriberDetails(Subscriber subscriber) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriberDetailsPage(
          subscriber: subscriber,
          onDelete: () async {
            await _deleteSubscriber(subscriber);
          },
        ),
      ),
    );
    if (updated != null && updated is Subscriber) {
      await HiveHelper.updateSubscriber(updated);
      _loadFromDatabase();
    }
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Color getStatusColor(String status) =>
      status == 'مفعل' ? Colors.green : Colors.red;

  Color getCardColor(Subscriber subscriber) {
    if (subscriber.remainingDays > 5) return Colors.green;
    if (subscriber.remainingDays >= 0) return Colors.yellow[700]!;
    return Colors.red[400]!;
  }

  double get totalDebt =>
      filteredSubscribers.fold(0, (sum, s) => sum + s.amount);

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              items: ['الكل', 'مفعل', 'منتهي']
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                selectedStatus = value!;
                _filterSubscribers();
              },
              decoration: InputDecoration(labelText: 'الحالة'),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedAmountOrder,
              items: ['الافتراضي', 'الأعلى مبلغاً', 'الأقل مبلغاً']
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                selectedAmountOrder = value!;
                _filterSubscribers();
              },
              decoration: InputDecoration(labelText: 'الترتيب حسب المبلغ'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة المشتركين'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مشترك...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              _buildFilterRow(),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الديون الإجمالية:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${totalDebt.toStringAsFixed(0)} د.ع",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSubscribers.length,
              itemBuilder: (context, index) {
                final s = filteredSubscribers[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  color: getCardColor(s),
                  child: ListTile(
                    onTap: () => _showSubscriberDetails(s),
                    title: Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الانتهاء: ${formatDate(s.endDate)}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'الأيام المتبقية: ${s.remainingDays}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'المبلغ: ${s.amount.toStringAsFixed(0)} د.ع',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'ملاحظات: ${s.notes}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    trailing: Text(
                      s.status,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubscriber,
        child: Icon(Icons.add),
        tooltip: 'إضافة مشترك',
      ),
    );
  }
}

// باقي الكود كما هو (صفحة التفاصيل والإضافة/التعديل)...

class SubscriberDetailsPage extends StatefulWidget {
  final Subscriber subscriber;
  final VoidCallback onDelete;

  SubscriberDetailsPage({required this.subscriber, required this.onDelete});

  @override
  _SubscriberDetailsPageState createState() => _SubscriberDetailsPageState();
}

class _SubscriberDetailsPageState extends State<SubscriberDetailsPage> {
  void _editSubscriber() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSubscriberPage(subscriber: widget.subscriber),
      ),
    );

    if (updated != null && updated is Subscriber) {
      setState(() {
        widget.subscriber.name = updated.name;
        widget.subscriber.amount = updated.amount;
        widget.subscriber.status = updated.status;
        widget.subscriber.notes = updated.notes;
        widget.subscriber.endDate = updated.endDate;
      });
      Navigator.pop(context, widget.subscriber);
    }
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا المشترك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDelete();
      Navigator.pop(context);
    }
  }

  void _paySubscription() async {
    final controller = TextEditingController();
    final paid = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('سداد الاشتراك'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'أدخل المبلغ المدفوع'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) Navigator.pop(context, value);
            },
            child: Text('سداد'),
          ),
        ],
      ),
    );

    if (paid != null) {
      setState(() {
        widget.subscriber.amount -= paid;
      });
    }
  }

  void _activateSubscriber() async {
    double? selectedPrice;

    await showDialog(
      context: context,
      builder: (_) {
        final customPriceController = TextEditingController();

        return AlertDialog(
          title: Text('اختيار سعر التفعيل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  selectedPrice = 35000;
                  Navigator.pop(context);
                },
                child: Text('تفعيل بـ 35000 د.ع'),
              ),
              SizedBox(height: 10),
              Text('أو أدخل سعر مخصص:'),
              TextField(
                controller: customPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'اكتب السعر هنا...',
                  suffixText: 'د.ع',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(customPriceController.text);
                if (value != null) {
                  selectedPrice = value;
                  Navigator.pop(context);
                }
              },
              child: Text('تفعيل بالسعر المخصص'),
            ),
          ],
        );
      },
    );

    if (selectedPrice != null) {
      setState(() {
        widget.subscriber.status = 'مفعل';
        widget.subscriber.endDate = widget.subscriber.endDate.add(
          Duration(days: 30),
        );
        widget.subscriber.amount += selectedPrice!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تفعيل المشترك وإضافة $selectedPrice د.ع و٣٠ يوم'),
        ),
      );

      Future.delayed(
        Duration(milliseconds: 500),
        () => Navigator.pop(context, widget.subscriber),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المشترك'),
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _editSubscriber),
          IconButton(icon: Icon(Icons.delete), onPressed: _confirmDelete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الاسم: ${widget.subscriber.name}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'تاريخ الانتهاء: ${DateFormat('yyyy-MM-dd').format(widget.subscriber.endDate)}',
            ),
            SizedBox(height: 10),
            Text('الأيام المتبقية: ${widget.subscriber.remainingDays}'),
            SizedBox(height: 10),
            Text('المبلغ: ${widget.subscriber.amount.toStringAsFixed(0)} د.ع'),
            SizedBox(height: 10),
            Text('الحالة: ${widget.subscriber.status}'),
            SizedBox(height: 10),
            Text('ملاحظات: ${widget.subscriber.notes}'),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _activateSubscriber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('تفعيل المشترك'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _paySubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: Text('سداد الاشتراك'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditSubscriberPage extends StatefulWidget {
  final Subscriber? subscriber;

  AddEditSubscriberPage({this.subscriber});

  @override
  _AddEditSubscriberPageState createState() => _AddEditSubscriberPageState();
}

class _AddEditSubscriberPageState extends State<AddEditSubscriberPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();
  String _status = 'مفعل';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subscriber?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.subscriber?.amount.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.subscriber?.notes ?? '',
    );
    _selectedDate = widget.subscriber?.endDate ?? DateTime.now();
    _status = widget.subscriber?.status ?? 'مفعل';
  }

  void _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date!);
    }
  }

  void _saveSubscriber() {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.tryParse(_amountController.text);
        if (amount == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("⚠️ المبلغ غير صالح")));
          return;
        }

        final newSubscriber = Subscriber(
          name: _nameController.text,
          endDate: _selectedDate,
          amount: amount,
          status: _status,
          notes: _notesController.text,
        );

        print("🚀 المشترك راجع: \${newSubscriber.toJson()}");
        Navigator.pop(context, newSubscriber);
      } catch (e) {
        print("❌ خطأ أثناء حفظ المشترك: \$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscriber == null ? 'إضافة مشترك' : 'تعديل مشترك'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'الاسم'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'المبلغ'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'يرجى إدخال المبلغ' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['مفعل', 'منتهي']
                    .map(
                      (label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
                decoration: InputDecoration(labelText: 'الحالة'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'ملاحظات'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'تاريخ الانتهاء: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: Text('اختيار التاريخ'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _saveSubscriber, child: Text('حفظ')),
            ],
          ),
        ),
      ),
    );
  }
}
