const orderService = require("../services/orderService");

async function list(req, res) {
  const result = await orderService.listOrders(req.query);
  res.json(result);
}

async function getByUuid(req, res) {
  const order = await orderService.getOrderByUuid(req.params.uuid);
  if (!order) {
    return res.status(404).json({ error: "Order not found" });
  }
  res.json(order);
}

module.exports = {
  list,
  getByUuid,
};
