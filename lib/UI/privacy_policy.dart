import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CodeShare/variables.dart';
import '../main.dart';


class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool userAgreed = false;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);

    // Delay to wait for layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      bool shouldShow = _scrollController.offset < _scrollController.position.maxScrollExtent;
      if (_showScrollIndicator != shouldShow) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context);
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child:  Text('Privacy Policy', style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary)),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                // Blur effect
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover  entire background
                  width: double.infinity,
                  height: double.infinity,
                )),
          ),
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Center(
              child: Container(
                width: AppData.termsAndConditionsWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),

                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: AppData.text18,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Privacy Policy\n',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: 'Last updated: April 18, 2025\n',
                                  ),
                                  TextSpan(
                                    text: 'Version: ${privacyTermsVersionDisplayMap[currentPrivacyVersion]}\n\n',
                                  ),

                                  TextSpan(
                                    text:
                                    'This app collects and uses certain types of data to improve user experience, performance, and reliability. This includes information such as app preferences, crash reports, and general usage analytics (e.g., screen views, button taps, and feature interactions). These analytics help to understand which features of the app are being used so improvements can be made and bugs fixed more efficiently.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                    'No personally identifying information is collected unless you explicitly provide it (such as entering a name or crew label). Your data created within this app is not sold or shared with any third parties.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                    'All data is handled securely and is used solely for the purpose of making the app better and more reliable for the wildland fire community.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                    'By continuing, you confirm that you have read and agree to this privacy policy and consent to the app\'s data collection practices.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                    'For questions regarding the privacy policy or data collection, please contact dev@firemanifesting.com.',
                                  ),
                                ],
                              ),
                            ),

                          ),

                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _showScrollIndicator
                          ? Padding(
                        key: ValueKey(true),
                        padding: const EdgeInsets.only(top: 8, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 30,
                              color: Colors.black.withOpacity(0.6),
                            ),
                            Text(
                              ' More',
                              style: TextStyle(fontSize: AppData.text18, color: Colors.black),
                            ),
                          ],
                        ),
                      )
                          : SizedBox(
                        key: ValueKey(false),
                        height: AppData.screenWidth > 600 ? 60 : 48, // Matches visual height of padding + row
                      ),
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: AppData.checkboxScalingFactor, // Scales dynamically based on screen width
                          child: Checkbox(
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Colors.black, // Outline color
                              width: 2.0, // Outline width
                            ),//
                            value: userAgreed,
                            onChanged: (value) {
                              setState(() {
                                userAgreed = value!;
                              });
                            },
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'I agree to the privacy policy',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppData.text18,
                              // fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: userAgreed
                            ? () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('privacyVersionAccepted', currentPrivacyVersion);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyHomePage(),
                              settings: const RouteSettings(name: 'HomePage'),
                            ),
                          );
                        }
                            : null,

                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          backgroundColor: AppColors.textFieldColor,
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        ),
                        child:  Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: AppData.text20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}