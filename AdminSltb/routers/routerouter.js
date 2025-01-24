
let express = require('express');
let Routerouter = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const User = require('../models/usermodel');
const Vehicle = require('../models/Vehicle');
const route = require('../models/Route');








// Route to get all vehicles
Routerouter.get('/Routes', async (req, res) => {
    try {
      // Retrieve all vehicle data from Firestore
      const snapshot = await db.collection('route').get();
  
      req.flash('success', '');
  
      // Map the snapshot documents to an array of vehicle objects
      const routes = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
  
      // Render your view or send the retrieved data to the client
      res.render('Routes', { routes,success: req.flash('success') ,error: req.flash('error')});
    } catch (error) {
      console.error('Error fetching vehicle data:', error);
      req.flash('error', 'Error fetching vehicle data');
      res.redirect('/'); // Redirect to the desired route or handle the error accordingly
    }
  });
  
  
//   Add more routes as needed
  
Routerouter.get('/addRoute', (req, res) => {
    try {
        const userId = req.session.userId;

        if (!userId) {
            req.flash('error', 'Please log in to continue');
            res.render('login', { error: req.flash('error') });
            return;
        }

        res.render('addRoute', { success: req.flash('success'), error: req.flash('error') });
    } catch (err) {
        req.flash('error', 'An error occurred while processing your request');
        res.render('login', { error: req.flash('error') });
    }
});
  
Routerouter.post('/addRoute', async (req, res) => {
    const { routenumber, start, destination, startcoordinants, destinationcoordinants, } = req.body;
    
  
    try {
        const userId = req.session.userId;
    
      if (!userId) {
        
        res.render('login', { error: 'please log in again' });
        return;
      }

  
      const Route = new route(routenumber, start, destination, startcoordinants, destinationcoordinants, );
      await Route.save();
  
      req.flash('success', 'Route added successfully');
  
      const snapshot = await db.collection('route').get();
      const routes = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
  
      res.render('Routes', { routes, success: req.flash('success'), error: req.flash('error') });
    } catch (err) {
      req.flash('error', err.message);
      res.redirect('/', { error: req.flash('error'), success: req.flash('success') });
    }
  });
  
//   // delete vehical 
  
  
//   router.delete('/delete/:id', async (req, res) => {
//     const vehicleId = req.params.id; // Get the vehicle ID from the request parameters
  
//     try {
//       // Delete the vehicle document from Firestore
//       await db.collection('vehicles').doc(vehicleId).delete();
//       req.flash('success', 'Vehicle Deleted successfully');
//     // reder to table
//     const snapshot = await db.collection('vehicles').get();
//     const vehicles = snapshot.docs.map(doc => ({
//       id: doc.id,
//       ...doc.data()
//     }));
//     res.render('Busable', { vehicles , success: req.flash('success'),error: req.flash('error')});
  
    
//     } catch (err) {
//       console.error('Error deleting vehicle:', err);
//       req.flash('error', 'Error deleting vehicle');
//       res.redirect('/home'); // Redirect to the home page with an error message
//     }
//   });
  
  
  
  
  
  
  
  
  
  
  
  
//   router.get('/update/:id', async (req, res) => {
//     const vehicleId = req.params.id;
//     console.log(vehicleId)
//     try {
//       const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
//       if (!vehicleDoc.exists) {
//         throw new Error('Vehicle not found');
//       }
  
//       const vehicle = vehicleDoc.data();
//       res.render('updateUNivehicles', { vehicle, vehicleId, error: null }); // Pass null for error
//     } catch (err) {
//       req.flash('error', err.message);
//       res.redirect('/');
//     }
//   });
  
  
//   router.post('/update/:id', upload.single('vehicalImage'), async (req, res) => {
//     const vehicleId = req.params.id;
//     const { make, model, year, registeredNumber, fuelCapacity, fuelType } = req.body;
//     const imageFile = req.file; // Get the uploaded file
  
//     try {
//       const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
//       if (!vehicleDoc.exists) {
//         throw new Error('Vehicle not found');
//       }
  
//       const vehicle = vehicleDoc.data();
  
//       // Log current vehicle data for debugging
  
  
//       let imageUrl = vehicle.imageUrl; // Default to existing imageUrl
  
//       if (imageFile) {
//         const filePath = imageFile.path;
//         const destinationPath = `vehicals/${imageFile.originalname}`;
//         await bucket.upload(filePath, { destination: destinationPath });
//         const signedUrls = await bucket.file(destinationPath).getSignedUrl({
//           action: 'read',
//           expires: '01-01-2100'
//         });
//         imageUrl = signedUrls;  // Update imageUrl with the new uploaded URL
//       }
  
//       const updatedVehicle = {
//         make: make || vehicle.make,
//         model: model || vehicle.model,
//         year: year || vehicle.year,
//         registeredNumber: registeredNumber || vehicle.registeredNumber,
//         fuelCapacity: fuelCapacity || vehicle.fuelCapacity,
//         fuelType: fuelType || vehicle.fuelType,
//         imageUrl // Use the updated or existing imageUrl
//       };
  
//       // Log updated vehicle data for debugging
      
  
//       await db.collection('vehicles').doc(vehicleId).update(updatedVehicle);
//       req.flash('success', 'Vehicle  successfully updated');
  
//       // Fetch and render the updated list of vehicles
//       const snapshot = await db.collection('vehicles').get();
//       const vehicles = snapshot.docs.map(doc => ({
//         id: doc.id,
//         ...doc.data()
//       }));
      
//       res.render('Busable', { vehicles,success: req.flash('success'),error: req.flash('error') });
  
//     } catch (err) {
//       console.error('Error updating vehicle:', err);
//       res.redirect('/');
//     }
//   });
  
  
  





module.exports = Routerouter;




