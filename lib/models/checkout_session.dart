import 'dart:convert';

import 'package:kfb/helpers/shared_pref.dart';
import 'package:kfb/helpers/tools.dart';
import 'package:kfb/models/billing_details.dart';
import 'package:kfb/models/cart.dart';
import 'package:kfb/models/customer_address.dart';
import 'package:kfb/models/payment_type.dart';
import 'package:kfb/models/response/tax_rate.dart';
import 'package:kfb/models/shipping_type.dart';

class CheckoutSession {
  String sfKeyBillingCheckout = "CS_BILLING_DETAILS";
  String sfKeyShippingCheckout = "CS_SHIPPING_DETAILS";
  bool shipToDifferentAddress = false;

  CheckoutSession._privateConstructor();
  static final CheckoutSession getInstance =
      CheckoutSession._privateConstructor();

  BillingDetails billingDetails;
  ShippingType shippingType;
  PaymentType paymentType;

  void initSession() {
    billingDetails = BillingDetails();
    shippingType = null;
  }

  void clear() {
    billingDetails = null;
    shippingType = null;
    paymentType = null;
  }

  void saveBillingAddress() {
    SharedPref sharedPref = SharedPref();
    CustomerAddress customerAddress =
        CheckoutSession.getInstance.billingDetails.billingAddress;

    String billingAddress = jsonEncode(customerAddress.toJson());
    sharedPref.save(sfKeyBillingCheckout, billingAddress);
  }

  Future<CustomerAddress> getBillingAddress() async {
    SharedPref sharedPref = SharedPref();

    String strCheckoutDetails = await sharedPref.read(sfKeyBillingCheckout);

    if (strCheckoutDetails != null && strCheckoutDetails != "") {
      return CustomerAddress.fromJson(jsonDecode(strCheckoutDetails));
    }
    return null;
  }

  void clearBillingAddress() {
    SharedPref sharedPref = SharedPref();
    sharedPref.remove(sfKeyBillingCheckout);
  }

  void saveShippingAddress() {
    SharedPref sharedPref = SharedPref();
    CustomerAddress customerAddress =
        CheckoutSession.getInstance.billingDetails.shippingAddress;

    String shippingAddress = jsonEncode(customerAddress.toJson());
    sharedPref.save(sfKeyShippingCheckout, shippingAddress);
  }

  Future<CustomerAddress> getShippingAddress() async {
    SharedPref sharedPref = SharedPref();
    String strCheckoutDetails = await sharedPref.read(sfKeyShippingCheckout);
    if (strCheckoutDetails != null && strCheckoutDetails != "") {
      return CustomerAddress.fromJson(jsonDecode(strCheckoutDetails));
    }
    return null;
  }

  void clearShippingAddress() {
    SharedPref sharedPref = SharedPref();
    sharedPref.remove(sfKeyShippingCheckout);
  }

  Future<String> total({bool withFormat, TaxRate taxRate}) async {
    double totalCart = parseWcPrice(await Cart.getInstance.getTotal());
    double totalShipping = 0;
    if (shippingType != null && shippingType.object != null) {
      switch (shippingType.methodId) {
        case "flat_rate":
          totalShipping = parseWcPrice(shippingType.cost);
          break;
        case "free_shipping":
          totalShipping = parseWcPrice(shippingType.cost);
          break;
        case "local_pickup":
          totalShipping = parseWcPrice(shippingType.cost);
          break;
        default:
          break;
      }
    }

    double total = totalCart + totalShipping;

    if (taxRate != null) {
      String taxAmount = await Cart.getInstance.taxAmount(taxRate);
      total += parseWcPrice(taxAmount);
    }

    if (withFormat != null && withFormat == true) {
      return formatDoubleCurrency(total: total);
    }
    return total.toStringAsFixed(2);
  }
}
