const admin = require('firebase-admin');
const db = admin.firestore();

class Vehicle {
  constructor(routenumber,start, destination, startcoordinants, destinationcoordinants,) {
    this.routenumber = routenumber;
    this.start = start;
    this.destination = destination;
    this.startcoordinants = startcoordinants;
    this.destinationcoordinants = destinationcoordinants;
   
  }
  async save() {
    try {
      
      await db.collection('route').add({
        routenumber: this.routenumber,
        start: this.start,
        destination: this.destination,
        startcoordinants: this.startcoordinants,
        destinationcoordinants: this.destinationcoordinants,
       
      });
     
    } catch (err) {
      console.error('Error saving route:', err);
      throw new Error('Internal server error');
    }
  }
}

module.exports = Vehicle;

