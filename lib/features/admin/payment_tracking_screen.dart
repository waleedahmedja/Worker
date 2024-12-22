import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTrackingScreen extends StatefulWidget {
  const PaymentTrackingScreen({super.key});

  @override
  State<PaymentTrackingScreen> createState() => _PaymentTrackingScreenState();
}

class _PaymentTrackingScreenState extends State<PaymentTrackingScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _selectedCustomer;
  String? _selectedWorker;

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      controller.text = pickedDate.toIso8601String();
    }
  }

  /// Fetches items for the dropdown from Firestore.
  Future<List<DropdownMenuItem<String>>> _fetchDropdownItems(String role) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    return snapshot.docs
        .map((doc) => DropdownMenuItem(
              value: doc.id,
              child: Text(doc['name']),
            ))
        .toList();
  }

  /// Builds a reusable dropdown for customer and worker selection.
  Widget buildDropdown({
    required String role,
    required String hint,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    return FutureBuilder<List<DropdownMenuItem<String>>>(
      future: _fetchDropdownItems(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return DropdownButtonFormField<String>(
          value: selectedValue,
          hint: Text(hint),
          items: snapshot.data ?? [],
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  /// Builds the Firestore query for filtered payments.
  Query buildPaymentQuery() {
    Query query = FirebaseFirestore.instance
        .collection('jobs')
        .where('paymentStatus', isEqualTo: 'completed');

    if (_selectedCustomer != null) {
      query = query.where('customerId', isEqualTo: _selectedCustomer);
    }

    if (_selectedWorker != null) {
      query = query.where('workerId', isEqualTo: _selectedWorker);
    }

    if (_startDateController.text.isNotEmpty) {
      final startDate = DateTime.parse(_startDateController.text);
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }

    if (_endDateController.text.isNotEmpty) {
      final endDate = DateTime.parse(_endDateController.text);
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Tracking")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: "Start Date",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _startDateController),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: "End Date",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _endDateController),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: buildDropdown(
                    role: 'customer',
                    hint: 'Select Customer',
                    selectedValue: _selectedCustomer,
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildDropdown(
                    role: 'worker',
                    hint: 'Select Worker',
                    selectedValue: _selectedWorker,
                    onChanged: (value) {
                      setState(() {
                        _selectedWorker = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: buildPaymentQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No payments found."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final job =
                        snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text("Job ID: ${snapshot.data!.docs[index].id}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Customer: ${job['customerId']}"),
                          Text("Worker: ${job['workerId']}"),
                          Text(
                              "Location: ${job['location'].latitude}, ${job['location'].longitude}"),
                          Text("Fare: \$${job['fare']}"),
                          Text("Payment: ${job['paymentStatus']}"),
                          Text("Date: ${job['createdAt'].toDate()}"),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
