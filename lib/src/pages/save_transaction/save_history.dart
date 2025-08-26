// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/glass_dialog.dart';

import 'package:monalisa_app_001/src/components/pin_keyboard.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/widgets/global_layout.dart';
import 'package:monalisa_app_001/src/widgets/display_amount.dart';

class SaveTransactionHistory extends StatefulWidget {
  static const String route = '/save_history';
  const SaveTransactionHistory({super.key});

  @override
  State<SaveTransactionHistory> createState() => _SaveTransactionHistoryState();
}

class _SaveTransactionHistoryState extends State<SaveTransactionHistory> {
  String amount = '0';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalPageLayout(
        headerPadding: kPadding.px,
        header: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: 54.mt,
              child: ListTile(
                contentPadding: 0.p,
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Add Transaction',
                      style: context.bodyLarge.k(context.titleInverse),
                    ),
                    Text(
                      'Expense',
                      style: context.bodySmall.k(context.titleInverse),
                    ),
                  ],
                ),
                trailing:
                    Text(
                      'Cancel',
                      style: context.bodyMedium.bold.k(context.titleInverse),
                    ).onTap(() {
                      context.pop();
                    }),
              ),
            ),
            Padding(
              padding: 77.py,
              child: MoneyDisplay(
                amount: double.parse(amount),
                color: Colors.white,
              ),
            ),
          ],
        ),
        footer: Container(
          //padding: kPadding.px,
          decoration: BoxDecoration()
              .roundedOnly(topLeft: 20, topRight: 20)
              .bg(context.background),
          child: Container(
            //margin: kMargin.my,
            padding: kPadding.px,
            child: PinKeyboard(
              backgroundColor: context.background,
              // Custom key background color
              keyFontSize: 32.0.sp, // Custom font size for key labels
              swapPosition: true,
              keyShape: KeyShape.circle,
              onDigitPressed: (String x) {
                setState(() {
                  if (amount == '0') {
                    amount = x;
                  } else {
                    amount += x;
                  }
                });
              },
              onDeletePressed: () {
                setState(() {
                  if (amount.length > 1) {
                    amount = amount.substring(0, amount.length - 1);
                  } else {
                    amount = '0';
                  }
                });
              },
              onDonePressed: () {
                Future.microtask(() {
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: const SaveTransactionForm(),
                      ),
                    );
                  }
                });
              },
            ),
          ),
        ),
        contentHeight: .50,
      ),
    );
  }
}

class ReusableDropdown extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;
  final String hint;

  const ReusableDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.hint = 'Select an option',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      padding: 0.p,
      value: selectedItem,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
      decoration: InputDecoration(
        fillColor: context.cardBackground,
        //labelText: hint,
        labelStyle: context.bodySmall.copyWith(color: context.outline),
        contentPadding: 0.p,
        // contentPadding: const EdgeInsets.symmetric(
        //   horizontal: 12,
        //   vertical: 14,
        // ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                radius: 18,
                child: Icon(
                  Icons.category,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(item, style: context.bodyMedium),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class SaveTransactionForm extends StatefulWidget {
  const SaveTransactionForm({super.key});

  @override
  State<SaveTransactionForm> createState() => _SaveTransactionFormState();
}

class _SaveTransactionFormState extends State<SaveTransactionForm> {
  final List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills'];

  final List<String> dates = ['Today', 'Yesterday', 'Last Week'];

  String? selectedCategory;
  String? selectedDate;
  String? calDate;
  final TextEditingController noteController = TextEditingController();
  @override
  void initState() {
    super.initState();
    selectedCategory = categories.first;
    selectedDate = dates.first;
  }

  void _showCustomDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime tempPickedDate = DateTime.now();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: context.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select a date",
                  style: context.titleMedium.k(context.titleInverse),
                ),
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.teal,
                      onPrimary: context.bodyTextColor,
                      onSurface: context.bodyTextColor,
                    ),
                    textTheme: TextTheme(
                      bodyMedium: TextStyle(
                        fontSize: 14,
                        color: context.bodyTextColor,
                      ),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) {
                      tempPickedDate = date;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kMargin.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(tempPickedDate);
                      },
                      child: const Text("Select"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          calDate = '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildSuccessAlert() {
      return Center(
        child: Container(
          margin: 28.m,
          padding: 27.p,
          height: 357.h,
          width: 334.w,
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            spacing: 5.h,
            children: [
              Container(
                height: 100.h,
                width: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.secondaryButton,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: context.primaryColor, size: 64),
              ),
              10.s,
              Text(
                'Success!',
                style: context.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'Successfully added expense',
                style: context.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Spacer(),
              PrimaryButton(
                label: "Continue",
                color: context.primaryColor,
                textColor: context.titleInverse,
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(HomePage.route, (route) => false);
                  }
                },
                //borderColor:context.primaryColor.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: context.getHeight / 2,
      padding: kPadding.p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: 10.pt,
            title: const Text('Transaction Date'),
            subtitle: GestureDetector(
              onTap: () => _showCustomDatePicker(context),
              child: Text(
                calDate ?? 'Select Date',
                style: context.bodyMedium.copyWith(
                  color: selectedDate == null
                      ? context.outline
                      : context.bodyTextColor,
                ),
              ),
            ),
          ),

          Divider(),
          ListTile(
            contentPadding: 10.pt,
            title: const Text('Category'),
            subtitle: ReusableDropdown(
              items: categories,
              selectedItem: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              hint: 'Select Category',
            ),
          ),
          Divider(),
          ListTile(
            contentPadding: 10.pt,
            title: const Text('Note'),
            subtitle: Container(
              margin: 16.mt,
              child: CustomTextField(
                hint: 'Enter your notes',
                leading: Icon(
                  TablerIcons.notebook,
                  color: context.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save Transaction',
            onPressed: () {
              // Save transaction logic here
              // final note = noteController.text;
              // log(
              //   'Date: $selectedDate, Category: $selectedCategory, Note: $note',
              // );
              showCustomDialog(context, buildSuccessAlert());
            },
          ),
        ],
      ),
    );
  }
}
