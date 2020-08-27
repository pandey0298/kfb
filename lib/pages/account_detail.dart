import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kfb/api_provider/orders_api_provider.dart';
import 'package:kfb/helpers/tools.dart';
import 'package:kfb/helpers/ui.dart';
import 'package:kfb/models/response/order.dart';
import 'package:kfb/shared_pref.dart/sp_auth.dart';
import 'package:kfb/shared_pref.dart/sp_user_id.dart';
import 'package:kfb/widgets/app_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wp_json_api/models/responses/wc_customer_info_response.dart';
import 'package:wp_json_api/wp_json_api.dart';

class AccountDetailPage extends StatefulWidget {
  @override
  _AccountDetailPageState createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage>
    with SingleTickerProviderStateMixin {
  int _page;
  List<Order> _orders;
  WCCustomerInfoResponse _wcCustomerInfoResponse;
  bool _isLoading;
  bool _isLoadingOrders;
  int _currentTabIndex = 0;
  Widget _activeBody;
  OrdersApiProvider _ordersApiProvider = OrdersApiProvider();

  TabController _tabController;
  List<Tab> _tabs = [];

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _isLoadingOrders = true;
    _page = 1;
    _orders = [];
    _tabs = [
      new Tab(text: ""),
      new Tab(text: ""),
    ];
    _tabController = TabController(vsync: this, length: _tabs.length);
    _activeBody = showAppLoader();
    _fetchWpUserData();
    _fetchOrders();
  }

  _fetchWpUserData() async {
    WCCustomerInfoResponse wcCustomerInfoResponse =
        await WPJsonAPI.instance.api((request) async {
      return request.wcCustomerInfo(await readAuthToken());
    });

    if (wcCustomerInfoResponse != null) {
      _wcCustomerInfoResponse = wcCustomerInfoResponse;
    }
    if (this.mounted)
      setState(() {
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    _tabs = [
      new Tab(text: "Orders"),
      new Tab(text: "Settings"),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Container(
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          margin: EdgeInsets.only(left: 0),
        ),
        title: Text(
          "Account",
          style: Theme.of(context).primaryTextTheme.headline6,
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomPadding: false,
      body: SafeArea(
        minimum: safeAreaDefault(),
        child: _isLoading
            ? showAppLoader()
            : Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  _wcCustomerInfoResponse.data.avatar,
                                ),
                              ),
                              height: 90,
                              width: 90,
                            ),
                            Expanded(
                              child: Padding(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Text(
                                          (_wcCustomerInfoResponse == null
                                              ? ""
                                              : [
                                                  _wcCustomerInfoResponse
                                                      .data.firstName,
                                                  _wcCustomerInfoResponse
                                                      .data.lastName
                                                ]
                                                  .where((t) =>
                                                      (t != null || t != ""))
                                                  .toList()
                                                  .join(" ")),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                padding: EdgeInsets.only(left: 16),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          child: TabBar(
                            tabs: _tabs,
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.black87,
                            indicator: new BubbleTabIndicator(
                              indicatorHeight: 25.0,
                              indicatorColor: Colors.black87,
                              tabBarIndicatorSize: TabBarIndicatorSize.tab,
                            ),
                            onTap: _tabsTapped,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: wBoxShadow(),
                      color: Colors.white,
                    ),
                  ),
                  Expanded(child: _activeBody),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _tabsTapped(int i) {
    _currentTabIndex = i;
    setState(() {
      if (_currentTabIndex == 0) {
        _activeBody = _widgetOrders();
      } else {
        _activeBody = _widgetSettings();
      }
    });
  }

  ListView _widgetSettings() {
    return ListView(
      children: <Widget>[
        Card(
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text("Update details"),
            onTap: () =>
                Navigator.pushNamed(context, "/account-update").then((onValue) {
              setState(() {
                _isLoading = true;
              });
              _fetchWpUserData();
            }),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.local_shipping),
            title: Text("Shipping Details"),
            onTap: () =>
                Navigator.pushNamed(context, "/account-shipping-details"),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.credit_card),
            title: Text("Billing Details"),
            onTap: () =>
                Navigator.pushNamed(context, "/account-billing-details"),
          ),
        ),
        Card(
          child: ListTile(
              leading: Icon(Icons.credit_card),
              title: Text("Log Out"),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.clear();
                Navigator.pop(context);
                Navigator.pop(context);
              }),
        ),
        // Card(
        //   child: ListTile(
        //     leading: Icon(Icons.exit_to_app),
        //     title: Text("Logout"),
        //     onTap: () => authLogout(context),
        //   ),
        // ),
      ],
    );
  }

  _fetchOrders() async {
    String userId = await readUserId();

    if (userId == null) {
      setState(() {
        _isLoadingOrders = false;
        _activeBody = _widgetOrders();
      });
      return;
    }
    // _orders = await appWooSignal((api) {
    //   return api.getOrders(
    //       customer: int.parse(userId), page: _page, perPage: 100);
    _orders = await _ordersApiProvider.getOrders(
      customer: int.parse(userId),
      page: _page,
      perPage: 100,
    );
    setState(() {
      _isLoadingOrders = false;
      _activeBody = _widgetOrders();
    });
  }

  Widget _widgetOrders() {
    return _isLoadingOrders
        ? showAppLoader()
        : _orders.length <= 0
            ? Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.black54,
                      size: 40,
                    ),
                    Text(
                      "No orders found",
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemBuilder: (cxt, i) {
                  return Card(
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.only(top: 5, bottom: 5, left: 8, right: 6),
                      title: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xfffcfcfc),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "#" + _orders[i].id.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              capitalize(_orders[i].status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  formatStringCurrency(total: _orders[i].total),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText2
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  _orders[i].lineItems.length.toString() +
                                      " " +
                                      "items",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                            Text(
                              dateFormatted(
                                    date: _orders[i].dateCreated,
                                    formatType:
                                        formatForDateTime(FormatType.Date),
                                  ) +
                                  "\n" +
                                  dateFormatted(
                                    date: _orders[i].dateCreated,
                                    formatType:
                                        formatForDateTime(FormatType.Time),
                                  ),
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyText1
                                  .copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        int orderId = _orders[i].id;
                        Navigator.pushNamed(context, "/account-order-detail",
                            arguments: orderId);
                      },
                    ),
                  );
                },
                itemCount: _orders.length,
              );
  }
}
