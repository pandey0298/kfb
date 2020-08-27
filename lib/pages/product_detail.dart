import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:kfb/api_provider/api_provider.dart';
import 'package:kfb/helpers/tools.dart';
import 'package:kfb/helpers/ui.dart';
import 'package:kfb/models/cart.dart';
import 'package:kfb/models/cart_line_item.dart';
import 'package:kfb/models/response/product_variation.dart';
import 'package:kfb/models/woo_models.dart';
import 'package:kfb/widgets/app_loader.dart';
import 'package:kfb/widgets/buttons.dart';
import 'package:kfb/widgets/cart_icon.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({Key key, @required this.product}) : super(key: key);

  @override
  _ProductDetailState createState() => _ProductDetailState(this.product);
}

class _ProductDetailState extends State<ProductDetailPage> {
  _ProductDetailState(this._product);

  ApiProvider apiProvider;

  bool _isLoading;
  Product _product;
  int _quantityIndicator = 1;
  List<ProductVariation> _productVariations = [];
  ProductVariation selectedProductVariation;

  @override
  void initState() {
    apiProvider=ApiProvider();
    super.initState();
    if (_product.type == "variable") {
      _isLoading = true;
      _fetchProductVariations();
    } else {
      _isLoading = false;
    }
  }

  _fetchProductVariations() async {
    List<ProductVariation> tmpVariations = [];
    int currentPage = 1;

    bool isFetching = true;
    while (isFetching) {
      List<ProductVariation> tmp = await apiProvider
          .fetchProductVariations(_product.id, perPage: 100, page: currentPage);
      if (tmp != null && tmp.length > 0) {
        tmpVariations.addAll(tmp);
      }

      if (tmp != null && tmp.length >= 100) {
        currentPage += 1;
      } else {
        isFetching = false;
      }
    }
    _productVariations = tmpVariations;
    setState(() {
      _isLoading = false;
    });
  }

  Map<int, dynamic> _tmpAttributeObj = {};

  ProductVariation findProductVariation() {
    ProductVariation tmpProductVariation;

    Map<String, dynamic> tmpSelectedObj = {};
    (_tmpAttributeObj.values).forEach((attributeObj) {
      tmpSelectedObj[attributeObj["name"]] = attributeObj["value"];
    });

    _productVariations.forEach((productVariation) {
      Map<String, dynamic> tmpVariations = {};

      productVariation.attributes.forEach((attr) {
        tmpVariations[attr.name] = attr.option;
      });

      if (tmpVariations.toString() == tmpSelectedObj.toString()) {
        tmpProductVariation = productVariation;
      }
    });

    return tmpProductVariation;
  }

  void _modalBottomSheetOptionsForAttribute(int attributeIndex) {
    wModalBottom(
      context,
      title: "Select a" + " " + _product.attributes[attributeIndex].name,
      bodyWidget: ListView.separated(
        itemCount: _product.attributes[attributeIndex].options.length,
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(
              _product.attributes[attributeIndex].options[index],
              style: Theme.of(context).primaryTextTheme.subtitle1,
            ),
            trailing: (_tmpAttributeObj.isNotEmpty &&
                    _tmpAttributeObj.containsKey(attributeIndex) &&
                    _tmpAttributeObj[attributeIndex]["value"] ==
                        _product.attributes[attributeIndex].options[index])
                ? Icon(Icons.check, color: Colors.blueAccent)
                : null,
            onTap: () {
              _tmpAttributeObj[attributeIndex] = {
                "name": _product.attributes[attributeIndex].name,
                "value": _product.attributes[attributeIndex].options[index]
              };
              Navigator.pop(context, () {});
              Navigator.pop(context);
              _modalBottomSheetAttributes();
            },
          );
        },
      ),
    );
  }

  _itemAddToCart({CartLineItem cartLineItem}) {
    Cart.getInstance.addToCart(cartLineItem: cartLineItem);
    showStatusAlert(context,
        title: "Success",
        subtitle: "Added to cart",
        duration: 1,
        icon: Icons.add_shopping_cart);
    setState(() {});
  }

  void _modalBottomSheetAttributes() {
    wModalBottom(
      context,
      title: "Options",
      bodyWidget: ListView.separated(
        itemCount: _product.attributes.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          color: Colors.black12,
          thickness: 1,
        ),
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(_product.attributes[index].name,
                style: Theme.of(context).primaryTextTheme.subtitle1),
            subtitle: (_tmpAttributeObj.isNotEmpty &&
                    _tmpAttributeObj.containsKey(index))
                ? Text(_tmpAttributeObj[index]["value"],
                    style: Theme.of(context).primaryTextTheme.bodyText1)
                : Text(
                    "Select a" + " " + _product.attributes[index].name,
                  ),
            trailing: (_tmpAttributeObj.isNotEmpty &&
                    _tmpAttributeObj.containsKey(index))
                ? Icon(Icons.check, color: Colors.blueAccent)
                : null,
            onTap: () => _modalBottomSheetOptionsForAttribute(index),
          );
        },
      ),
      extraWidget: Container(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12, width: 1))),
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Text(
              (findProductVariation() != null
                  ? "Price" +
                      ": " +
                      formatStringCurrency(
                          total: findProductVariation().price) +
                      (findProductVariation() != null &&
                              findProductVariation().stockQuantity != null
                          ? ' (${findProductVariation().stockQuantity} in stock)'
                          : '')
                  : (((_product.attributes.length ==
                              _tmpAttributeObj.values.length) &&
                          findProductVariation() == null)
                      ? "This variation is unavailable"
                      : "Choose your options")),
              style: Theme.of(context).primaryTextTheme.subtitle1,
            ),
            Text(
              (findProductVariation() != null
                  ? findProductVariation().inStock != true
                      ? "Refilling Soon"
                      : ""
                  : ""),
              style: Theme.of(context).primaryTextTheme.subtitle1,
            ),
            wsPrimaryButton(context, title: "Add to cart", action: () {
              if (_product.attributes.length !=
                  _tmpAttributeObj.values.length) {
                showEdgeAlertWith(context,
                    title: "Oops",
                    desc: "Please select valid options first",
                    style: EdgeAlertStyle.WARNING);
                return;
              }

              if (findProductVariation() == null) {
                showEdgeAlertWith(context,
                    title: "Oops",
                    desc: "Product variation does not exist",
                    style: EdgeAlertStyle.WARNING);
                return;
              }

              if (findProductVariation() != null) {
                if (findProductVariation().inStock != true) {
                  showEdgeAlertWith(context,
                      title: "Sorry",
                      desc: "This item is not in stock",
                      style: EdgeAlertStyle.WARNING);
                  return;
                }
              }

              List<String> options = [];
              _tmpAttributeObj.forEach((k, v) {
                options.add(v["name"] + ": " + v["value"]);
              });

              CartLineItem cartLineItem = CartLineItem(
                  name: _product.name,
                  productId: _product.id,
                  variationId: findProductVariation().id,
                  quantity: 1,
                  taxStatus: findProductVariation().taxStatus,
                  shippingClassId:
                      findProductVariation().shippingClassId.toString(),
                  subtotal: findProductVariation().price,
                  stockQuantity: findProductVariation().stockQuantity,
                  isManagedStock: findProductVariation().manageStock,
                  taxClass: findProductVariation().taxClass,
                  imageSrc: (findProductVariation().image != null
                      ? findProductVariation().image.src
                      : _product.images.first.src),
                  shippingIsTaxable: _product.shippingTaxable,
                  variationOptions: options.join(", "),
                  total: findProductVariation().price);

              _itemAddToCart(cartLineItem: cartLineItem);
              Navigator.of(context).pop();
            }),
          ],
        ),
        margin: EdgeInsets.only(bottom: 10),
      ),
    );
  }

  void _modalBottomSheetMenu() {
    wModalBottom(
      context,
      title: "Description",
      bodyWidget: SingleChildScrollView(
        child: Text(
          parseHtmlString(_product.description),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          wCartIcon(context),
        ],
        title: storeLogo(height: 55),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? showAppLoader()
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.40,
                          child: SizedBox(
                            child: new Swiper(
                              itemBuilder: (BuildContext context, int index) {
                                return CachedNetworkImage(
                                  imageUrl: _product.images[index].src,
                                  placeholder: (context, url) => Center(
                                    child: new CircularProgressIndicator(
                                      strokeWidth: 2,
                                      backgroundColor: Colors.black12,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      new Icon(Icons.error),
                                  fit: BoxFit.contain,
                                );
                              },
                              itemCount: _product.images.length,
                              viewportFraction: 0.85,
                              scale: 0.9,
                              onTap: _productImageTapped,
                            ),
                          ),
                        ),
                        Container(
                          height: 100,
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  _product.name,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .copyWith(
                                          color: Colors.black87, fontSize: 20),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                flex: 4,
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      formatStringCurrency(
                                          total: _product.price),
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .headline4
                                          .copyWith(
                                            fontSize: 20,
                                          ),
                                      textAlign: TextAlign.right,
                                    ),
                                    (_product.onSale == true &&
                                            _product.type != "variable"
                                        ? Text(
                                            formatStringCurrency(
                                                total: _product.regularPrice),
                                            style: TextStyle(
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          )
                                        : null)
                                  ].where((t) => t != null).toList(),
                                ),
                                flex: 2,
                              )
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: wBoxShadow(),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          height: 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "Description",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .caption
                                        .copyWith(
                                            fontSize: 18,
                                            color: Color(0xfffa4a33)),
                                    textAlign: TextAlign.left,
                                  ),
                                  MaterialButton(
                                    child: Text(
                                      "Full description",
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .bodyText2
                                          .copyWith(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                    height: 50,
                                    minWidth: 60,
                                    onPressed: _modalBottomSheetMenu,
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  (_product.shortDescription != null &&
                                          _product.shortDescription != ""
                                      ? parseHtmlString(
                                          _product.shortDescription)
                                      : parseHtmlString(_product.description)),
                                ),
                                flex: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15.0,
                          spreadRadius: -17,
                          offset: Offset(
                            0,
                            -10,
                          ),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              (_product.stockQuantity != null &&
                                      _product.type == "simple")
                                  ? "Quantity (${_product.stockQuantity} in stock)"
                                  : "Quantity",
                              style:
                                  Theme.of(context).primaryTextTheme.bodyText1,
                            ),
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    size: 28,
                                  ),
                                  onPressed: _removeQuantityTapped,
                                ),
                                Text(
                                  _quantityIndicator.toString(),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    size: 28,
                                  ),
                                  onPressed: _addQuantityTapped,
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Align(
                                child: Text(
                                  formatStringCurrency(
                                      total: (parseWcPrice(_product.price) *
                                              _quantityIndicator)
                                          .toString()),
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .headline4,
                                  textAlign: TextAlign.center,
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            Flexible(
                              child: wsPrimaryButton(
                                context,
                                title: _product.type != "simple"
                                    ? "Select Options"
                                    : "Add to cart",
                                action: () => _addItemToCart(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    height: 140,
                  ),
                ],
              ),
      ),
    );
  }

  _addItemToCart() {
    CartLineItem cartLineItem = CartLineItem(
      name: _product.name,
      productId: _product.id,
      quantity: _quantityIndicator,
      taxStatus: _product.taxStatus,
      shippingClassId: _product.shippingClassId.toString(),
      subtotal: _product.price,
      taxClass: _product.taxClass,
      isManagedStock: _product.manageStock,
      stockQuantity: _product.stockQuantity,
      shippingIsTaxable: _product.shippingTaxable,
      imageSrc: _product.images.first.src,
      total: _product.price,
    );

    if (_product.type != "simple") {
      _modalBottomSheetAttributes();
      return;
    }
    if (!_product.inStock??false) {
      showEdgeAlertWith(context,
          title: "Sorry",
          desc: "This item is out of stock",
          style: EdgeAlertStyle.WARNING,
          icon: Icons.local_shipping);
      return;
    }
    _itemAddToCart(cartLineItem: cartLineItem);
  }

  _productImageTapped(int i) {
    Map<String, dynamic> obj = {
      "index": i,
      "images": _product.images.map((f) => f.src).toList()
    };
    Navigator.pushNamed(context, "/product-images", arguments: obj);
  }

  _addQuantityTapped() {
    if (_product.manageStock != null && _product.manageStock == true) {
      if (_quantityIndicator >= _product.stockQuantity) {
        showEdgeAlertWith(context,
            title: "Maximum quantity reached",
            desc: "${"Sorry, only"} ${_product.stockQuantity} ${"left"}",
            style: EdgeAlertStyle.INFO);
        return;
      }
    }
    if (_quantityIndicator != 0) {
      setState(() {
        _quantityIndicator++;
      });
    }
  }

  _removeQuantityTapped() {
    if ((_quantityIndicator - 1) >= 1) {
      setState(() {
        _quantityIndicator--;
      });
    }
  }
}
