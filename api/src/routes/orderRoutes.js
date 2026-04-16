const { Router } = require("express");
const orderController = require("../controllers/orderController");
const { asyncHandler } = require("../middleware/asyncHandler");

const router = Router();

router.get("/", asyncHandler(orderController.list));
router.get("/:uuid", asyncHandler(orderController.getByUuid));

module.exports = router;
