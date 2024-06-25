
import 'package:country_picker/country_picker.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';

import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';

class CountryPickerFlagName extends StatefulWidget {
  final Function(Country)? onCountryChange;
  final Country? initialValue;
  const CountryPickerFlagName({super.key, required this.onCountryChange, this.initialValue});

  @override
  State<CountryPickerFlagName> createState() => _CountryPickerFlagNameState();
}

class _CountryPickerFlagNameState extends State<CountryPickerFlagName> {

  late Country country;

  initState() {
    super.initState();
    if (widget.initialValue != null) {
      country = widget.initialValue ?? Country(
        phoneCode: "+1",
        countryCode: "US",
        e164Sc: 1,
        geographic: true,
        level: 1,
        name: "United States",
        example: "+1 202-555-0191",
        displayName: "United States (+1)",
        displayNameNoCountryCode: "United States",
        e164Key: "1-US-0",
      );
      print('CountryPickerFlagName: ${country.name}');
    }
  }


  @override
  Widget build(BuildContext context) {
    country = widget.initialValue ?? country;
    return GestureDetector(
      onTap: () {
        if (widget.onCountryChange != null) {
          showCountryPicker(
          context: context,
          showPhoneCode: false,
          onSelect: (Country selectedCountry) {
            setState(() {
              country = selectedCountry;
            });

            if (widget.onCountryChange != null) {
              widget.onCountryChange!(selectedCountry);
            }
          },
        );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(
              CountryPickerUtils.getFlagImageAssetPath(country.countryCode),
              package: 'country_pickers',
            ),
          ),
          SizedBox(width: CustomSpacing.two),
          Flexible(
            child: Text(
              country.name,
              style: CustomTypography.Body1,
            ),
          ),
        ],
      ),
    );
  }


  /*@override
  Widget build(BuildContext context) {
    return CountryPickerDropdown(
      initialValue: 'US',
      itemBuilder: (Country country) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: AssetImage(
                  CountryPickerUtils.getFlagImageAssetPath(
                      country.isoCode),
                  package: 'country_pickers',
                ),
              ),
              SizedBox(width: CustomSpacing.two),
              Flexible(
                child: Text(
                  country.name,
                  style: CustomTypography.Body1,
                ),
              ),
            ],
          ),
        );
      },
      onValuePicked: widget.onCountryChange,
    );
  }*/
}
