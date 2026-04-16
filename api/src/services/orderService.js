const orderRepository = require("../repositories/orderRepository");

function parseOptionalInt(value) {
  if (value === undefined || value === null || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function parseListQuery(query) {
  const page = Math.max(Number(query.page) || 0, 0);
  const size = Math.min(Math.max(Number(query.size) || 20, 1), 100);
  const sort = query.sort === "asc" ? "asc" : "desc";

  return {
    page,
    size,
    sort,
    codigoCliente: parseOptionalInt(query.codigoCliente),
    productId: parseOptionalInt(query.productId),
    status: query.status && String(query.status).trim() ? String(query.status).trim() : null,
  };
}

async function listOrders(query) {
  const params = parseListQuery(query);
  return orderRepository.findOrders(params);
}

async function getOrderByUuid(uuid) {
  const id = uuid != null ? String(uuid).trim() : "";
  if (!id) return null;
  return orderRepository.findByUuid(id);
}

module.exports = {
  listOrders,
  getOrderByUuid,
};
