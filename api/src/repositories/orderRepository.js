const { pool } = require("../config/database");

async function findOrders({ codigoCliente, productId, status, page, size, sort }) {
  const values = [];
  const conditions = [];
  let paramIndex = 1;

  if (codigoCliente != null) {
    conditions.push(`o.customer_id = $${paramIndex++}`);
    values.push(codigoCliente);
  }

  if (status) {
    conditions.push(`o.status = $${paramIndex++}`);
    values.push(status.toUpperCase());
  }

  if (productId != null) {
    conditions.push(`EXISTS (
      SELECT 1 FROM order_items oi WHERE oi.order_id = o.id AND oi.product_id = $${paramIndex++}
    )`);
    values.push(productId);
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
  const direction = sort === "asc" ? "ASC" : "DESC";
  const offset = page * size;

  const countQuery = `SELECT COUNT(*) FROM orders o ${where}`;
  const countResult = await pool.query(countQuery, values);
  const totalElements = Number(countResult.rows[0].count);

  const query = `
    SELECT o.id, o.uuid, o.created_at, o.channel, o.status,
           o.customer_id, o.seller_id, o.shipment_id, o.payment_id, o.metadata_id,
           o.indexed_at
    FROM orders o
    ${where}
    ORDER BY o.created_at ${direction}
    LIMIT $${paramIndex++} OFFSET $${paramIndex++}
  `;
  values.push(size, offset);

  const result = await pool.query(query, values);
  const orders = await Promise.all(result.rows.map(buildFullOrder));

  return {
    content: orders,
    page,
    size,
    totalElements,
    totalPages: Math.ceil(totalElements / size),
  };
}

async function findByUuid(uuid) {
  const result = await pool.query(
    `SELECT o.id, o.uuid, o.created_at, o.channel, o.status,
            o.customer_id, o.seller_id, o.shipment_id, o.payment_id, o.metadata_id,
            o.indexed_at
     FROM orders o WHERE o.uuid = $1`,
    [uuid]
  );

  if (result.rows.length === 0) return null;
  return buildFullOrder(result.rows[0]);
}

async function buildFullOrder(row) {
  const [customer, seller, items, shipment, payment, metadata] = await Promise.all([
    fetchOne("customers", row.customer_id),
    fetchOne("sellers", row.seller_id),
    fetchItems(row.id),
    fetchOne("shipments", row.shipment_id),
    fetchOne("payments", row.payment_id),
    fetchOne("order_metadata", row.metadata_id),
  ]);

  const mappedItems = items.map((item) => {
    const itemTotal = Number(item.unit_price) * item.quantity;
    return {
      id: item.id,
      product_id: item.product_id,
      product_name: item.product_name,
      unit_price: Number(item.unit_price),
      quantity: item.quantity,
      category: item.category
        ? {
            id: item.category.id,
            name: item.category.name,
            sub_category: item.category.sub_category || null,
          }
        : null,
      total: itemTotal,
    };
  });

  const orderTotal = mappedItems.reduce((sum, i) => sum + i.total, 0);

  return {
    uuid: row.uuid,
    created_at: row.created_at,
    channel: row.channel,
    total: orderTotal,
    status: row.status ? row.status.toLowerCase() : null,
    customer: customer
      ? { id: customer.id, name: customer.name, email: customer.email, document: customer.document }
      : null,
    seller: seller
      ? { id: seller.id, name: seller.name, city: seller.city, state: seller.state }
      : null,
    items: mappedItems,
    shipment: shipment
      ? {
          carrier: shipment.carrier,
          service: shipment.service,
          status: shipment.status,
          tracking_code: shipment.tracking_code,
        }
      : null,
    payment: payment
      ? {
          method: payment.method,
          status: payment.status,
          transaction_id: payment.transaction_id,
        }
      : null,
    metadata: metadata
      ? { source: metadata.source, user_agent: metadata.user_agent, ip_address: metadata.ip_address }
      : null,
  };
}

async function fetchOne(table, id) {
  if (!id) return null;
  const result = await pool.query(`SELECT * FROM ${table} WHERE id = $1`, [id]);
  return result.rows[0] || null;
}

async function fetchItems(orderId) {
  const result = await pool.query(
    `SELECT oi.*, c.name AS cat_name, c.sub_category_id,
            sc.id AS sub_cat_id, sc.name AS sub_cat_name
     FROM order_items oi
     LEFT JOIN categories c ON oi.category_id = c.id
     LEFT JOIN sub_categories sc ON c.sub_category_id = sc.id
     WHERE oi.order_id = $1`,
    [orderId]
  );

  return result.rows.map((r) => ({
    id: r.id,
    product_id: r.product_id,
    product_name: r.product_name,
    unit_price: r.unit_price,
    quantity: r.quantity,
    category: r.category_id
      ? {
          id: r.category_id,
          name: r.cat_name,
          sub_category: r.sub_cat_id ? { id: r.sub_cat_id, name: r.sub_cat_name } : null,
        }
      : null,
  }));
}

module.exports = { findOrders, findByUuid };
