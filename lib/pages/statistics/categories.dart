import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/category.dart';
import 'package:fund_tracker/models/preferences.dart';
import 'package:fund_tracker/models/transaction.dart';
import 'package:fund_tracker/shared/library.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Categories extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final Preferences prefs;

  Categories({this.transactions, this.categories, this.prefs});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  int touchedIndex = -1;
  bool onlyExpenses;
  TooltipBehavior _tooltip;

  initState() {
    super.initState();
    _tooltip = TooltipBehavior(enable: true, format: 'point.x : point.y%');
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> _categoricalData;
    List<PieChartSectionData> sectionData = [];

    onlyExpenses = onlyExpenses ?? widget.prefs.isOnlyExpenses;

    final List<Transaction> txExpenses =
        widget.transactions.where((tx) => tx.isExpense).toList();

    if (widget.transactions.length > 0) {
      final List<Map<String, dynamic>> _transactionsInCategories = onlyExpenses
          ? divideTransactionsIntoCategories(txExpenses, widget.categories)
          : divideTransactionsIntoCategories(
              widget.transactions, widget.categories);
      final List<Map<String, dynamic>> _categoriesWithTotalAmounts =
          appendTotalCategorialAmounts(_transactionsInCategories);
      final List<Map<String, dynamic>> _categoriesWithPercentages =
          appendIndividualPercentages(_categoriesWithTotalAmounts);
      _categoricalData = combineSmallPercentages(_categoriesWithPercentages);
      _categoricalData
          .sort((a, b) => b['percentage'].compareTo(a['percentage']));
      sectionData = _categoricalData
          .asMap()
          .map((index, category) {
            return MapEntry(
              index,
              PieChartSectionData(
                value: category['percentage'] * 100,
                color: category['iconColor'],
                radius: touchedIndex == index ? 145 : 140,
                title: category['percentage'] > 0.04
                    ? String.fromCharCode(category['icon'])
                    : '',
                titleStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 25.0,
                  fontFamily: 'MaterialDesignIconFont',
                  package: 'community_material_icon',
                ),
                titlePositionPercentageOffset: 0.7,
              ),
            );
          })
          .values
          .toList();
    }

    return Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
      if (sectionData.length > 0) ...[
        SizedBox(height: 10.0),

        Container(
            height: 500, child: _buildDefaultDoughnutChart(_categoricalData)),

        // PieChart(
        //   PieChartData(
        //     sections: sectionData,
        //     sectionsSpace: 1,
        //     borderData: FlBorderData(
        //       show: false,
        //     ),
        //     pieTouchData: PieTouchData(
        //       touchCallback: (pieTouchResponse, res) => setState(() {
        //         touchedIndex = (pieTouchResponse.isInterestedForInteractions ||
        //                 res.touchedSection.touchedSectionIndex == null)
        //             ? touchedIndex
        //             : res.touchedSection.touchedSectionIndex;
        //       }),
        //     ),
        //   ),
        // ),
      ] else ...[
        SizedBox(height: 35.0),
        Center(
          child: Text(
              'No ${onlyExpenses ? 'expenses' : 'negative balance'} in current period.'),
        ),
      ]
    ]);
  }

  SfCircularChart _buildDefaultDoughnutChart(
      List<Map<String, dynamic>> categoricalData) {
    return SfCircularChart(
      enableMultiSelection: false,
      title: ChartTitle(
          text: false ? '' : 'Categories', alignment: ChartAlignment.near),
      legend: Legend(
        isVisible: !false,
        overflowMode: LegendItemOverflowMode.scroll,
        position: LegendPosition.bottom,
        orientation: LegendItemOrientation.horizontal,
      ),
      series: _getDefaultDoughnutSeries(categoricalData),
      tooltipBehavior: _tooltip,
    );
  }

  /// Returns the doughnut series which need to be render.
  List<DoughnutSeries<Map<String, dynamic>, String>> _getDefaultDoughnutSeries(
      List<Map<String, dynamic>> categoricalData) {
    return <DoughnutSeries<Map<String, dynamic>, String>>[
      DoughnutSeries<Map<String, dynamic>, String>(
          radius: '90%',
          explode: true,
          explodeOffset: '0%',
          dataSource: <Map<String, dynamic>>[...categoricalData],
          xValueMapper: (Map<String, dynamic> data, _) => data['name'],
          yValueMapper: (Map<String, dynamic> data, _) => data['percentage'],
          dataLabelMapper: (Map<String, dynamic> data, _) =>
              data['amount'].toStringAsFixed(2) + '\$',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
          ),
          enableTooltip: true)
    ];
  }
}
