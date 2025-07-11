class TransactionModel {
  List<Result>? result;
  String? message;
  String? sessionId;
  String? status;
  String? paymentStatus;
  String? paymentIntent;
  String? firestoreStatus;
  List<Plans>? plans;
  SessionData? sessionData;
  String? invoiceId;
  String? invoiceNumber;
  String? invoicePdfUrl;
  String? invoiceUrl;

  TransactionModel({
    this.result,
    this.message,
    this.sessionId,
    this.status,
    this.paymentStatus,
    this.paymentIntent,
    this.firestoreStatus,
    this.plans,
    this.sessionData,
    this.invoiceId,
    this.invoiceNumber,
    this.invoicePdfUrl,
    this.invoiceUrl,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
    sessionId = json['session_id'];
    status = json['status'];
    paymentStatus = json['payment_status'];
    paymentIntent = json['payment_intent'];
    firestoreStatus = json['firestore_status'];
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
    sessionData = json['session_data'] != null
        ? new SessionData.fromJson(json['session_data'])
        : null;
    invoiceId = json['invoice_id'];
    invoiceNumber = json['invoice_number'];
    invoicePdfUrl = json['invoice_pdf_url'];
    invoiceUrl = json['invoice_url'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class Result {
  String? month;
  Plans? plans;
  List<Invoices>? invoices;

  Result({this.month, this.invoices, this.plans});

  Result.fromJson(Map<String, dynamic> json) {
    month = json['month'];
    plans = json['plans'] != null ? new Plans.fromJson(json['plans']) : null;
    if (json['invoices'] != null) {
      invoices = <Invoices>[];
      json['invoices'].forEach((v) {
        invoices!.add(new Invoices.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['month'] = this.month;
    data['month'] = this.month;
    if (this.invoices != null) {
      data['invoices'] = this.invoices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Invoices {
  String? invoiceId;
  String? customerId;
  String? companyId;
  String? customerEmail;
  String? userId;
  List<Plans>? plans;
  int? amount;
  String? invoicePdfUrl;
  String? status;
  StripeInvoice? stripeInvoice;
  UpdatedAt? updatedAt;
  UpdatedAt? createdAt;

  Invoices(
      {this.invoiceId,
      this.customerId,
      this.companyId,
      this.customerEmail,
      this.userId,
      this.plans,
      this.amount,
      this.invoicePdfUrl,
      this.status,
      this.stripeInvoice,
      this.updatedAt,
      this.createdAt});

  Invoices.fromJson(Map<String, dynamic> json) {
    invoiceId = json['invoice_id'];
    customerId = json['customer_id'];
    companyId = json['company_id'];
    customerEmail = json['customer_email'];
    userId = json['user_id'];
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(new Plans.fromJson(v));
      });
    }
    amount = json['amount'];
    invoicePdfUrl = json['invoice_pdf_url'];
    status = json['status'];
    stripeInvoice = json['stripe_invoice'] != null
        ? new StripeInvoice.fromJson(json['stripe_invoice'])
        : null;
    updatedAt = json['updated_at'] != null
        ? new UpdatedAt.fromJson(json['updated_at'])
        : null;
    createdAt = json['created_at'] != null
        ? new UpdatedAt.fromJson(json['created_at'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invoice_id'] = this.invoiceId;
    data['customer_id'] = this.customerId;
    data['company_id'] = this.companyId;
    data['customer_email'] = this.customerEmail;
    data['user_id'] = this.userId;
    if (this.plans != null) {
      data['plans'] = this.plans!.map((v) => v.toJson()).toList();
    }
    data['amount'] = this.amount;
    data['invoice_pdf_url'] = this.invoicePdfUrl;
    data['status'] = this.status;
    if (this.stripeInvoice != null) {
      data['stripe_invoice'] = this.stripeInvoice!.toJson();
    }
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    if (this.createdAt != null) {
      data['created_at'] = this.createdAt!.toJson();
    }
    return data;
  }
}

class SessionData {
  String? id;
  String? object;
  AdaptivePricing? adaptivePricing;
  Null? afterExpiration;
  Null? allowPromotionCodes;
  int? amountSubtotal;
  int? amountTotal;
  AutomaticTax? automaticTax;
  Null? billingAddressCollection;
  String? cancelUrl;
  Null? clientReferenceId;
  Null? clientSecret;
  CollectedInformation? collectedInformation;
  Null? consent;
  Null? consentCollection;
  int? created;
  String? currency;
  Null? currencyConversion;
  List<Null>? customFields;
  CustomText? customText;
  String? customer;
  Null? customerCreation;
  CustomerDetails? customerDetails;
  Null? customerEmail;
  List<Null>? discounts;
  int? expiresAt;
  Null? invoice;
  InvoiceCreation? invoiceCreation;
  bool? livemode;
  Null? locale;
  Metadata? metadata;
  String? mode;
  String? paymentIntent;
  Null? paymentLink;
  String? paymentMethodCollection;
  Null? paymentMethodConfigurationDetails;
  PaymentMethodOptions? paymentMethodOptions;
  List<String>? paymentMethodTypes;
  String? paymentStatus;
  Null? permissions;
  AdaptivePricing? phoneNumberCollection;
  PresentmentDetails? presentmentDetails;
  Null? recoveredFrom;
  SavedPaymentMethodOptions? savedPaymentMethodOptions;
  Null? setupIntent;
  Null? shippingAddressCollection;
  Null? shippingCost;
  List<Null>? shippingOptions;
  String? status;
  Null? submitType;
  Null? subscription;
  String? successUrl;
  TotalDetails? totalDetails;
  String? uiMode;
  Null? url;
  Null? walletOptions;

  SessionData(
      {this.id,
      this.object,
      this.adaptivePricing,
      this.afterExpiration,
      this.allowPromotionCodes,
      this.amountSubtotal,
      this.amountTotal,
      this.automaticTax,
      this.billingAddressCollection,
      this.cancelUrl,
      this.clientReferenceId,
      this.clientSecret,
      this.collectedInformation,
      this.consent,
      this.consentCollection,
      this.created,
      this.currency,
      this.currencyConversion,
      this.customFields,
      this.customText,
      this.customer,
      this.customerCreation,
      this.customerDetails,
      this.customerEmail,
      this.discounts,
      this.expiresAt,
      this.invoice,
      this.invoiceCreation,
      this.livemode,
      this.locale,
      this.metadata,
      this.mode,
      this.paymentIntent,
      this.paymentLink,
      this.paymentMethodCollection,
      this.paymentMethodConfigurationDetails,
      this.paymentMethodOptions,
      this.paymentMethodTypes,
      this.paymentStatus,
      this.permissions,
      this.phoneNumberCollection,
      this.presentmentDetails,
      this.recoveredFrom,
      this.savedPaymentMethodOptions,
      this.setupIntent,
      this.shippingAddressCollection,
      this.shippingCost,
      this.shippingOptions,
      this.status,
      this.submitType,
      this.subscription,
      this.successUrl,
      this.totalDetails,
      this.uiMode,
      this.url,
      this.walletOptions});

  SessionData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    adaptivePricing = json['adaptive_pricing'] != null
        ? new AdaptivePricing.fromJson(json['adaptive_pricing'])
        : null;
    afterExpiration = json['after_expiration'];
    allowPromotionCodes = json['allow_promotion_codes'];
    amountSubtotal = json['amount_subtotal'];
    amountTotal = json['amount_total'];
    automaticTax = json['automatic_tax'] != null
        ? new AutomaticTax.fromJson(json['automatic_tax'])
        : null;
    billingAddressCollection = json['billing_address_collection'];
    cancelUrl = json['cancel_url'];
    clientReferenceId = json['client_reference_id'];
    clientSecret = json['client_secret'];
    collectedInformation = json['collected_information'] != null
        ? new CollectedInformation.fromJson(json['collected_information'])
        : null;
    consent = json['consent'];
    consentCollection = json['consent_collection'];
    created = json['created'];
    currency = json['currency'];
    currencyConversion = json['currency_conversion'];
    // if (json['custom_fields'] != null) {
    //   customFields = <Null>[];
    //   json['custom_fields'].forEach((v) { customFields!.add(new Null.fromJson(v)); });
    // }
    customText = json['custom_text'] != null
        ? new CustomText.fromJson(json['custom_text'])
        : null;
    customer = json['customer'];
    customerCreation = json['customer_creation'];
    customerDetails = json['customer_details'] != null
        ? new CustomerDetails.fromJson(json['customer_details'])
        : null;
    customerEmail = json['customer_email'];
    // if (json['discounts'] != null) {
    //   discounts = <Null>[];
    //   json['discounts'].forEach((v) { discounts!.add(new Null.fromJson(v)); });
    // }
    expiresAt = json['expires_at'];
    invoice = json['invoice'];
    invoiceCreation = json['invoice_creation'] != null
        ? new InvoiceCreation.fromJson(json['invoice_creation'])
        : null;
    livemode = json['livemode'];
    locale = json['locale'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    mode = json['mode'];
    paymentIntent = json['payment_intent'];
    paymentLink = json['payment_link'];
    paymentMethodCollection = json['payment_method_collection'];
    paymentMethodConfigurationDetails =
        json['payment_method_configuration_details'];
    paymentMethodOptions = json['payment_method_options'] != null
        ? new PaymentMethodOptions.fromJson(json['payment_method_options'])
        : null;
    paymentMethodTypes = json['payment_method_types'].cast<String>();
    paymentStatus = json['payment_status'];
    permissions = json['permissions'];
    phoneNumberCollection = json['phone_number_collection'] != null
        ? new AdaptivePricing.fromJson(json['phone_number_collection'])
        : null;
    presentmentDetails = json['presentment_details'] != null
        ? new PresentmentDetails.fromJson(json['presentment_details'])
        : null;
    recoveredFrom = json['recovered_from'];
    savedPaymentMethodOptions = json['saved_payment_method_options'] != null
        ? new SavedPaymentMethodOptions.fromJson(
            json['saved_payment_method_options'])
        : null;
    setupIntent = json['setup_intent'];
    shippingAddressCollection = json['shipping_address_collection'];
    shippingCost = json['shipping_cost'];
    // if (json['shipping_options'] != null) {
    //   shippingOptions = <Null>[];
    //   json['shipping_options'].forEach((v) { shippingOptions!.add(new Null.fromJson(v)); });
    // }
    status = json['status'];
    submitType = json['submit_type'];
    subscription = json['subscription'];
    successUrl = json['success_url'];
    totalDetails = json['total_details'] != null
        ? new TotalDetails.fromJson(json['total_details'])
        : null;
    uiMode = json['ui_mode'];
    url = json['url'];
    walletOptions = json['wallet_options'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['object'] = this.object;
    if (this.adaptivePricing != null) {
      data['adaptive_pricing'] = this.adaptivePricing!.toJson();
    }
    data['after_expiration'] = this.afterExpiration;
    data['allow_promotion_codes'] = this.allowPromotionCodes;
    data['amount_subtotal'] = this.amountSubtotal;
    data['amount_total'] = this.amountTotal;
    if (this.automaticTax != null) {
      data['automatic_tax'] = this.automaticTax!.toJson();
    }
    data['billing_address_collection'] = this.billingAddressCollection;
    data['cancel_url'] = this.cancelUrl;
    data['client_reference_id'] = this.clientReferenceId;
    data['client_secret'] = this.clientSecret;
    if (this.collectedInformation != null) {
      data['collected_information'] = this.collectedInformation!.toJson();
    }
    data['consent'] = this.consent;
    data['consent_collection'] = this.consentCollection;
    data['created'] = this.created;
    data['currency'] = this.currency;
    data['currency_conversion'] = this.currencyConversion;
    // if (this.customFields != null) {
    //   data['custom_fields'] = this.customFields!.map((v) => v.toJson()).toList();
    // }
    if (this.customText != null) {
      data['custom_text'] = this.customText!.toJson();
    }
    data['customer'] = this.customer;
    data['customer_creation'] = this.customerCreation;
    if (this.customerDetails != null) {
      data['customer_details'] = this.customerDetails!.toJson();
    }
    data['customer_email'] = this.customerEmail;
    // if (this.discounts != null) {
    //   data['discounts'] = this.discounts!.map((v) => v.toJson()).toList();
    // }
    data['expires_at'] = this.expiresAt;
    data['invoice'] = this.invoice;
    if (this.invoiceCreation != null) {
      data['invoice_creation'] = this.invoiceCreation!.toJson();
    }
    data['livemode'] = this.livemode;
    data['locale'] = this.locale;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['mode'] = this.mode;
    data['payment_intent'] = this.paymentIntent;
    data['payment_link'] = this.paymentLink;
    data['payment_method_collection'] = this.paymentMethodCollection;
    data['payment_method_configuration_details'] =
        this.paymentMethodConfigurationDetails;
    if (this.paymentMethodOptions != null) {
      data['payment_method_options'] = this.paymentMethodOptions!.toJson();
    }
    data['payment_method_types'] = this.paymentMethodTypes;
    data['payment_status'] = this.paymentStatus;
    data['permissions'] = this.permissions;
    if (this.phoneNumberCollection != null) {
      data['phone_number_collection'] = this.phoneNumberCollection!.toJson();
    }
    if (this.presentmentDetails != null) {
      data['presentment_details'] = this.presentmentDetails!.toJson();
    }
    data['recovered_from'] = this.recoveredFrom;
    if (this.savedPaymentMethodOptions != null) {
      data['saved_payment_method_options'] =
          this.savedPaymentMethodOptions!.toJson();
    }
    data['setup_intent'] = this.setupIntent;
    data['shipping_address_collection'] = this.shippingAddressCollection;
    data['shipping_cost'] = this.shippingCost;
    // if (this.shippingOptions != null) {
    //   data['shipping_options'] = this.shippingOptions!.map((v) => v.toJson()).toList();
    // }
    data['status'] = this.status;
    data['submit_type'] = this.submitType;
    data['subscription'] = this.subscription;
    data['success_url'] = this.successUrl;
    if (this.totalDetails != null) {
      data['total_details'] = this.totalDetails!.toJson();
    }
    data['ui_mode'] = this.uiMode;
    data['url'] = this.url;
    data['wallet_options'] = this.walletOptions;
    return data;
  }
}

class CustomerDetails {
  Address? address;
  String? email;
  String? name;
  Null? phone;
  String? taxExempt;
  List<Null>? taxIds;

  CustomerDetails(
      {this.address,
      this.email,
      this.name,
      this.phone,
      this.taxExempt,
      this.taxIds});

  CustomerDetails.fromJson(Map<String, dynamic> json) {
    address =
        json['address'] != null ? new Address.fromJson(json['address']) : null;
    email = json['email'];
    name = json['name'];
    phone = json['phone'];
    taxExempt = json['tax_exempt'];
    // if (json['tax_ids'] != null) {
    //   taxIds = <Null>[];
    //   json['tax_ids'].forEach((v) { taxIds!.add(new Null.fromJson(v)); });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.address != null) {
      data['address'] = this.address!.toJson();
    }
    data['email'] = this.email;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['tax_exempt'] = this.taxExempt;
    // if (this.taxIds != null) {
    //   data['tax_ids'] = this.taxIds!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Address {
  Null? city;
  String? country;
  Null? line1;
  Null? line2;
  Null? postalCode;
  Null? state;

  Address(
      {this.city,
      this.country,
      this.line1,
      this.line2,
      this.postalCode,
      this.state});

  Address.fromJson(Map<String, dynamic> json) {
    city = json['city'];
    country = json['country'];
    line1 = json['line1'];
    line2 = json['line2'];
    postalCode = json['postal_code'];
    state = json['state'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['city'] = this.city;
    data['country'] = this.country;
    data['line1'] = this.line1;
    data['line2'] = this.line2;
    data['postal_code'] = this.postalCode;
    data['state'] = this.state;
    return data;
  }
}

class InvoiceData {
  Null? accountTaxIds;
  Null? customFields;
  Null? description;
  Null? footer;
  Null? issuer;
  Metadata? metadata;
  Null? renderingOptions;

  InvoiceData(
      {this.accountTaxIds,
      this.customFields,
      this.description,
      this.footer,
      this.issuer,
      this.metadata,
      this.renderingOptions});

  InvoiceData.fromJson(Map<String, dynamic> json) {
    accountTaxIds = json['account_tax_ids'];
    customFields = json['custom_fields'];
    description = json['description'];
    footer = json['footer'];
    issuer = json['issuer'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    renderingOptions = json['rendering_options'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['account_tax_ids'] = this.accountTaxIds;
    data['custom_fields'] = this.customFields;
    data['description'] = this.description;
    data['footer'] = this.footer;
    data['issuer'] = this.issuer;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['rendering_options'] = this.renderingOptions;
    return data;
  }
}

class InvoiceCreation {
  bool? enabled;
  InvoiceData? invoiceData;

  InvoiceCreation({this.enabled, this.invoiceData});

  InvoiceCreation.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
    invoiceData = json['invoice_data'] != null
        ? new InvoiceData.fromJson(json['invoice_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    if (this.invoiceData != null) {
      data['invoice_data'] = this.invoiceData!.toJson();
    }
    return data;
  }
}

class TotalDetails {
  int? amountDiscount;
  int? amountShipping;
  int? amountTax;

  TotalDetails({this.amountDiscount, this.amountShipping, this.amountTax});

  TotalDetails.fromJson(Map<String, dynamic> json) {
    amountDiscount = json['amount_discount'];
    amountShipping = json['amount_shipping'];
    amountTax = json['amount_tax'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount_discount'] = this.amountDiscount;
    data['amount_shipping'] = this.amountShipping;
    data['amount_tax'] = this.amountTax;
    return data;
  }
}

class SavedPaymentMethodOptions {
  List<String>? allowRedisplayFilters;
  String? paymentMethodRemove;
  Null? paymentMethodSave;

  SavedPaymentMethodOptions(
      {this.allowRedisplayFilters,
      this.paymentMethodRemove,
      this.paymentMethodSave});

  SavedPaymentMethodOptions.fromJson(Map<String, dynamic> json) {
    allowRedisplayFilters = json['allow_redisplay_filters'].cast<String>();
    paymentMethodRemove = json['payment_method_remove'];
    paymentMethodSave = json['payment_method_save'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['allow_redisplay_filters'] = this.allowRedisplayFilters;
    data['payment_method_remove'] = this.paymentMethodRemove;
    data['payment_method_save'] = this.paymentMethodSave;
    return data;
  }
}

class AdaptivePricing {
  bool? enabled;

  AdaptivePricing({this.enabled});

  AdaptivePricing.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    return data;
  }
}

class CustomText {
  Null? afterSubmit;
  Null? shippingAddress;
  Null? submit;
  Null? termsOfServiceAcceptance;

  CustomText(
      {this.afterSubmit,
      this.shippingAddress,
      this.submit,
      this.termsOfServiceAcceptance});

  CustomText.fromJson(Map<String, dynamic> json) {
    afterSubmit = json['after_submit'];
    shippingAddress = json['shipping_address'];
    submit = json['submit'];
    termsOfServiceAcceptance = json['terms_of_service_acceptance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['after_submit'] = this.afterSubmit;
    data['shipping_address'] = this.shippingAddress;
    data['submit'] = this.submit;
    data['terms_of_service_acceptance'] = this.termsOfServiceAcceptance;
    return data;
  }
}

class Plans {
  List<OWOmeps4vmW4A8zPXRws>? oWOmeps4vmW4A8zPXRws;
  String? planId;
  String? planType;
  String? selectedPlan;
  String? planName;
  dynamic price;
  String? productId;
  String? priceId;

  Plans(
      {this.oWOmeps4vmW4A8zPXRws,
      this.planId,
      this.planType,
      this.selectedPlan,
      this.planName,
      this.price,
      this.productId,
      this.priceId});

  Plans.fromJson(Map<String, dynamic> json) {
    if (json['OWOmeps4vmW4A8zPXRws'] != null) {
      oWOmeps4vmW4A8zPXRws = <OWOmeps4vmW4A8zPXRws>[];
      json['OWOmeps4vmW4A8zPXRws'].forEach((v) {
        oWOmeps4vmW4A8zPXRws!.add(new OWOmeps4vmW4A8zPXRws.fromJson(v));
      });
    }
    planId = json['plan_id'];
    planType = json['plan_type'];
    selectedPlan = json['selected_plan'];
    planName = json['plan_name'];
    price = json['price'];
    productId = json['product_id'];
    priceId = json['price_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.oWOmeps4vmW4A8zPXRws != null) {
      data['OWOmeps4vmW4A8zPXRws'] =
          this.oWOmeps4vmW4A8zPXRws!.map((v) => v.toJson()).toList();
    }
    data['plan_id'] = this.planId;
    data['plan_type'] = this.planType;
    data['selected_plan'] = this.selectedPlan;
    data['plan_name'] = this.planName;
    data['price'] = this.price;
    data['product_id'] = this.productId;
    data['price_id'] = this.priceId;
    return data;
  }
}

class OWOmeps4vmW4A8zPXRws {
  String? sessionId;
  String? type;
  String? docId;
  String? planId;
  Plan? plan;
  String? allCredits;
  String? availableCredits;
  String? userName;
  String? userEmail;
  String? userId;
  String? companyId;
  String? companyName;
  String? planName;
  bool? activated;
  ExpiresAt? expiresAt;
  String? amount;
  String? invoiceId;
  String? invoiceNumber;
  String? invoicePdfUrl;
  String? invoiceUrl;
  ExpiresAt? transactionDate;
  ExpiresAt? updatedAt;

  OWOmeps4vmW4A8zPXRws(
      {this.sessionId,
      this.type,
      this.docId,
      this.planId,
      this.plan,
      this.allCredits,
      this.availableCredits,
      this.userName,
      this.userEmail,
      this.userId,
      this.companyId,
      this.companyName,
      this.planName,
      this.activated,
      this.expiresAt,
      this.amount,
      this.invoiceId,
      this.invoiceNumber,
      this.invoicePdfUrl,
      this.invoiceUrl,
      this.transactionDate,
      this.updatedAt});

  OWOmeps4vmW4A8zPXRws.fromJson(Map<String, dynamic> json) {
    sessionId = json['session_id'];
    type = json['type'];
    docId = json['doc_id'];
    planId = json['plan_id'];
    plan = json['plan'] != null ? new Plan.fromJson(json['plan']) : null;
    allCredits = json['all_credits'];
    availableCredits = json['available_credits'];
    userName = json['user_name'];
    userEmail = json['user_email'];
    userId = json['user_id'];
    companyId = json['company_id'];
    companyName = json['company_name'];
    planName = json['plan_name'];
    activated = json['activated'];
    expiresAt = json['expires_at'] != null
        ? new ExpiresAt.fromJson(json['expires_at'])
        : null;
    amount = json['amount'];
    invoiceId = json['invoice_id'];
    invoiceNumber = json['invoice_number'];
    invoicePdfUrl = json['invoice_pdf_url'];
    invoiceUrl = json['invoice_url'];
    transactionDate = json['transaction_date'] != null
        ? new ExpiresAt.fromJson(json['transaction_date'])
        : null;
    updatedAt = json['updated_at'] != null
        ? new ExpiresAt.fromJson(json['updated_at'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['session_id'] = this.sessionId;
    data['type'] = this.type;
    data['doc_id'] = this.docId;
    data['plan_id'] = this.planId;
    if (this.plan != null) {
      data['plan'] = this.plan!.toJson();
    }
    data['all_credits'] = this.allCredits;
    data['available_credits'] = this.availableCredits;
    data['user_name'] = this.userName;
    data['user_email'] = this.userEmail;
    data['user_id'] = this.userId;
    data['company_id'] = this.companyId;
    data['company_name'] = this.companyName;
    data['plan_name'] = this.planName;
    data['activated'] = this.activated;
    if (this.expiresAt != null) {
      data['expires_at'] = this.expiresAt!.toJson();
    }
    data['amount'] = this.amount;
    data['invoice_id'] = this.invoiceId;
    data['invoice_number'] = this.invoiceNumber;
    data['invoice_pdf_url'] = this.invoicePdfUrl;
    data['invoice_url'] = this.invoiceUrl;
    if (this.transactionDate != null) {
      data['transaction_date'] = this.transactionDate!.toJson();
    }
    if (this.updatedAt != null) {
      data['updated_at'] = this.updatedAt!.toJson();
    }
    return data;
  }
}

class Plan {
  String? planId;
  String? planType;
  String? selectedPlan;
  String? planName;
  String? price;
  String? productId;
  String? priceId;

  Plan(
      {this.planId,
      this.planType,
      this.selectedPlan,
      this.planName,
      this.price,
      this.productId,
      this.priceId});

  Plan.fromJson(Map<String, dynamic> json) {
    planId = json['plan_id'];
    planType = json['plan_type'];
    selectedPlan = json['selected_plan'];
    planName = json['plan_name'];
    price = json['price'];
    productId = json['product_id'];
    priceId = json['price_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['plan_id'] = this.planId;
    data['plan_type'] = this.planType;
    data['selected_plan'] = this.selectedPlan;
    data['plan_name'] = this.planName;
    data['price'] = this.price;
    data['product_id'] = this.productId;
    data['price_id'] = this.priceId;
    return data;
  }
}

class ExpiresAt {
  int? iSeconds;
  int? iNanoseconds;

  ExpiresAt({this.iSeconds, this.iNanoseconds});

  ExpiresAt.fromJson(Map<String, dynamic> json) {
    iSeconds = json['_seconds'];
    iNanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_seconds'] = this.iSeconds;
    data['_nanoseconds'] = this.iNanoseconds;
    return data;
  }
}

class StripeInvoice {
  String? id;
  String? object;
  String? accountCountry;
  String? accountName;
  Null? accountTaxIds;
  int? amountDue;
  int? amountOverpaid;
  int? amountPaid;
  int? amountRemaining;
  int? amountShipping;
  Null? application;
  int? attemptCount;
  bool? attempted;
  bool? autoAdvance;
  AutomaticTax? automaticTax;
  Null? automaticallyFinalizesAt;
  String? billingReason;
  String? collectionMethod;
  int? created;
  String? currency;
  Null? customFields;
  String? customer;
  Null? customerAddress;
  String? customerEmail;
  Null? customerName;
  Null? customerPhone;
  Null? customerShipping;
  String? customerTaxExempt;
  List<Null>? customerTaxIds;
  Null? defaultPaymentMethod;
  Null? defaultSource;
  List<Null>? defaultTaxRates;
  String? description;
  List<Null>? discounts;
  Null? dueDate;
  int? effectiveAt;
  int? endingBalance;
  Null? footer;
  Null? fromInvoice;
  String? hostedInvoiceUrl;
  String? invoicePdf;
  Issuer? issuer;
  Null? lastFinalizationError;
  Null? latestRevision;
  Lines? lines;
  bool? livemode;
  Metadata? metadata;
  Null? nextPaymentAttempt;
  String? number;
  Null? onBehalfOf;
  Null? parent;
  PaymentSettings? paymentSettings;
  int? periodEnd;
  int? periodStart;
  int? postPaymentCreditNotesAmount;
  int? prePaymentCreditNotesAmount;
  Null? receiptNumber;
  Rendering? rendering;
  Null? shippingCost;
  Null? shippingDetails;
  int? startingBalance;
  Null? statementDescriptor;
  String? status;
  StatusTransitions? statusTransitions;
  int? subtotal;
  int? subtotalExcludingTax;
  Null? testClock;
  int? total;
  List<Null>? totalDiscountAmounts;
  int? totalExcludingTax;
  List<Null>? totalPretaxCreditAmounts;
  List<Null>? totalTaxes;
  int? webhooksDeliveredAt;

  StripeInvoice(
      {this.id,
      this.object,
      this.accountCountry,
      this.accountName,
      this.accountTaxIds,
      this.amountDue,
      this.amountOverpaid,
      this.amountPaid,
      this.amountRemaining,
      this.amountShipping,
      this.application,
      this.attemptCount,
      this.attempted,
      this.autoAdvance,
      this.automaticTax,
      this.automaticallyFinalizesAt,
      this.billingReason,
      this.collectionMethod,
      this.created,
      this.currency,
      this.customFields,
      this.customer,
      this.customerAddress,
      this.customerEmail,
      this.customerName,
      this.customerPhone,
      this.customerShipping,
      this.customerTaxExempt,
      this.customerTaxIds,
      this.defaultPaymentMethod,
      this.defaultSource,
      this.defaultTaxRates,
      this.description,
      this.discounts,
      this.dueDate,
      this.effectiveAt,
      this.endingBalance,
      this.footer,
      this.fromInvoice,
      this.hostedInvoiceUrl,
      this.invoicePdf,
      this.issuer,
      this.lastFinalizationError,
      this.latestRevision,
      this.lines,
      this.livemode,
      this.metadata,
      this.nextPaymentAttempt,
      this.number,
      this.onBehalfOf,
      this.parent,
      this.paymentSettings,
      this.periodEnd,
      this.periodStart,
      this.postPaymentCreditNotesAmount,
      this.prePaymentCreditNotesAmount,
      this.receiptNumber,
      this.rendering,
      this.shippingCost,
      this.shippingDetails,
      this.startingBalance,
      this.statementDescriptor,
      this.status,
      this.statusTransitions,
      this.subtotal,
      this.subtotalExcludingTax,
      this.testClock,
      this.total,
      this.totalDiscountAmounts,
      this.totalExcludingTax,
      this.totalPretaxCreditAmounts,
      this.totalTaxes,
      this.webhooksDeliveredAt});

  StripeInvoice.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    accountCountry = json['account_country'];
    accountName = json['account_name'];
    accountTaxIds = json['account_tax_ids'];
    amountDue = json['amount_due'];
    amountOverpaid = json['amount_overpaid'];
    amountPaid = json['amount_paid'];
    amountRemaining = json['amount_remaining'];
    amountShipping = json['amount_shipping'];
    application = json['application'];
    attemptCount = json['attempt_count'];
    attempted = json['attempted'];
    autoAdvance = json['auto_advance'];
    automaticTax = json['automatic_tax'] != null
        ? new AutomaticTax.fromJson(json['automatic_tax'])
        : null;
    automaticallyFinalizesAt = json['automatically_finalizes_at'];
    billingReason = json['billing_reason'];
    collectionMethod = json['collection_method'];
    created = json['created'];
    currency = json['currency'];
    customFields = json['custom_fields'];
    customer = json['customer'];
    customerAddress = json['customer_address'];
    customerEmail = json['customer_email'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerShipping = json['customer_shipping'];
    customerTaxExempt = json['customer_tax_exempt'];
    // if (json['customer_tax_ids'] != null) {
    //   customerTaxIds = <Null>[];
    //   json['customer_tax_ids'].forEach((v) { customerTaxIds!.add(new Null.fromJson(v)); });
    // }
    defaultPaymentMethod = json['default_payment_method'];
    defaultSource = json['default_source'];
    // if (json['default_tax_rates'] != null) {
    //   defaultTaxRates = <Null>[];
    //   json['default_tax_rates'].forEach((v) { defaultTaxRates!.add(new Null.fromJson(v)); });
    // }
    description = json['description'];
    // if (json['discounts'] != null) {
    //   discounts = <Null>[];
    //   json['discounts'].forEach((v) { discounts!.add(new Null.fromJson(v)); });
    // }
    dueDate = json['due_date'];
    effectiveAt = json['effective_at'];
    endingBalance = json['ending_balance'];
    footer = json['footer'];
    fromInvoice = json['from_invoice'];
    hostedInvoiceUrl = json['hosted_invoice_url'];
    invoicePdf = json['invoice_pdf'];
    issuer =
        json['issuer'] != null ? new Issuer.fromJson(json['issuer']) : null;
    lastFinalizationError = json['last_finalization_error'];
    latestRevision = json['latest_revision'];
    lines = json['lines'] != null ? new Lines.fromJson(json['lines']) : null;
    livemode = json['livemode'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    nextPaymentAttempt = json['next_payment_attempt'];
    number = json['number'];
    onBehalfOf = json['on_behalf_of'];
    parent = json['parent'];
    paymentSettings = json['payment_settings'] != null
        ? new PaymentSettings.fromJson(json['payment_settings'])
        : null;
    periodEnd = json['period_end'];
    periodStart = json['period_start'];
    postPaymentCreditNotesAmount = json['post_payment_credit_notes_amount'];
    prePaymentCreditNotesAmount = json['pre_payment_credit_notes_amount'];
    receiptNumber = json['receipt_number'];
    rendering = json['rendering'] != null
        ? new Rendering.fromJson(json['rendering'])
        : null;
    shippingCost = json['shipping_cost'];
    shippingDetails = json['shipping_details'];
    startingBalance = json['starting_balance'];
    statementDescriptor = json['statement_descriptor'];
    status = json['status'];
    statusTransitions = json['status_transitions'] != null
        ? new StatusTransitions.fromJson(json['status_transitions'])
        : null;
    subtotal = json['subtotal'];
    subtotalExcludingTax = json['subtotal_excluding_tax'];
    testClock = json['test_clock'];
    total = json['total'];
    // if (json['total_discount_amounts'] != null) {
    //   totalDiscountAmounts = <Null>[];
    //   json['total_discount_amounts'].forEach((v) { totalDiscountAmounts!.add(new Null.fromJson(v)); });
    // }
    totalExcludingTax = json['total_excluding_tax'];
    // if (json['total_pretax_credit_amounts'] != null) {
    //   totalPretaxCreditAmounts = <Null>[];
    //   json['total_pretax_credit_amounts'].forEach((v) { totalPretaxCreditAmounts!.add(new Null.fromJson(v)); });
    // }
    // if (json['total_taxes'] != null) {
    //   totalTaxes = <Null>[];
    //   json['total_taxes'].forEach((v) { totalTaxes!.add(new Null.fromJson(v)); });
    // }
    webhooksDeliveredAt = json['webhooks_delivered_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['object'] = this.object;
    data['account_country'] = this.accountCountry;
    data['account_name'] = this.accountName;
    data['account_tax_ids'] = this.accountTaxIds;
    data['amount_due'] = this.amountDue;
    data['amount_overpaid'] = this.amountOverpaid;
    data['amount_paid'] = this.amountPaid;
    data['amount_remaining'] = this.amountRemaining;
    data['amount_shipping'] = this.amountShipping;
    data['application'] = this.application;
    data['attempt_count'] = this.attemptCount;
    data['attempted'] = this.attempted;
    data['auto_advance'] = this.autoAdvance;
    if (this.automaticTax != null) {
      data['automatic_tax'] = this.automaticTax!.toJson();
    }
    data['automatically_finalizes_at'] = this.automaticallyFinalizesAt;
    data['billing_reason'] = this.billingReason;
    data['collection_method'] = this.collectionMethod;
    data['created'] = this.created;
    data['currency'] = this.currency;
    data['custom_fields'] = this.customFields;
    data['customer'] = this.customer;
    data['customer_address'] = this.customerAddress;
    data['customer_email'] = this.customerEmail;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_shipping'] = this.customerShipping;
    data['customer_tax_exempt'] = this.customerTaxExempt;
    // if (this.customerTaxIds != null) {
    //   data['customer_tax_ids'] = this.customerTaxIds!.map((v) => v.toJson()).toList();
    // }
    data['default_payment_method'] = this.defaultPaymentMethod;
    data['default_source'] = this.defaultSource;
    // if (this.defaultTaxRates != null) {
    //   data['default_tax_rates'] = this.defaultTaxRates!.map((v) => v.toJson()).toList();
    // }
    data['description'] = this.description;
    // if (this.discounts != null) {
    //   data['discounts'] = this.discounts!.map((v) => v.toJson()).toList();
    // }
    data['due_date'] = this.dueDate;
    data['effective_at'] = this.effectiveAt;
    data['ending_balance'] = this.endingBalance;
    data['footer'] = this.footer;
    data['from_invoice'] = this.fromInvoice;
    data['hosted_invoice_url'] = this.hostedInvoiceUrl;
    data['invoice_pdf'] = this.invoicePdf;
    if (this.issuer != null) {
      data['issuer'] = this.issuer!.toJson();
    }
    data['last_finalization_error'] = this.lastFinalizationError;
    data['latest_revision'] = this.latestRevision;
    if (this.lines != null) {
      data['lines'] = this.lines!.toJson();
    }
    data['livemode'] = this.livemode;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    data['next_payment_attempt'] = this.nextPaymentAttempt;
    data['number'] = this.number;
    data['on_behalf_of'] = this.onBehalfOf;
    data['parent'] = this.parent;
    if (this.paymentSettings != null) {
      data['payment_settings'] = this.paymentSettings!.toJson();
    }
    data['period_end'] = this.periodEnd;
    data['period_start'] = this.periodStart;
    data['post_payment_credit_notes_amount'] =
        this.postPaymentCreditNotesAmount;
    data['pre_payment_credit_notes_amount'] = this.prePaymentCreditNotesAmount;
    data['receipt_number'] = this.receiptNumber;
    if (this.rendering != null) {
      data['rendering'] = this.rendering!.toJson();
    }
    data['shipping_cost'] = this.shippingCost;
    data['shipping_details'] = this.shippingDetails;
    data['starting_balance'] = this.startingBalance;
    data['statement_descriptor'] = this.statementDescriptor;
    data['status'] = this.status;
    if (this.statusTransitions != null) {
      data['status_transitions'] = this.statusTransitions!.toJson();
    }
    data['subtotal'] = this.subtotal;
    data['subtotal_excluding_tax'] = this.subtotalExcludingTax;
    data['test_clock'] = this.testClock;
    data['total'] = this.total;
    // if (this.totalDiscountAmounts != null) {
    //   data['total_discount_amounts'] = this.totalDiscountAmounts!.map((v) => v.toJson()).toList();
    // }
    data['total_excluding_tax'] = this.totalExcludingTax;
    // if (this.totalPretaxCreditAmounts != null) {
    //   data['total_pretax_credit_amounts'] = this.totalPretaxCreditAmounts!.map((v) => v.toJson()).toList();
    // }
    // if (this.totalTaxes != null) {
    //   data['total_taxes'] = this.totalTaxes!.map((v) => v.toJson()).toList();
    // }
    data['webhooks_delivered_at'] = this.webhooksDeliveredAt;
    return data;
  }
}

class CollectedInformation {
  Null? shippingDetails;

  CollectedInformation({this.shippingDetails});

  CollectedInformation.fromJson(Map<String, dynamic> json) {
    shippingDetails = json['shipping_details'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['shipping_details'] = this.shippingDetails;
    return data;
  }
}

class AutomaticTax {
  Null? disabledReason;
  bool? enabled;
  Null? liability;
  Null? provider;
  Null? status;

  AutomaticTax(
      {this.disabledReason,
      this.enabled,
      this.liability,
      this.provider,
      this.status});

  AutomaticTax.fromJson(Map<String, dynamic> json) {
    disabledReason = json['disabled_reason'];
    enabled = json['enabled'];
    liability = json['liability'];
    provider = json['provider'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['disabled_reason'] = this.disabledReason;
    data['enabled'] = this.enabled;
    data['liability'] = this.liability;
    data['provider'] = this.provider;
    data['status'] = this.status;
    return data;
  }
}

class Issuer {
  String? type;

  Issuer({this.type});

  Issuer.fromJson(Map<String, dynamic> json) {
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    return data;
  }
}

class Lines {
  String? object;
  List<Data>? data;
  bool? hasMore;
  int? totalCount;
  String? url;

  Lines({this.object, this.data, this.hasMore, this.totalCount, this.url});

  Lines.fromJson(Map<String, dynamic> json) {
    object = json['object'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    hasMore = json['has_more'];
    totalCount = json['total_count'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['object'] = this.object;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['has_more'] = this.hasMore;
    data['total_count'] = this.totalCount;
    data['url'] = this.url;
    return data;
  }
}

class Data {
  String? id;
  String? object;
  int? amount;
  String? currency;
  String? description;
  List<Null>? discountAmounts;
  bool? discountable;
  List<Null>? discounts;
  String? invoice;
  bool? livemode;
  Metadata? metadata;
  Parent? parent;
  Period? period;
  List<Null>? pretaxCreditAmounts;
  Pricing? pricing;
  int? quantity;
  List<Null>? taxes;

  Data(
      {this.id,
      this.object,
      this.amount,
      this.currency,
      this.description,
      this.discountAmounts,
      this.discountable,
      this.discounts,
      this.invoice,
      this.livemode,
      this.metadata,
      this.parent,
      this.period,
      this.pretaxCreditAmounts,
      this.pricing,
      this.quantity,
      this.taxes});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    amount = json['amount'];
    currency = json['currency'];
    description = json['description'];
    // if (json['discount_amounts'] != null) {
    //   discountAmounts = <Null>[];
    //   json['discount_amounts'].forEach((v) { discountAmounts!.add(new Null.fromJson(v)); });
    // }
    discountable = json['discountable'];
    // if (json['discounts'] != null) {
    //   discounts = <Null>[];
    //   json['discounts'].forEach((v) { discounts!.add(new Null.fromJson(v)); });
    // }
    invoice = json['invoice'];
    livemode = json['livemode'];
    metadata = json['metadata'] != null
        ? new Metadata.fromJson(json['metadata'])
        : null;
    parent =
        json['parent'] != null ? new Parent.fromJson(json['parent']) : null;
    period =
        json['period'] != null ? new Period.fromJson(json['period']) : null;
    // if (json['pretax_credit_amounts'] != null) {
    //   pretaxCreditAmounts = <Null>[];
    //   json['pretax_credit_amounts'].forEach((v) { pretaxCreditAmounts!.add(new Null.fromJson(v)); });
    // }
    pricing =
        json['pricing'] != null ? new Pricing.fromJson(json['pricing']) : null;
    quantity = json['quantity'];
    // if (json['taxes'] != null) {
    //   taxes = <Null>[];
    //   json['taxes'].forEach((v) { taxes!.add(new Null.fromJson(v)); });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['object'] = this.object;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    data['description'] = this.description;
    // if (this.discountAmounts != null) {
    //   data['discount_amounts'] = this.discountAmounts!.map((v) => v.toJson()).toList();
    // }
    data['discountable'] = this.discountable;
    // if (this.discounts != null) {
    //   data['discounts'] = this.discounts!.map((v) => v.toJson()).toList();
    // }
    data['invoice'] = this.invoice;
    data['livemode'] = this.livemode;
    if (this.metadata != null) {
      data['metadata'] = this.metadata!.toJson();
    }
    if (this.parent != null) {
      data['parent'] = this.parent!.toJson();
    }
    if (this.period != null) {
      data['period'] = this.period!.toJson();
    }
    // if (this.pretaxCreditAmounts != null) {
    //   data['pretax_credit_amounts'] = this.pretaxCreditAmounts!.map((v) => v.toJson()).toList();
    // }
    if (this.pricing != null) {
      data['pricing'] = this.pricing!.toJson();
    }
    data['quantity'] = this.quantity;
    // if (this.taxes != null) {
    //   data['taxes'] = this.taxes!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Parent {
  InvoiceItemDetails? invoiceItemDetails;
  Null? subscriptionItemDetails;
  String? type;

  Parent({this.invoiceItemDetails, this.subscriptionItemDetails, this.type});

  Parent.fromJson(Map<String, dynamic> json) {
    invoiceItemDetails = json['invoice_item_details'] != null
        ? new InvoiceItemDetails.fromJson(json['invoice_item_details'])
        : null;
    subscriptionItemDetails = json['subscription_item_details'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.invoiceItemDetails != null) {
      data['invoice_item_details'] = this.invoiceItemDetails!.toJson();
    }
    data['subscription_item_details'] = this.subscriptionItemDetails;
    data['type'] = this.type;
    return data;
  }
}

class InvoiceItemDetails {
  String? invoiceItem;
  bool? proration;
  ProrationDetails? prorationDetails;
  Null? subscription;

  InvoiceItemDetails(
      {this.invoiceItem,
      this.proration,
      this.prorationDetails,
      this.subscription});

  InvoiceItemDetails.fromJson(Map<String, dynamic> json) {
    invoiceItem = json['invoice_item'];
    proration = json['proration'];
    prorationDetails = json['proration_details'] != null
        ? new ProrationDetails.fromJson(json['proration_details'])
        : null;
    subscription = json['subscription'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invoice_item'] = this.invoiceItem;
    data['proration'] = this.proration;
    if (this.prorationDetails != null) {
      data['proration_details'] = this.prorationDetails!.toJson();
    }
    data['subscription'] = this.subscription;
    return data;
  }
}

class ProrationDetails {
  Null? creditedItems;

  ProrationDetails({this.creditedItems});

  ProrationDetails.fromJson(Map<String, dynamic> json) {
    creditedItems = json['credited_items'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['credited_items'] = this.creditedItems;
    return data;
  }
}

class Period {
  int? end;
  int? start;

  Period({this.end, this.start});

  Period.fromJson(Map<String, dynamic> json) {
    end = json['end'];
    start = json['start'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['end'] = this.end;
    data['start'] = this.start;
    return data;
  }
}

class Pricing {
  PriceDetails? priceDetails;
  String? type;
  String? unitAmountDecimal;

  Pricing({this.priceDetails, this.type, this.unitAmountDecimal});

  Pricing.fromJson(Map<String, dynamic> json) {
    priceDetails = json['price_details'] != null
        ? new PriceDetails.fromJson(json['price_details'])
        : null;
    type = json['type'];
    unitAmountDecimal = json['unit_amount_decimal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.priceDetails != null) {
      data['price_details'] = this.priceDetails!.toJson();
    }
    data['type'] = this.type;
    data['unit_amount_decimal'] = this.unitAmountDecimal;
    return data;
  }
}

class PriceDetails {
  String? price;
  String? product;

  PriceDetails({this.price, this.product});

  PriceDetails.fromJson(Map<String, dynamic> json) {
    price = json['price'];
    product = json['product'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['price'] = this.price;
    data['product'] = this.product;
    return data;
  }
}

class PaymentMethodOptions {
  Card? card;

  PaymentMethodOptions({this.card});

  PaymentMethodOptions.fromJson(Map<String, dynamic> json) {
    card = json['card'] != null ? new Card.fromJson(json['card']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.card != null) {
      data['card'] = this.card!.toJson();
    }
    return data;
  }
}

class Card {
  String? requestThreeDSecure;

  Card({this.requestThreeDSecure});

  Card.fromJson(Map<String, dynamic> json) {
    requestThreeDSecure = json['request_three_d_secure'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['request_three_d_secure'] = this.requestThreeDSecure;
    return data;
  }
}

class PresentmentDetails {
  int? presentmentAmount;
  String? presentmentCurrency;

  PresentmentDetails({this.presentmentAmount, this.presentmentCurrency});

  PresentmentDetails.fromJson(Map<String, dynamic> json) {
    presentmentAmount = json['presentment_amount'];
    presentmentCurrency = json['presentment_currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['presentment_amount'] = this.presentmentAmount;
    data['presentment_currency'] = this.presentmentCurrency;
    return data;
  }
}

class Metadata {
  String? payload;
  String? userId;

  Metadata({this.payload, this.userId});

  Metadata.fromJson(Map<String, dynamic> json) {
    payload = json['payload'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['payload'] = this.payload;
    data['user_id'] = this.userId;
    return data;
  }
}

class PaymentSettings {
  Null? defaultMandate;
  Null? paymentMethodOptions;
  Null? paymentMethodTypes;

  PaymentSettings(
      {this.defaultMandate,
      this.paymentMethodOptions,
      this.paymentMethodTypes});

  PaymentSettings.fromJson(Map<String, dynamic> json) {
    defaultMandate = json['default_mandate'];
    paymentMethodOptions = json['payment_method_options'];
    paymentMethodTypes = json['payment_method_types'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['default_mandate'] = this.defaultMandate;
    data['payment_method_options'] = this.paymentMethodOptions;
    data['payment_method_types'] = this.paymentMethodTypes;
    return data;
  }
}

class Rendering {
  Null? amountTaxDisplay;
  Pdf? pdf;
  Null? template;
  Null? templateVersion;

  Rendering(
      {this.amountTaxDisplay, this.pdf, this.template, this.templateVersion});

  Rendering.fromJson(Map<String, dynamic> json) {
    amountTaxDisplay = json['amount_tax_display'];
    pdf = json['pdf'] != null ? new Pdf.fromJson(json['pdf']) : null;
    template = json['template'];
    templateVersion = json['template_version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount_tax_display'] = this.amountTaxDisplay;
    if (this.pdf != null) {
      data['pdf'] = this.pdf!.toJson();
    }
    data['template'] = this.template;
    data['template_version'] = this.templateVersion;
    return data;
  }
}

class Pdf {
  String? pageSize;

  Pdf({this.pageSize});

  Pdf.fromJson(Map<String, dynamic> json) {
    pageSize = json['page_size'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page_size'] = this.pageSize;
    return data;
  }
}

class StatusTransitions {
  int? finalizedAt;
  Null? markedUncollectibleAt;
  Null? paidAt;
  Null? voidedAt;

  StatusTransitions(
      {this.finalizedAt,
      this.markedUncollectibleAt,
      this.paidAt,
      this.voidedAt});

  StatusTransitions.fromJson(Map<String, dynamic> json) {
    finalizedAt = json['finalized_at'];
    markedUncollectibleAt = json['marked_uncollectible_at'];
    paidAt = json['paid_at'];
    voidedAt = json['voided_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['finalized_at'] = this.finalizedAt;
    data['marked_uncollectible_at'] = this.markedUncollectibleAt;
    data['paid_at'] = this.paidAt;
    data['voided_at'] = this.voidedAt;
    return data;
  }
}

class UpdatedAt {
  int? iSeconds;
  int? iNanoseconds;

  UpdatedAt({this.iSeconds, this.iNanoseconds});

  UpdatedAt.fromJson(Map<String, dynamic> json) {
    iSeconds = json['_seconds'];
    iNanoseconds = json['_nanoseconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_seconds'] = this.iSeconds;
    data['_nanoseconds'] = this.iNanoseconds;
    return data;
  }
}
