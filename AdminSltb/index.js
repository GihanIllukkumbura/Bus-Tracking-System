let express = require('express');
const admin = require('firebase-admin');
let app = express();
let methodoverwride = require('method-override')
let dotenv = require('dotenv')
let bodyParser = require('body-parser')
const serviceAccount = require('./key.json');

const WebSocket = require('ws');
const expressWs = require('express-ws');
expressWs(app);

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });





admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "gs://flutternew-c90e6.appspot.com"
});



const db = admin.firestore();


let session = require('express-session');
let flash = require('connect-flash')

dotenv.config({ path: './config.env' })
// mongoose.connect(process.env.mongodburl);
app.set('view engine', 'ejs')

app.use(methodoverwride('_method'))
app.use(bodyParser.urlencoded({ extended: true }))
app.use(express.static('public'))

app.use('/upload', express.static('upload'));
// session middleweare
app.use(session({
  secret: 'nodejs',
  resave: true,
  saveUninitialized: true
}))
//flash middleweare
app.use(flash())

















const userRouter = require("./routers/userRouter.js");
const vehicalRouter = require("./routers/vehicalRouter.js");
const mapRouter = require("./routers/mapRouter.js");
const DriverRouter = require("./routers/driverRoute.js");
const Routerouter = require("./routers/routerouter.js");


app.use(userRouter)
app.use(vehicalRouter)
app.use(mapRouter)
app.use(DriverRouter)
app.use(Routerouter)




//globaly variable set for operation (like sucess , error) message
app.use((req, res, next) => {
  res.locals.sucess = req.flash('sucess'),
    res.locals.err = req.flash('err')
  next()
})


app.use('/upload', express.static('upload'));



app.listen(process.env.PORT, () => {
  console.log(process.env.PORT, "Port Working");
})