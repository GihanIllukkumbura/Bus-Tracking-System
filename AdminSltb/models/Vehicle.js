const admin = require('firebase-admin');
const db = admin.firestore();

class Vehicle {
  constructor(sltbnumber, model, year, registeredNumber, fuelCapacity, fuelType, imageUrl) {
    this.sltbnumber = sltbnumber;
    this.model = model;
    this.year = year;
    this.registeredNumber = registeredNumber;
    this.fuelCapacity = fuelCapacity;
    this.fuelType = fuelType;
    this.imageUrl = imageUrl;
  }
  async save() {
    try {
      
      await db.collection('vehicles').add({
        sltbnumber: this.sltbnumber,
        model: this.model,
        year: this.year,
        registeredNumber: this.registeredNumber,
        fuelCapacity: this.fuelCapacity,
        fuelType: this.fuelType,
        imageUrl: this.imageUrl
      });
     
    } catch (err) {
      console.error('Error saving vehicle:', err);
      throw new Error('Internal server error');
    }
  }
}

module.exports = Vehicle;

