const express = require('express');
const router = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const Vehicle = require('../models/Vehicle');
const serviceAccount = require('../key.json');
const multer = require('multer');
const fs = require('fs');
const path = require('path');







const WebSocket = require('ws');
const expressWs = require('express-ws');
expressWs(router);

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

// WebSocket connection
wss.on('connection', (ws) => {
  console.log('WebSocket connected');

  // Extracting the id from the URL
  const url = new URL(ws.upgradeReq.url, 'http://localhost:200');
  const userId = url.searchParams.get('id');

  // Firestore listener for location updates
  const docRef = db.collection('locations').doc(userId);
  const listener = docRef.onSnapshot((doc) => {
    const data = doc.data();
    if (data) {
      ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
    }
  });

  // WebSocket close event
  ws.on('close', () => {
    console.log('WebSocket disconnected');
    listener(); // Stop Firestore listener when WebSocket is closed
  });
});


// Express route
router.get('/map/:id', (req, res) => {
  const userId = req.params.id;
  res.render('maplocation', { userId });
});

// WebSocket route
router.ws('/map/:id', (ws, req) => {
  const userId = req.params.id;
  const docRef = db.collection('locations').doc(userId);
  const listener = docRef.onSnapshot((doc) => {
    const data = doc.data();
    if (data) {
      ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
    }
  });

  ws.on('close', () => {
    console.log('WebSocket disconnected');
    listener(); // Stop Firestore listener when WebSocket is closed
  });
});





router.get('/locations', async (req, res) => {
  try {
    const userId = req.session.userId;
  
    if (!userId) {
      console.log('User ID not found in session');
      res.render('login', { error: 'User ID not found in session, please log in again' });
      return;
    }
  
    const userRef = db.collection('users').doc(userId);
    const userSnapshot = await userRef.get();
  
    if (!userSnapshot.exists) {
      console.log('User document not found');
      res.render('login', { error: 'User document not found, please log in again' });
      return;
    }

    const locationsSnapshot = await db.collection('locations').get();
    const locations = locationsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        latitude: data.latitude,
        longitude: data.longitude,
        userid: data.userid
      };
    });

// Extract unique user IDs from locations
const userIds = [...new Set(locations.map(location => location.userid))];
console.log(userIds)

// Fetch usernames for user IDs in locations
const usersSnapshot = await db.collection('users').where('userid', 'in', userIds).get();

// Log the user IDs from the users collection
console.log('User IDs from users collection:');
usersSnapshot.docs.forEach(doc => {
  console.log(doc.id);
});

// Create a map of user IDs to usernames
const usersMap = new Map(usersSnapshot.docs.map(doc => [doc.id, doc.data().username]));

// Add usernames to locations
locations.forEach(location => {
  const username = usersMap.get(location.userid);

    location.username = username;
    console.log(location.username)
  
});

// Render the EJS template with the locations including usernames
console.log(locations)
res.render('allusersMap', { locations });


  } catch (error) {
    console.error('Error retrieving user locations:', error);
    res.status(500).send('Internal server error');
  }
});





router.get('/activetrips', async (req, res) => {
  try {
    // Step 1: Get active trips from the 'activetrips' collection
    const tripsSnapshot = await db.collection('activetrips').get();
    
    if (tripsSnapshot.empty) {
      console.log('No active trips found');
      res.render('activetripsMap', { trips: [] });
      return;
    }

    let trips = [];

    // Step 2: Iterate over the trip documents
    for (let tripDoc of tripsSnapshot.docs) {
      const tripData = tripDoc.data();
      const userId = tripDoc.id; // userId corresponds to the document ID
      
      // Step 3: Fetch user details from the 'users' collection
      const userSnapshot = await db.collection('users').doc(userId).get();
      const userData = userSnapshot.data();

      if (!userSnapshot.exists) {
        console.log(`User not found for trip: ${tripDoc.id}`);
        continue;
      }

      // Step 4: Fetch vehicle details using vehicleId from the 'vehicles' collection
      const vehicleSnapshot = await db.collection('vehicles').doc(tripData.vehicleId).get();
      const vehicleData = vehicleSnapshot.data();

      if (!vehicleSnapshot.exists) {
        console.log(`Vehicle not found for trip: ${tripDoc.id}`);
        continue;
      }

      // Step 5: Fetch live location from the 'locations' collection
      const locationSnapshot = await db.collection('locations').doc(userId).get();
      const locationData = locationSnapshot.data();

      if (!locationSnapshot.exists) {
        console.log(`Location not found for user: ${userId}`);
        continue;
      }

      // Step 6: Construct trip data, including new fields (destinationAddress, distance, etc.)
      trips.push({
        username: userData.username,
        vehicleId: tripData.vehicleId,
        sltbnumber: vehicleData.sltbnumber,
        imageUrl: vehicleData.imageUrl,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        destinationAddress: tripData.destinationAddress,  // New Field
        distance: tripData.distance,                      // New Field
        liveTrackingCoordinates: tripData.liveTrackingCoordinates, // New Field
        startAddress: tripData.startAddress,              // New Field
        startTime: tripData.startTime,                    // New Field
      });
    }



    // Step 7: Render the map view with trips data, including new fields
    res.render('activetripsMap', { trips });

  } catch (error) {
    console.error('Error retrieving active trips:', error);
    res.status(500).send('Internal server error');
  }
});

module.exports = router;