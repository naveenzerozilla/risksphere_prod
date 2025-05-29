import 'dart:ffi';

import 'package:flutter/material.dart';

import '../../../../../constants/enums.dart';
import '../../../../../design_system/components/custom_button.dart';
import '../../../../../design_system/components/custom_chip.dart';
import '../../../../../design_system/primitives/app_colors.dart';
import '../../../../../design_system/primitives/custom_typography.dart';
import '../../../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../../../providers/verification_provider.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;

class VerificationUserRequestsListItem extends StatelessWidget {
  final int index;
  final VerificationProvider verificationProvider;
  final List<roleModel.Roles> allRoles; // Assuming Role is a model class for roles
  final roleModel.Roles? selectedRole;
  final void Function(roleModel.Roles?) onRoleSelected;
  final Function onSaveRole;
  final Function onCancelRoleSelection;
  final Function onAcceptRequest;
  final Function onRejectRequest;
  final bool isCorporateAcceptLoading;
  final bool isUserRejectLoading;
  final int selectedUserVerificationAcceptListIndex;
  final int selectedUserVerificationRejectListIndex;

  const VerificationUserRequestsListItem({
    Key? key,
    required this.index,
    required this.verificationProvider,
    required this.allRoles,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onSaveRole,
    required this.onCancelRoleSelection,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.isCorporateAcceptLoading,
    required this.isUserRejectLoading,
    required this.selectedUserVerificationAcceptListIndex,
    required this.selectedUserVerificationRejectListIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: CustomSpacing.one),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                          '“${verificationProvider.userRequests[index].name ?? ""}”',
                          style: typography.Body1_5.copyWith(
                            color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.white
                                : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                          ' has requested to create new corporate account.',
                          style: typography.Body1_5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: CustomSpacing.one),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomChip(
                          label: Text(
                            verificationProvider.userRequests[index].email ?? "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                          label: Text(
                            verificationProvider.userRequests[index].phone ?? "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Select Role',
                                      style: typography.H6),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: CustomSpacing.two),
                                      DropdownButtonFormField(
                                        items: allRoles
                                            .where((role) =>
                                        role.isApplicableForInternal ==
                                            true)
                                            .map((role) {
                                          return DropdownMenuItem(
                                            child: Text(role.name ?? ""),
                                            value: role,
                                          );
                                        }).toList(),
                                        onChanged: onRoleSelected??null,
                                        value: selectedRole,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.two),
                                      Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomButton(
                                                  type: ButtonType.filled,
                                                  onPressed: () {
                                                    onSaveRole();
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Save',
                                                      style: typography
                                                          .BottomNavigationActiveLabel),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomButton(
                                                  type: ButtonType.text,
                                                  onPressed: () {
                                                    onCancelRoleSelection();
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Cancel',
                                                      style: typography
                                                          .BottomNavigationActiveLabel
                                                          .copyWith(
                                                          color: AppColors
                                                              .primaryMain)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          label: Text(
                            verificationProvider.userRequests[index].role ?? "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  isCorporateAcceptLoading &&
                      selectedUserVerificationAcceptListIndex == index
                      ? Center(
                    child: Container(
                      margin: EdgeInsets.only(left: 24),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : CustomButton(
                    type: ButtonType.outlined,
                    onPressed: () {
                      onAcceptRequest();
                    },
                    child: Text('Accept',
                        style: typography.BottomNavigationActiveLabel
                            .copyWith(color: AppColors.primaryMain)),
                  ),
                  SizedBox(width: CustomSpacing.two),
                  isUserRejectLoading &&
                      selectedUserVerificationRejectListIndex == index
                      ? Center(
                    child: Container(
                      margin: EdgeInsets.only(left: 16),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : CustomButton(
                    type: ButtonType.text,
                    onPressed: () {
                      onRejectRequest();
                    },
                    child: Text('Reject',
                        style: typography.BottomNavigationActiveLabel
                            .copyWith(color: AppColors.primaryMain)),
                  ),
                 // Uncomment for time
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: CustomSpacing.two),
                      Text(
                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        //'Mar 7, 2024 23:26',
                          style: typography.Caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
