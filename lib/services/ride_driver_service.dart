import 'package:senmi/services/api_service.dart';

class RideService {

  static const String baseUrl =
      "https://www.senmi.com.ng/api";

  static Future<Map<String,String>> headers() async {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.token}",
    };
  }

  //createRideRequest()
//getAvailableDrivers()
//acceptRide()
//startRide()
//completeRide()
//cancelRide()

//getRideDetails()

//updateDriverLocation()

//rateDriver()

//getDriverWallet()
//withdrawCommission()

}


