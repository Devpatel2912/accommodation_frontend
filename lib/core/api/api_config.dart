class ApiConfig {
  static const String baseUrl = "http://27.116.52.24:8072";
  // static const String baseUrl = "http://192.168.29.73:5000"; //dyulabs
  // static const String baseUrl = "http://10.228.69.155:5000";// my phone
  // static const String baseUrl = "http://192.168.201.130:5001"; //AVD
  static const String notificationBaseUrl =
      "http://27.116.52.24:8072/notifications"; // Integrated FCM backend


  // Endpoints
  static const String requests = "/requests";
  static const String login = "/auth/login";
  static const String sendOtp = "/auth/request-otp";
  static const String myRequests = "/requests/my";
  static const String profile = "/auth/profile";
  static const String adminRequests = "/admin/requests";
  static const String rooms = "/rooms";
  static const String allHouses = "/houses";
  static const String availableHouses = "/admin/houses/available";
  static const String houseBookings = "/admin/house-bookings";
  static const String memberSuggestions = "/requests/members/suggestions";
  static const String myMembers = "/requests/members";
  static const String adminUsers = "/admin/users";
  static const String adminMembers = "/admin/members";
  static const String adminRoomsAll = "/rooms/admin/all";
  static const String allocationItems = "/admin/allocation-items";
  static const String memberAllocations = "/admin/member-allocations";
  static const String upload = "/upload";
  static const String register = "/auth/register";
  static const String subadminRequests = "/subadmin/requests";
  static const String googleMapsApiKey =
      "AIzaSyAWbWNOIN2NVRIHbjhflvEh4JDr2ZkJ3xA";

  // Supabase Configuration (for PubSub)
  static const String supabaseUrl = "https://woushgaduuivvupthfge.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvdXNoZ2FkdXVpdnZ1cHRoZmdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMzM3MDgsImV4cCI6MjA5MjcwOTcwOH0.0nWsJUBM7Abmb0Smott-NNpCrspgok8IEnBZzWCWP1c";
}
