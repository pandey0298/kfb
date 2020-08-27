import 'package:flutter/material.dart';
import 'package:kfb/helpers/tools.dart';
import 'package:kfb/helpers/ui.dart';
import 'package:kfb/models/response/order.dart';

class CheckoutStatusPage extends StatefulWidget {
  final Order order;
  CheckoutStatusPage({Key key, @required this.order}) : super(key: key);

  @override
  _CheckoutStatusState createState() => _CheckoutStatusState(this.order);
}

class _CheckoutStatusState extends State<CheckoutStatusPage> {
  _CheckoutStatusState(this._order);

  Order _order;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: storeLogo(height: 60),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          child: Text(
                            "Order Status",
                            style: Theme.of(context).primaryTextTheme.subtitle1,
                          ),
                          padding: EdgeInsets.only(bottom: 15),
                        ),
                        Text(
                          "Thank You!",
                          style: Theme.of(context).primaryTextTheme.headline6,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "Your transaction details",
                          style: Theme.of(context).primaryTextTheme.bodyText2,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "Order Ref" + ". #" + _order.id.toString(),
                          style: Theme.of(context).primaryTextTheme.bodyText1,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 1.0),
                      ),
                    ),
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  Container(
                    child: Image(
                      image: new AssetImage("assets/images/camion.gif"),
                      height: 170,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    width: double.infinity,
                  ),
                ],
              ),
              Align(
                child: Padding(
                  child: Text(
                    "Items",
                    style: Theme.of(context).primaryTextTheme.subtitle1,
                    textAlign: TextAlign.left,
                  ),
                  padding: EdgeInsets.all(8),
                ),
                alignment: Alignment.center,
              ),
              Expanded(
                child: new ListView.builder(
                    itemCount: _order.lineItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      LineItems lineItem = _order.lineItems[index];
                      return Container(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  Text(
                                    lineItem.name,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .bodyText1,
                                    softWrap: false,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "x" + lineItem.quantity.toString(),
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .bodyText2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatStringCurrency(
                                  total: lineItem.total.toString()),
                              style:
                                  Theme.of(context).primaryTextTheme.bodyText1,
                            )
                          ],
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.all(8),
                      );
                    }),
              ),
              Align(
                child: MaterialButton(
                  child: Text("Back to Home"),
                  onPressed: () => Navigator.pushNamed(context, "/landing"),
                ),
                alignment: Alignment.bottomCenter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
