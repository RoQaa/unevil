import 'package:flutter/material.dart';
import 'login_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() =>
      _StartPageState();
}

class _StartPageState
    extends State<StartPage>
    with
        SingleTickerProviderStateMixin {
  late AnimationController
  controller;

  late Animation<double>
  logoAnimation;
  late Animation<double>
  textAnimation;
  late Animation<Offset>
  buttonAnimation;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
              milliseconds:
              1600),
        );

    logoAnimation =
        CurvedAnimation(
          parent: controller,
          curve: const Interval(
            0.0,
            0.5,
            curve:
            Curves.easeOutBack,
          ),
        );

    textAnimation =
        CurvedAnimation(
          parent: controller,
          curve: const Interval(
            0.3,
            0.7,
            curve:
            Curves.easeIn,
          ),
        );

    buttonAnimation =
        Tween<Offset>(
          begin: const Offset(
              0, 1),
          end:
          Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve:
            const Interval(
              0.5,
              1.0,
              curve: Curves
                  .easeOut,
            ),
          ),
        );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(
          0xFF121B4D),
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets
              .symmetric(
              horizontal:
              28),
          child: Column(
            children: [
              const Spacer(),

              ScaleTransition(
                scale:
                logoAnimation,
                child:
                Container(
                  padding:
                  const EdgeInsets
                      .all(
                      18),
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .white
                        .withOpacity(
                        0.05),
                    borderRadius:
                    BorderRadius.circular(
                        25),
                    border:
                    Border.all(
                      color: Colors
                          .white
                          .withOpacity(
                          0.08),
                    ),
                  ),
                  child:
                  Image.asset(
                    'assets/logo.png',
                    height:
                    170,
                  ),
                ),
              ),

              const SizedBox(
                  height:
                  35),

              FadeTransition(
                opacity:
                textAnimation,
                child:
                const Column(
                  children: [
                    Text(
                      "Unveil AI",
                      style:
                      TextStyle(
                        color: Color(
                            0xFFF5A623),
                        fontSize:
                        38,
                        fontWeight:
                        FontWeight
                            .bold,
                        letterSpacing:
                        1.2,
                      ),
                    ),
                    SizedBox(
                        height:
                        15),
                    Text(
                      "Reveal fake content instantly.\nAnalyze text, images, audio and video with confidence.",
                      textAlign:
                      TextAlign
                          .center,
                      style:
                      TextStyle(
                        color: Colors
                            .white70,
                        fontSize:
                        17,
                        height:
                        1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SlideTransition(
                position:
                buttonAnimation,
                child:
                Column(
                  children: [
                    SizedBox(
                      width: double
                          .infinity,
                      height:
                      58,
                      child:
                      ElevatedButton(
                        onPressed:
                            () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                              const LoginPage(),
                            ),
                          );
                        },
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                              0xFFF5A623),
                          elevation:
                          10,
                          shadowColor:
                          const Color(
                              0x66F5A623),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                18),
                          ),
                        ),
                        child:
                        const Text(
                          "Get Started",
                          style:
                          TextStyle(
                            fontSize:
                            19,
                            color: Colors
                                .white,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height:
                        14),

                    SizedBox(
                      width: double
                          .infinity,
                      height:
                      56,
                      child:
                      OutlinedButton(
                        onPressed:
                            () {},
                        style:
                        OutlinedButton.styleFrom(
                          backgroundColor:
                          const Color(
                              0xFF8E6BFF),
                          side:
                          const BorderSide(
                            color: Color(
                                0xFF8E6BFF),
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                18),
                          ),
                        ),
                        child:
                        const Text(
                          "Visit Unveil Web",
                          style:
                          TextStyle(
                            fontSize:
                            17,
                            color: Colors
                                .white,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height:
                  35),
            ],
          ),
        ),
      ),
    );
  }
}
