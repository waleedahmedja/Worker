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

  Future<List<DropdownMenuItem<String>>> _fetchDropdownItems(
      String role) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Tracking")),
      body: Column(
        children: [
          // Commented out the PaymentSummary since it's not defined in the code
          // const PaymentSummary(),
          const Divider(),
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
                  child: FutureBuilder<List<DropdownMenuItem<String>>>(
                    future: _fetchDropdownItems('customer'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedCustomer,
                        hint: const Text("Select Customer"),
                        items: snapshot.data ?? [],
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomer = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<List<DropdownMenuItem<String>>>(
                    future: _fetchDropdownItems('worker'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedWorker,
                        hint: const Text("Select Worker"),
                        items: snapshot.data ?? [],
                        onChanged: (value) {
                          setState(() {
                            _selectedWorker = value;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('paymentStatus', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No payments found."));
                }

                final jobs = snapshot.data!.docs;

                // Filter jobs
                final filteredJobs = jobs.where((doc) {
                  final job = doc.data() as Map<String, dynamic>;

                  // Filter by date range
                  final startDate = _startDateController.text.isNotEmpty
                      ? DateTime.parse(_startDateController.text)
                      : null;
                  final endDate = _endDateController.text.isNotEmpty
                      ? DateTime.parse(_endDateController.text)
                      : null;
                  final jobDate = job['createdAt'].toDate();

                  if (startDate != null && jobDate.isBefore(startDate)) {
                    return false;
                  }
                  if (endDate != null && jobDate.isAfter(endDate)) {
                    return false;
                  }

                  // Filter by customer/worker
                  if (_selectedCustomer != null &&
                      job['customerId'] != _selectedCustomer) {
                    return false;
                  }
                  if (_selectedWorker != null &&
                      job['workerId'] != _selectedWorker) {
                    return false;
                  }

                  return true;
                }).toList();

                return ListView.builder(
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job =
                        filteredJobs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text("Job ID: ${filteredJobs[index].id}"),
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
