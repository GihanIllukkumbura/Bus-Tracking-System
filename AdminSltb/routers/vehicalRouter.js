const express = require('express');
const router = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const Vehicle = require('../models/Vehicle');
const serviceAccount = require('../key.json');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// image upload

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'upload/'); // Set the destination folder for uploaded files
  },
  filename: function (req, file, cb) {
    cb(null, file.fieldname + '-' + Date.now()) // Set the filename to be unique
  },
});

const upload = multer({ storage: storage });


var bucket = admin.storage().bucket();




// const filePath = 'c:/Users/pc/Downloads/k820RUm6KHRtm8G3huGJY2Z4bjN2.jpg';

// // Destination path in the storage bucket (e.g., 'images/my-image.jpg')
// const destinationPath = 'vehicals/my-image.jpg';

// Upload the file to the storage bucket
// bucket.upload(filePath, {
//   destination: destinationPath
// }).then((file) => {
//   console.log('File uploaded successfully.');

//   // Get the download URL
//   return file[0].getSignedUrl({
//     action: 'read',
//     expires: '01-01-2100' // Optional expiration date
//   });
// }).then((url) => {
//   console.log('Download URL:', url);
// }).catch((error) => {
//   console.error('Error uploading file:', error);
// });











// Route to get all vehicles
router.get('/vehicles', async (req, res) => {
  try {
    // Retrieve all vehicle data from Firestore
    const snapshot = await db.collection('vehicles').get();

    req.flash('success', '');

    // Map the snapshot documents to an array of vehicle objects
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Render your view or send the retrieved data to the client
    res.render('Busable', { vehicles,success: req.flash('success') ,error: req.flash('error')});
  } catch (error) {
    console.error('Error fetching vehicle data:', error);
    req.flash('error', 'Error fetching vehicle data');
    res.redirect('/'); // Redirect to the desired route or handle the error accordingly
  }
});


// Add more routes as needed

router.get('/addvehical', (req, res) => {
  res.render('addvehical', { success: req.flash('success'), error: req.flash('error') });
});

router.post('/addvehical', upload.single('vehicalImage'), async (req, res) => {
  const { sltbnumber, model, year, registeredNumber, fuelCapacity, fuelType } = req.body;
  const imageFile = req.file;

  try {
    if (!imageFile) {
      throw new Error('Please upload an image');
    }

    const filePath = imageFile.path;
    const destinationPath = `vehicals/${imageFile.originalname}`;

    await bucket.upload(filePath, { destination: destinationPath });

    const [imageUrl] = await bucket.file(destinationPath).getSignedUrl({
      action: 'read',
      expires: '01-01-2100'
    });

    const vehicle = new Vehicle(sltbnumber, model, year, registeredNumber, fuelCapacity, fuelType, imageUrl);
    await vehicle.save();

    req.flash('success', 'Vehicle added successfully');

    const snapshot = await db.collection('vehicles').get();
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.render('Busable', { vehicles, success: req.flash('success'), error: req.flash('error') });
  } catch (err) {
    req.flash('error', err.message);
    res.render('addvehical', { error: req.flash('error'), success: req.flash('success') });
  }
});

// delete vehical 


router.delete('/delete/:id', async (req, res) => {
  const vehicleId = req.params.id; // Get the vehicle ID from the request parameters

  try {
    // Delete the vehicle document from Firestore
    await db.collection('vehicles').doc(vehicleId).delete();
    req.flash('success', 'Vehicle Deleted successfully');
  // reder to table
  const snapshot = await db.collection('vehicles').get();
  const vehicles = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  res.render('Busable', { vehicles , success: req.flash('success'),error: req.flash('error')});

  
  } catch (err) {
    console.error('Error deleting vehicle:', err);
    req.flash('error', 'Error deleting vehicle');
    res.redirect('/home'); // Redirect to the home page with an error message
  }
});












router.get('/update/:id', async (req, res) => {
  const vehicleId = req.params.id;
  console.log(vehicleId)
  try {
    const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
    if (!vehicleDoc.exists) {
      throw new Error('Vehicle not found');
    }

    const vehicle = vehicleDoc.data();
    res.render('updateUNivehicles', { vehicle, vehicleId, error: null }); // Pass null for error
  } catch (err) {
    req.flash('error', err.message);
    res.redirect('/');
  }
});


router.post('/update/:id', upload.single('vehicalImage'), async (req, res) => {
  const vehicleId = req.params.id;
  const { sltbnumber, model, year, registeredNumber, fuelCapacity, fuelType } = req.body;
  const imageFile = req.file; // Get the uploaded file

  try {
    const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
    if (!vehicleDoc.exists) {
      throw new Error('Vehicle not found');
    }

    const vehicle = vehicleDoc.data();

    // Log current vehicle data for debugging


    let imageUrl = vehicle.imageUrl; // Default to existing imageUrl

    if (imageFile) {
      const filePath = imageFile.path;
      const destinationPath = `vehicals/${imageFile.originalname}`;
      await bucket.upload(filePath, { destination: destinationPath });
      const signedUrls = await bucket.file(destinationPath).getSignedUrl({
        action: 'read',
        expires: '01-01-2100'
      });
      imageUrl = signedUrls;  // Update imageUrl with the new uploaded URL
    }

    const updatedVehicle = {
      sltbnumber: sltbnumber || vehicle.sltbnumber,
      model: model || vehicle.model,
      year: year || vehicle.year,
      registeredNumber: registeredNumber || vehicle.registeredNumber,
      fuelCapacity: fuelCapacity || vehicle.fuelCapacity,
      fuelType: fuelType || vehicle.fuelType,
      imageUrl // Use the updated or existing imageUrl
    };

    // Log updated vehicle data for debugging
    

    await db.collection('vehicles').doc(vehicleId).update(updatedVehicle);
    req.flash('success', 'Vehicle  successfully updated');

    // Fetch and render the updated list of vehicles
    const snapshot = await db.collection('vehicles').get();
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.render('Busable', { vehicles,success: req.flash('success'),error: req.flash('error') });

  } catch (err) {
    console.error('Error updating vehicle:', err);
    res.redirect('/');
  }
});





module.exports = router;
