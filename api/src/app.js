const express = require("express");
const cors = require("cors");
const orderRoutes = require("./routes/orderRoutes");
const { errorHandler } = require("./middleware/errorHandler");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/orders", orderRoutes);

app.use(errorHandler);

module.exports = app;
