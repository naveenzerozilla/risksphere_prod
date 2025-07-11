// class PaymentInfoModel {
//   String? sessionId;
//   String? status;
//   String? paymentStatus;
//   String? paymentIntent;
//   String? firestoreStatus;
//   List<Plans>? plans;
//   SessionData? sessionData;
//   String? invoiceId;
//   String? invoiceNumber;
//   String? invoicePdfUrl;
//   String? invoiceUrl;
//   String? message;
//
//   PaymentInfoModel(
//       {this.sessionId,
//       this.status,
//       this.paymentStatus,
//       this.paymentIntent,
//       this.firestoreStatus,
//       this.plans,
//       this.sessionData,
//       this.invoiceId,
//       this.invoiceNumber,
//       this.invoicePdfUrl,
//       this.invoiceUrl,
//       this.message});
//
//   PaymentInfoModel.fromJson(Map<String, dynamic> json) {
//     sessionId = json['session_id'];
//     status = json['status'];
//     paymentStatus = json['payment_status'];
//     paymentIntent = json['payment_intent'];
//     firestoreStatus = json['firestore_status'];
//     if (json['plans'] != null) {
//       plans = <Plans>[];
//       json['plans'].forEach((v) {
//         plans!.add(new Plans.fromJson(v));
//       });
//     }
//     sessionData = json['session_data'] != null
//         ? new SessionData.fromJson(json['session_data'])
//         : null;
//     invoiceId = json['invoice_id'];
//     invoiceNumber = json['invoice_number'];
//     invoicePdfUrl = json['invoice_pdf_url'];
//     invoiceUrl = json['invoice_url'];
//     message = json['message'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['session_id'] = this.sessionId;
//     data['status'] = this.status;
//     data['payment_status'] = this.paymentStatus;
//     data['payment_intent'] = this.paymentIntent;
//     data['firestore_status'] = this.firestoreStatus;
//     if (this.plans != null) {
//       data['plans'] = this.plans!.map((v) => v.toJson()).toList();
//     }
//     if (this.sessionData != null) {
//       data['session_data'] = this.sessionData!.toJson();
//     }
//     data['invoice_id'] = this.invoiceId;
//     data['invoice_number'] = this.invoiceNumber;
//     data['invoice_pdf_url'] = this.invoicePdfUrl;
//     data['invoice_url'] = this.invoiceUrl;
//     data['message'] = this.message;
//     return data;
//   }
// }
//
// class Plans {
//   String? planId;
//   String? planType;
//   String? selectedPlan;
//   String? planName;
//   String? price;
//   String? productId;
//   String? priceId;
//
//   Plans(
//       {this.planId,
//       this.planType,
//       this.selectedPlan,
//       this.planName,
//       this.price,
//       this.productId,
//       this.priceId});
//
//   Plans.fromJson(Map<String, dynamic> json) {
//     planId = json['plan_id'];
//     planType = json['plan_type'];
//     selectedPlan = json['selected_plan'];
//     planName = json['plan_name'];
//     price = json['price'];
//     productId = json['product_id'];
//     priceId = json['price_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['plan_id'] = this.planId;
//     data['plan_type'] = this.planType;
//     data['selected_plan'] = this.selectedPlan;
//     data['plan_name'] = this.planName;
//     data['price'] = this.price;
//     data['product_id'] = this.productId;
//     data['price_id'] = this.priceId;
//     return data;
//   }
// }
//
// class SessionData {
//   String? id;
//   String? object;
//   AdaptivePricing? adaptivePricing;
//   Null? afterExpiration;
//   Null? allowPromotionCodes;
//   int? amountSubtotal;
//   int? amountTotal;
//   AutomaticTax? automaticTax;
//   Null? billingAddressCollection;
//   String? cancelUrl;
//   Null? clientReferenceId;
//   Null? clientSecret;
//   CollectedInformation? collectedInformation;
//   Null? consent;
//   Null? consentCollection;
//   int? created;
//   String? currency;
//   Null? currencyConversion;
//   List<Null>? customFields;
//   CustomText? customText;
//   String? customer;
//   Null? customerCreation;
//   CustomerDetails? customerDetails;
//   Null? customerEmail;
//   List<Null>? discounts;
//   int? expiresAt;
//   Null? invoice;
//   InvoiceCreation? invoiceCreation;
//   bool? livemode;
//   Null? locale;
//   Metadata? metadata;
//   String? mode;
//   String? paymentIntent;
//   Null? paymentLink;
//   String? paymentMethodCollection;
//   Null? paymentMethodConfigurationDetails;
//   PaymentMethodOptions? paymentMethodOptions;
//   List<String>? paymentMethodTypes;
//   String? paymentStatus;
//   Null? permissions;
//   AdaptivePricing? phoneNumberCollection;
//   PresentmentDetails? presentmentDetails;
//   Null? recoveredFrom;
//   SavedPaymentMethodOptions? savedPaymentMethodOptions;
//   Null? setupIntent;
//   Null? shippingAddressCollection;
//   Null? shippingCost;
//   List<Null>? shippingOptions;
//   String? status;
//   Null? submitType;
//   Null? subscription;
//   String? successUrl;
//   TotalDetails? totalDetails;
//   String? uiMode;
//   Null? url;
//   Null? walletOptions;
//
//   SessionData(
//       {this.id,
//       this.object,
//       this.adaptivePricing,
//       this.afterExpiration,
//       this.allowPromotionCodes,
//       this.amountSubtotal,
//       this.amountTotal,
//       this.automaticTax,
//       this.billingAddressCollection,
//       this.cancelUrl,
//       this.clientReferenceId,
//       this.clientSecret,
//       this.collectedInformation,
//       this.consent,
//       this.consentCollection,
//       this.created,
//       this.currency,
//       this.currencyConversion,
//       this.customFields,
//       this.customText,
//       this.customer,
//       this.customerCreation,
//       this.customerDetails,
//       this.customerEmail,
//       this.discounts,
//       this.expiresAt,
//       this.invoice,
//       this.invoiceCreation,
//       this.livemode,
//       this.locale,
//       this.metadata,
//       this.mode,
//       this.paymentIntent,
//       this.paymentLink,
//       this.paymentMethodCollection,
//       this.paymentMethodConfigurationDetails,
//       this.paymentMethodOptions,
//       this.paymentMethodTypes,
//       this.paymentStatus,
//       this.permissions,
//       this.phoneNumberCollection,
//       this.presentmentDetails,
//       this.recoveredFrom,
//       this.savedPaymentMethodOptions,
//       this.setupIntent,
//       this.shippingAddressCollection,
//       this.shippingCost,
//       this.shippingOptions,
//       this.status,
//       this.submitType,
//       this.subscription,
//       this.successUrl,
//       this.totalDetails,
//       this.uiMode,
//       this.url,
//       this.walletOptions});
//
//   SessionData.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     object = json['object'];
//     adaptivePricing = json['adaptive_pricing'] != null
//         ? new AdaptivePricing.fromJson(json['adaptive_pricing'])
//         : null;
//     afterExpiration = json['after_expiration'];
//     allowPromotionCodes = json['allow_promotion_codes'];
//     amountSubtotal = json['amount_subtotal'];
//     amountTotal = json['amount_total'];
//     automaticTax = json['automatic_tax'] != null
//         ? new AutomaticTax.fromJson(json['automatic_tax'])
//         : null;
//     billingAddressCollection = json['billing_address_collection'];
//     cancelUrl = json['cancel_url'];
//     clientReferenceId = json['client_reference_id'];
//     clientSecret = json['client_secret'];
//     collectedInformation = json['collected_information'] != null
//         ? new CollectedInformation.fromJson(json['collected_information'])
//         : null;
//     consent = json['consent'];
//     consentCollection = json['consent_collection'];
//     created = json['created'];
//     currency = json['currency'];
//     currencyConversion = json['currency_conversion'];
//     // if (json['custom_fields'] != null) {
//     //   customFields = <Null>[];
//     //   json['custom_fields'].forEach((v) { customFields!.add(new Null.fromJson(v)); });
//     // }
//     customText = json['custom_text'] != null
//         ? new CustomText.fromJson(json['custom_text'])
//         : null;
//     customer = json['customer'];
//     customerCreation = json['customer_creation'];
//     customerDetails = json['customer_details'] != null
//         ? new CustomerDetails.fromJson(json['customer_details'])
//         : null;
//     customerEmail = json['customer_email'];
//     // if (json['discounts'] != null) {
//     //   discounts = <Null>[];
//     //   json['discounts'].forEach((v) { discounts!.add(new Null.fromJson(v)); });
//     // }
//     expiresAt = json['expires_at'];
//     invoice = json['invoice'];
//     invoiceCreation = json['invoice_creation'] != null
//         ? new InvoiceCreation.fromJson(json['invoice_creation'])
//         : null;
//     livemode = json['livemode'];
//     locale = json['locale'];
//     metadata = json['metadata'] != null
//         ? new Metadata.fromJson(json['metadata'])
//         : null;
//     mode = json['mode'];
//     paymentIntent = json['payment_intent'];
//     paymentLink = json['payment_link'];
//     paymentMethodCollection = json['payment_method_collection'];
//     paymentMethodConfigurationDetails =
//         json['payment_method_configuration_details'];
//     paymentMethodOptions = json['payment_method_options'] != null
//         ? new PaymentMethodOptions.fromJson(json['payment_method_options'])
//         : null;
//     paymentMethodTypes = json['payment_method_types'].cast<String>();
//     paymentStatus = json['payment_status'];
//     permissions = json['permissions'];
//     phoneNumberCollection = json['phone_number_collection'] != null
//         ? new AdaptivePricing.fromJson(json['phone_number_collection'])
//         : null;
//     presentmentDetails = json['presentment_details'] != null
//         ? new PresentmentDetails.fromJson(json['presentment_details'])
//         : null;
//     recoveredFrom = json['recovered_from'];
//     savedPaymentMethodOptions = json['saved_payment_method_options'] != null
//         ? new SavedPaymentMethodOptions.fromJson(
//             json['saved_payment_method_options'])
//         : null;
//     setupIntent = json['setup_intent'];
//     shippingAddressCollection = json['shipping_address_collection'];
//     shippingCost = json['shipping_cost'];
//     // if (json['shipping_options'] != null) {
//     //   shippingOptions = <Null>[];
//     //   json['shipping_options'].forEach((v) { shippingOptions!.add(new Null.fromJson(v)); });
//     // }
//     status = json['status'];
//     submitType = json['submit_type'];
//     subscription = json['subscription'];
//     successUrl = json['success_url'];
//     totalDetails = json['total_details'] != null
//         ? new TotalDetails.fromJson(json['total_details'])
//         : null;
//     uiMode = json['ui_mode'];
//     url = json['url'];
//     walletOptions = json['wallet_options'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['object'] = this.object;
//     if (this.adaptivePricing != null) {
//       data['adaptive_pricing'] = this.adaptivePricing!.toJson();
//     }
//     data['after_expiration'] = this.afterExpiration;
//     data['allow_promotion_codes'] = this.allowPromotionCodes;
//     data['amount_subtotal'] = this.amountSubtotal;
//     data['amount_total'] = this.amountTotal;
//     if (this.automaticTax != null) {
//       data['automatic_tax'] = this.automaticTax!.toJson();
//     }
//     data['billing_address_collection'] = this.billingAddressCollection;
//     data['cancel_url'] = this.cancelUrl;
//     data['client_reference_id'] = this.clientReferenceId;
//     data['client_secret'] = this.clientSecret;
//     if (this.collectedInformation != null) {
//       data['collected_information'] = this.collectedInformation!.toJson();
//     }
//     data['consent'] = this.consent;
//     data['consent_collection'] = this.consentCollection;
//     data['created'] = this.created;
//     data['currency'] = this.currency;
//     data['currency_conversion'] = this.currencyConversion;
//     // if (this.customFields != null) {
//     //   data['custom_fields'] = this.customFields!.map((v) => v.toJson()).toList();
//     // }
//     if (this.customText != null) {
//       data['custom_text'] = this.customText!.toJson();
//     }
//     data['customer'] = this.customer;
//     data['customer_creation'] = this.customerCreation;
//     if (this.customerDetails != null) {
//       data['customer_details'] = this.customerDetails!.toJson();
//     }
//     data['customer_email'] = this.customerEmail;
//     // if (this.discounts != null) {
//     //   data['discounts'] = this.discounts!.map((v) => v.toJson()).toList();
//     // }
//     data['expires_at'] = this.expiresAt;
//     data['invoice'] = this.invoice;
//     if (this.invoiceCreation != null) {
//       data['invoice_creation'] = this.invoiceCreation!.toJson();
//     }
//     data['livemode'] = this.livemode;
//     data['locale'] = this.locale;
//     if (this.metadata != null) {
//       data['metadata'] = this.metadata!.toJson();
//     }
//     data['mode'] = this.mode;
//     data['payment_intent'] = this.paymentIntent;
//     data['payment_link'] = this.paymentLink;
//     data['payment_method_collection'] = this.paymentMethodCollection;
//     data['payment_method_configuration_details'] =
//         this.paymentMethodConfigurationDetails;
//     if (this.paymentMethodOptions != null) {
//       data['payment_method_options'] = this.paymentMethodOptions!.toJson();
//     }
//     data['payment_method_types'] = this.paymentMethodTypes;
//     data['payment_status'] = this.paymentStatus;
//     data['permissions'] = this.permissions;
//     if (this.phoneNumberCollection != null) {
//       data['phone_number_collection'] = this.phoneNumberCollection!.toJson();
//     }
//     if (this.presentmentDetails != null) {
//       data['presentment_details'] = this.presentmentDetails!.toJson();
//     }
//     data['recovered_from'] = this.recoveredFrom;
//     if (this.savedPaymentMethodOptions != null) {
//       data['saved_payment_method_options'] =
//           this.savedPaymentMethodOptions!.toJson();
//     }
//     data['setup_intent'] = this.setupIntent;
//     data['shipping_address_collection'] = this.shippingAddressCollection;
//     data['shipping_cost'] = this.shippingCost;
//     // if (this.shippingOptions != null) {
//     //   data['shipping_options'] = this.shippingOptions!.map((v) => v.toJson()).toList();
//     // }
//     data['status'] = this.status;
//     data['submit_type'] = this.submitType;
//     data['subscription'] = this.subscription;
//     data['success_url'] = this.successUrl;
//     if (this.totalDetails != null) {
//       data['total_details'] = this.totalDetails!.toJson();
//     }
//     data['ui_mode'] = this.uiMode;
//     data['url'] = this.url;
//     data['wallet_options'] = this.walletOptions;
//     return data;
//   }
// }
//
// class AdaptivePricing {
//   bool? enabled;
//
//   AdaptivePricing({this.enabled});
//
//   AdaptivePricing.fromJson(Map<String, dynamic> json) {
//     enabled = json['enabled'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['enabled'] = this.enabled;
//     return data;
//   }
// }
//
// class AutomaticTax {
//   bool? enabled;
//   Null? liability;
//   Null? provider;
//   Null? status;
//
//   AutomaticTax({this.enabled, this.liability, this.provider, this.status});
//
//   AutomaticTax.fromJson(Map<String, dynamic> json) {
//     enabled = json['enabled'];
//     liability = json['liability'];
//     provider = json['provider'];
//     status = json['status'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['enabled'] = this.enabled;
//     data['liability'] = this.liability;
//     data['provider'] = this.provider;
//     data['status'] = this.status;
//     return data;
//   }
// }
//
// class CollectedInformation {
//   Null? shippingDetails;
//
//   CollectedInformation({this.shippingDetails});
//
//   CollectedInformation.fromJson(Map<String, dynamic> json) {
//     shippingDetails = json['shipping_details'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['shipping_details'] = this.shippingDetails;
//     return data;
//   }
// }
//
// class CustomText {
//   Null? afterSubmit;
//   Null? shippingAddress;
//   Null? submit;
//   Null? termsOfServiceAcceptance;
//
//   CustomText(
//       {this.afterSubmit,
//       this.shippingAddress,
//       this.submit,
//       this.termsOfServiceAcceptance});
//
//   CustomText.fromJson(Map<String, dynamic> json) {
//     afterSubmit = json['after_submit'];
//     shippingAddress = json['shipping_address'];
//     submit = json['submit'];
//     termsOfServiceAcceptance = json['terms_of_service_acceptance'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['after_submit'] = this.afterSubmit;
//     data['shipping_address'] = this.shippingAddress;
//     data['submit'] = this.submit;
//     data['terms_of_service_acceptance'] = this.termsOfServiceAcceptance;
//     return data;
//   }
// }
//
// class CustomerDetails {
//   Address? address;
//   String? email;
//   String? name;
//   Null? phone;
//   String? taxExempt;
//   List<Null>? taxIds;
//
//   CustomerDetails(
//       {this.address,
//       this.email,
//       this.name,
//       this.phone,
//       this.taxExempt,
//       this.taxIds});
//
//   CustomerDetails.fromJson(Map<String, dynamic> json) {
//     address =
//         json['address'] != null ? new Address.fromJson(json['address']) : null;
//     email = json['email'];
//     name = json['name'];
//     phone = json['phone'];
//     taxExempt = json['tax_exempt'];
//     // if (json['tax_ids'] != null) {
//     //   taxIds = <Null>[];
//     //   json['tax_ids'].forEach((v) { taxIds!.add(new Null.fromJson(v)); });
//     // }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.address != null) {
//       data['address'] = this.address!.toJson();
//     }
//     data['email'] = this.email;
//     data['name'] = this.name;
//     data['phone'] = this.phone;
//     data['tax_exempt'] = this.taxExempt;
//     // if (this.taxIds != null) {
//     //   data['tax_ids'] = this.taxIds!.map((v) => v.toJson()).toList();
//     // }
//     return data;
//   }
// }
//
// class Address {
//   Null? city;
//   String? country;
//   Null? line1;
//   Null? line2;
//   Null? postalCode;
//   Null? state;
//
//   Address(
//       {this.city,
//       this.country,
//       this.line1,
//       this.line2,
//       this.postalCode,
//       this.state});
//
//   Address.fromJson(Map<String, dynamic> json) {
//     city = json['city'];
//     country = json['country'];
//     line1 = json['line1'];
//     line2 = json['line2'];
//     postalCode = json['postal_code'];
//     state = json['state'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['city'] = this.city;
//     data['country'] = this.country;
//     data['line1'] = this.line1;
//     data['line2'] = this.line2;
//     data['postal_code'] = this.postalCode;
//     data['state'] = this.state;
//     return data;
//   }
// }
//
// class InvoiceCreation {
//   bool? enabled;
//   InvoiceData? invoiceData;
//
//   InvoiceCreation({this.enabled, this.invoiceData});
//
//   InvoiceCreation.fromJson(Map<String, dynamic> json) {
//     enabled = json['enabled'];
//     invoiceData = json['invoice_data'] != null
//         ? new InvoiceData.fromJson(json['invoice_data'])
//         : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['enabled'] = this.enabled;
//     if (this.invoiceData != null) {
//       data['invoice_data'] = this.invoiceData!.toJson();
//     }
//     return data;
//   }
// }
//
// class InvoiceData {
//   Null? accountTaxIds;
//   Null? customFields;
//   Null? description;
//   Null? footer;
//   Null? issuer;
//   Metadata? metadata;
//   Null? renderingOptions;
//
//   InvoiceData(
//       {this.accountTaxIds,
//       this.customFields,
//       this.description,
//       this.footer,
//       this.issuer,
//       this.metadata,
//       this.renderingOptions});
//
//   InvoiceData.fromJson(Map<String, dynamic> json) {
//     accountTaxIds = json['account_tax_ids'];
//     customFields = json['custom_fields'];
//     description = json['description'];
//     footer = json['footer'];
//     issuer = json['issuer'];
//     metadata = json['metadata'] != null
//         ? new Metadata.fromJson(json['metadata'])
//         : null;
//     renderingOptions = json['rendering_options'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['account_tax_ids'] = this.accountTaxIds;
//     data['custom_fields'] = this.customFields;
//     data['description'] = this.description;
//     data['footer'] = this.footer;
//     data['issuer'] = this.issuer;
//     if (this.metadata != null) {
//       data['metadata'] = this.metadata!.toJson();
//     }
//     data['rendering_options'] = this.renderingOptions;
//     return data;
//   }
// }
//
// class Metadata {
//   String? invoiceId;
//   String? invoicePdf;
//   String? userId;
//
//   Metadata({this.invoiceId, this.invoicePdf, this.userId});
//
//   Metadata.fromJson(Map<String, dynamic> json) {
//     invoiceId = json['invoice_id'];
//     invoicePdf = json['invoice_pdf'];
//     userId = json['user_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['invoice_id'] = this.invoiceId;
//     data['invoice_pdf'] = this.invoicePdf;
//     data['user_id'] = this.userId;
//     return data;
//   }
// }
//
// class PaymentMethodOptions {
//   Card? card;
//
//   PaymentMethodOptions({this.card});
//
//   PaymentMethodOptions.fromJson(Map<String, dynamic> json) {
//     card = json['card'] != null ? new Card.fromJson(json['card']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.card != null) {
//       data['card'] = this.card!.toJson();
//     }
//     return data;
//   }
// }
//
// class Card {
//   String? requestThreeDSecure;
//
//   Card({this.requestThreeDSecure});
//
//   Card.fromJson(Map<String, dynamic> json) {
//     requestThreeDSecure = json['request_three_d_secure'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['request_three_d_secure'] = this.requestThreeDSecure;
//     return data;
//   }
// }
//
// class PresentmentDetails {
//   int? presentmentAmount;
//   String? presentmentCurrency;
//
//   PresentmentDetails({this.presentmentAmount, this.presentmentCurrency});
//
//   PresentmentDetails.fromJson(Map<String, dynamic> json) {
//     presentmentAmount = json['presentment_amount'];
//     presentmentCurrency = json['presentment_currency'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['presentment_amount'] = this.presentmentAmount;
//     data['presentment_currency'] = this.presentmentCurrency;
//     return data;
//   }
// }
//
// class SavedPaymentMethodOptions {
//   List<String>? allowRedisplayFilters;
//   String? paymentMethodRemove;
//   Null? paymentMethodSave;
//
//   SavedPaymentMethodOptions(
//       {this.allowRedisplayFilters,
//       this.paymentMethodRemove,
//       this.paymentMethodSave});
//
//   SavedPaymentMethodOptions.fromJson(Map<String, dynamic> json) {
//     allowRedisplayFilters = json['allow_redisplay_filters'].cast<String>();
//     paymentMethodRemove = json['payment_method_remove'];
//     paymentMethodSave = json['payment_method_save'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['allow_redisplay_filters'] = this.allowRedisplayFilters;
//     data['payment_method_remove'] = this.paymentMethodRemove;
//     data['payment_method_save'] = this.paymentMethodSave;
//     return data;
//   }
// }
//
// class TotalDetails {
//   int? amountDiscount;
//   int? amountShipping;
//   int? amountTax;
//
//   TotalDetails({this.amountDiscount, this.amountShipping, this.amountTax});
//
//   TotalDetails.fromJson(Map<String, dynamic> json) {
//     amountDiscount = json['amount_discount'];
//     amountShipping = json['amount_shipping'];
//     amountTax = json['amount_tax'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['amount_discount'] = this.amountDiscount;
//     data['amount_shipping'] = this.amountShipping;
//     data['amount_tax'] = this.amountTax;
//     return data;
//   }
// }
