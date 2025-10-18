import { LightningElement, api, track } from 'lwc';
import { getLocationService } from 'lightning/mobileCapabilities';
// 
export default class IHGeolocation extends LightningElement {

@api myLocationService
@api currentLocation
@api latitude
@api longitude
@api altitude
@api accuracy


//formfactor
  connectedCallback() {
      console.log(navigator.userAgent); // Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/90.0.4430.212
      console.log('UserAgent==>'+this.isUserAgent);
      //this.formfactor = this.getUserAgent;

  }

  @api
  getCurrentLocation(globalSettings) {
    return new Promise((resolve) => {
      this.currentLocation = null; // Reset current location
      this.myLocationService = getLocationService(); // Salesforce standard functionality
  
      var enableHighAccuracy = globalSettings.iahelp__Geo_EnableHighAccuracy__c;
      var timeout = globalSettings.iahelp__Geo_Timeout__c;
  
      // Check if Salesforce Location Service is available
      if (this.myLocationService && this.myLocationService.isAvailable()) {
        const locationOptions = { enableHighAccuracy, timeout };
        this.myLocationService.getCurrentPosition(locationOptions)
          .then((result) => {
            if (result) {
              this.latitude = result.coords.latitude;
              this.longitude = result.coords.longitude;
              this.altitude = result.coords.altitude;
              this.accuracy = result.coords.accuracy;
  
              var location = {
                latitude: this.latitude,
                longitude: this.longitude,
                altitude: this.altitude,
                accuracy: this.accuracy
              };
  
              resolve(location);
            }
          })
          .catch((error) => {
            console.error('Error with Salesforce Location Service:', error);
  
            var location = {
              latitude: null,
              longitude: null,
              altitude: null,
              accuracy: null
            };
  
            resolve(location);
          });
      } else if (navigator.geolocation) {
        console.log('Salesforce LocationService is not available. Falling back to navigator.geolocation.');
  
        var options = {
          enableHighAccuracy: enableHighAccuracy,
          timeout: timeout,
          maximumAge: 0,
        };
  
        navigator.geolocation.getCurrentPosition(
          (position) => {
            this.latitude = position.coords.latitude;
            this.longitude = position.coords.longitude;
            this.altitude = position.coords.altitude;
            this.accuracy = position.coords.accuracy;
  
            console.log(`Form_LWC Latitude: ${this.latitude}, Longitude: ${this.longitude}`);
  
            var location = {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude,
              altitude: position.coords.altitude,
              accuracy: position.coords.accuracy
            };
  
            resolve(location);
          },
          (error) => {
            console.error('Error with navigator.geolocation:', error);
  
            var location = {
              latitude: null,
              longitude: null,
              altitude: null,
              accuracy: null
            };
  
            resolve(location);
          },
          options
        );
      } else {
        // Fallback if neither LocationService nor geolocation is available
        console.log('Both Salesforce Location Service and navigator.geolocation are unavailable.');
  
        var location = {
          latitude: null,
          longitude: null,
          altitude: null,
          accuracy: null
        };
  
        console.log('Fallback location data:', location);
  
        resolve(location);
      }
    });
  }
  

@api
getisUserAgent(){
return navigator.userAgent.match(/Windows/i) != null ? 'Window' :
navigator.userAgent.match(/Android/i) != null ? 'Android Mobile' :
navigator.userAgent.match(/Mac/i) != null && !this.isIOS ? 'Mac':
navigator.userAgent.match(/iPhone|iPad|iPod/i) != null ? 'iOS' : '';
}


}