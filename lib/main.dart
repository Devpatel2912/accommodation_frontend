import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/presentation/views/login_view.dart';
import 'package:accommodation/modules/admin/admin_home_screen.dart';
import 'package:accommodation/modules/user/userhomescreen.dart';

import 'package:accommodation/data/datasources/auth_remote_datasource.dart';
import 'package:accommodation/data/repositories/auth_repository_impl.dart';
import 'package:accommodation/domain/usecases/request_otp_usecase.dart';
import 'package:accommodation/domain/usecases/verify_otp_usecase.dart';
import 'package:accommodation/presentation/viewmodels/login_viewmodel.dart';

import 'package:accommodation/data/datasources/request_remote_datasource.dart';
import 'package:accommodation/data/repositories/request_repository_impl.dart';
import 'package:accommodation/domain/usecases/get_my_requests_usecase.dart';
import 'package:accommodation/domain/usecases/cancel_request_usecase.dart';
import 'package:accommodation/domain/usecases/get_profile_usecase.dart';
import 'package:accommodation/domain/usecases/forward_to_members_usecase.dart';
import 'package:accommodation/domain/usecases/get_all_requests_usecase.dart';
import 'package:accommodation/domain/usecases/update_admin_request_usecase.dart';
import 'package:accommodation/domain/usecases/allocate_member_usecase.dart';
import 'package:accommodation/domain/usecases/get_available_rooms_usecase.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/views/splash_view.dart';

import 'package:accommodation/core/services/notification_service.dart';
import 'package:accommodation/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM and Local Notifications
  await PushNotificationService().init();
  
  // Initialize Real-time Notification Service (Supabase)
  await NotificationService().init();
  
  final client = http.Client();
  
  // Repositories
    final authRemoteDataSource = AuthRemoteDataSource(client);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  final requestRemoteDataSource = RequestRemoteDataSource(client);
  final requestRepository = RequestRepositoryImpl(requestRemoteDataSource);
  
  // Login UseCases
  final requestOtpUseCase = RequestOtpUseCase(authRepository);
  final verifyOtpUseCase = VerifyOtpUseCase(authRepository);
  
  // UserHome UseCases
  final getMyRequestsUseCase = GetMyRequestsUseCase(requestRepository);
  final cancelRequestUseCase = CancelRequestUseCase(requestRepository);
  final getProfileUseCase = GetProfileUseCase(authRepository);
  final forwardToMembersUseCase = ForwardToMembersUseCase(requestRepository);
  final getAllRequestsUseCase = GetAllRequestsUseCase(requestRepository);
  final updateAdminRequestUseCase = UpdateAdminRequestUseCase(requestRepository);
  final allocateMemberUseCase = AllocateMemberUseCase(requestRepository);
  final getAvailableRoomsUseCase = GetAvailableRoomsUseCase(requestRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel(requestOtpUseCase, verifyOtpUseCase)),
        ChangeNotifierProvider(
          create: (_) => UserHomeViewModel(
            getMyRequestsUseCase,
            cancelRequestUseCase,
            getProfileUseCase,
            forwardToMembersUseCase,
            getAllRequestsUseCase,
            updateAdminRequestUseCase,
            allocateMemberUseCase,
            getAvailableRoomsUseCase,
            requestRemoteDataSource,
          )..fetchProfile(), // Initial profile fetch to set isAdmin
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accommodation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal),
        scaffoldBackgroundColor: AppColors.bgGrey,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const SplashView(),
    );
  }
}