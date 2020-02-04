import 'package:flutter/material.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/pages/categories/categoriesRegistry.dart';
import 'package:fund_tracker/pages/statistics/barTile.dart';
import 'package:fund_tracker/shared/library.dart';
import 'package:fund_tracker/shared/widgets.dart';

class TopExpenses extends StatefulWidget {
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpenses;
  final ScrollController scrollController;

  TopExpenses(
    this.transactions,
    this.totalIncome,
    this.totalExpenses,
    this.scrollController,
  );

  @override
  _TopExpensesState createState() => _TopExpensesState();
}

class _TopExpensesState extends State<TopExpenses> {
  int _showCount = 5;
  List<Map<String, dynamic>> _sortedTransactions;

  List<Widget> _columnContent = <Widget>[
    SizedBox(height: 35.0),
    Center(
      child: Text('No transactions found in current period.'),
    )
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.length > 0) {
      _sortedTransactions = sortByAmountDescending(widget.transactions)
          .map((tx) => {
                'payee': tx.payee,
                'category': tx.category,
                'amount': tx.amount,
              })
          .toList();
      _sortedTransactions = getPercentagesOutOfTotalAmount(
          _sortedTransactions, widget.totalExpenses);
      _columnContent = sublist(_sortedTransactions, 0, _showCount)
              .map((tx) => <Widget>[
                    SizedBox(height: 10.0),
                    Column(
                      children: <Widget>[
                        BarTile(
                          title: tx['payee'],
                          subtitle: tx['category'],
                          amount: tx['amount'],
                          percentage: tx['percentage'],
                          color: categoriesRegistry.singleWhere((category) {
                            return category['name'] == tx['category'];
                          })['color'],
                        ),
                      ],
                    ),
                  ])
              .expand((x) => x)
              .toList() +
          <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  child: Text('Collapse'),
                  onPressed: () => setState(() => _showCount = 5),
                ),
                FlatButton(
                  child: Text('Show more'),
                  onPressed: () {
                    setState(() => _showCount += 5);
                    widget.scrollController.animateTo(
                      99999,
                      duration: Duration(seconds: 3),
                      curve: Curves.easeInOutQuint,
                    );
                  },
                )
              ],
            )
          ];
    }

    return Column(
      children: <Widget>[statTitle('Top Expenses')] + _columnContent,
    );
  }
}

List<Transaction> sortByAmountDescending(List<Transaction> transactions) {
  transactions.sort((a, b) => b.amount.compareTo(a.amount));
  return transactions;
}
