import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const BRAND = 'NexusLogistics WMS';

const C = {
  navy: [15, 23, 42],
  navyMid: [30, 41, 59],
  cyan: [6, 182, 212],
  cyanDark: [8, 145, 178],
  amber: [245, 158, 11],
  emerald: [16, 185, 129],
  red: [239, 68, 68],
  slate: [100, 116, 139],
  slateLight: [148, 163, 184],
  paper: [248, 250, 252],
  white: [255, 255, 255],
  ink: [30, 41, 59],
};

const TABLE_HEAD = [15, 23, 42];
const TABLE_ZEBRA = [248, 250, 252];

const STATUS_COLORS = {
  'In Stock': C.emerald,
  'Low Stock': C.amber,
  'Out of Stock': C.red,
};

function formatCurrency(n) {
  if (n == null || Number.isNaN(Number(n))) return '$0.00';
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(Number(n));
}

function formatNumber(n) {
  return new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(Number(n) || 0);
}

function formatDateTime(iso, useUtc = false) {
  const d = new Date(iso || Date.now());
  return d.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: useUtc ? 'UTC' : undefined,
  });
}

function buildReportId(iso) {
  const d = new Date(iso || Date.now());
  const ymd = d.toISOString().slice(0, 10).replace(/-/g, '');
  const seq = String(d.getTime()).slice(-6);
  return `NL-AUD-${ymd}-${seq}`;
}

function truncateLabel(text, max = 18) {
  const s = String(text || '—');
  return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function applyFooters(doc, pageWidth, pageHeight, margin) {
  const total = doc.internal.getNumberOfPages();
  for (let i = 1; i <= total; i += 1) {
    doc.setPage(i);
    const footerY = pageHeight - 10;
    doc.setDrawColor(...C.slateLight);
    doc.setLineWidth(0.2);
    doc.line(margin, footerY - 4, pageWidth - margin, footerY - 4);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(...C.slate);
    doc.text(`Confidential • ${BRAND} • Auto-generated Report`, pageWidth / 2, footerY, {
      align: 'center',
    });
    doc.setFontSize(7.5);
    doc.setTextColor(...C.ink);
    doc.text(`Page ${i} of ${total}`, pageWidth - margin, footerY, { align: 'right' });
  }
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawPremiumHeader(doc, pageWidth, margin, meta) {
  const headerH = 38;
  doc.setFillColor(...C.navy);
  doc.rect(0, 0, pageWidth, headerH, 'F');
  doc.setFillColor(...C.cyan);
  doc.rect(0, headerH - 2, pageWidth, 2, 'F');

  doc.setTextColor(...C.white);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(18);
  doc.text(BRAND, margin, 14);
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(203, 213, 225);
  doc.text('Executive Inventory Audit Report', margin, 21);

  doc.setFontSize(8);
  doc.setTextColor(...C.white);
  const rightX = pageWidth - margin;
  doc.text(`Report ID: ${meta.reportId}`, rightX, 12, { align: 'right' });
  doc.text(`Generated: ${meta.generatedAt}`, rightX, 17, { align: 'right' });
  doc.text(`Prepared by: ${meta.preparedBy}`, rightX, 22, { align: 'right' });
  doc.text(`Role: ${meta.role}`, rightX, 27, { align: 'right' });

  return headerH + 6;
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawMetaStrip(doc, margin, y, pageWidth, meta) {
  const h = 14;
  doc.setFillColor(...C.paper);
  doc.setDrawColor(226, 232, 240);
  doc.setLineWidth(0.3);
  doc.roundedRect(margin, y, pageWidth - margin * 2, h, 2, 2, 'FD');
  doc.setFontSize(7.5);
  doc.setTextColor(...C.slate);
  const mid = pageWidth / 2;
  doc.text(`Audit scope: All warehouses • ${meta.lineCount} inventory lines`, margin + 4, y + 5);
  doc.text(
    `In stock: ${meta.inStockLines} • Low: ${meta.lowStockLines} • Out: ${meta.outOfStockLines} • Catalog: ${meta.productCount} SKUs`,
    margin + 4,
    y + 10
  );
  doc.text(`Currency: USD`, mid, y + 5, { align: 'center' });
  doc.text(`Export: PDF / A4`, mid, y + 10, { align: 'center' });
  doc.text(`Status: Official system record`, pageWidth - margin - 4, y + 7.5, { align: 'right' });
  return y + h + 6;
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawSectionTitle(doc, margin, y, title, subtitle = '') {
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(11);
  doc.setTextColor(...C.navy);
  doc.text(title, margin, y);
  if (subtitle) {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(...C.slate);
    doc.text(subtitle, margin, y + 4.5);
    return y + 10;
  }
  return y + 7;
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawKpiCard(doc, x, y, w, h, { label, value, sub, accent }) {
  doc.setFillColor(...C.white);
  doc.setDrawColor(226, 232, 240);
  doc.setLineWidth(0.25);
  doc.roundedRect(x, y, w, h, 2.5, 2.5, 'FD');
  doc.setFillColor(...accent);
  doc.roundedRect(x, y, w, 1.8, 2.5, 2.5, 'F');

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(7.5);
  doc.setTextColor(...C.slate);
  doc.text(label, x + 4, y + 8);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(13);
  doc.setTextColor(...C.ink);
  doc.text(value, x + 4, y + 16);

  if (sub) {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(...C.slate);
    doc.text(sub, x + 4, y + 21);
  }
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawKpiGrid(doc, margin, y, pageWidth, fs, alerts) {
  const gap = 5;
  const cols = 2;
  const cardW = (pageWidth - margin * 2 - gap) / cols;
  const cardH = 24;
  /* Server-computed counts are authoritative (identical to the dashboard KPIs);
     the alert rows are only a fallback for older payloads. */
  const low = fs.low_stock_lines ?? alerts.filter((a) => a.stock_status === 'Low Stock').length;
  const out =
    fs.out_of_stock_lines ?? alerts.filter((a) => a.stock_status === 'Out of Stock').length;

  const cards = [
    {
      label: 'Inventory valuation (cost)',
      value: formatCurrency(fs.cost_value),
      sub: 'Σ quantity × unit cost',
      accent: C.cyan,
    },
    {
      label: 'Retail potential',
      value: formatCurrency(fs.retail_value),
      sub: 'Σ quantity × unit price',
      accent: C.navyMid,
    },
    {
      label: 'Total units on hand',
      value: formatNumber(fs.total_units),
      sub: `${formatNumber(fs.inventory_lines)} inventory lines`,
      accent: C.emerald,
    },
    {
      label: 'Stock risk lines',
      value: formatNumber(low + out),
      sub: `${formatNumber(low)} low • ${formatNumber(out)} out of stock`,
      accent: C.amber,
    },
  ];

  cards.forEach((card, i) => {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = margin + col * (cardW + gap);
    const cy = y + row * (cardH + gap);
    drawKpiCard(doc, x, cy, cardW, cardH, card);
  });

  return y + 2 * (cardH + gap) + 4;
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawBarChart(doc, {
  x,
  y,
  w,
  h,
  title,
  items,
  valueKey = 'value',
  labelKey = 'label',
  color = C.cyan,
  formatValue = (v) => String(v),
}) {
  doc.setFillColor(...C.white);
  doc.setDrawColor(226, 232, 240);
  doc.roundedRect(x, y, w, h, 2, 2, 'S');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8);
  doc.setTextColor(...C.ink);
  doc.text(title, x + 4, y + 6);

  const maxVal = Math.max(...items.map((d) => Number(d[valueKey]) || 0), 1);
  const chartTop = y + 10;
  const chartH = h - 16;
  const barAreaW = w - 52;
  const rowH = Math.min(8, chartH / Math.max(items.length, 1));

  items.slice(0, 8).forEach((item, idx) => {
    const val = Number(item[valueKey]) || 0;
    const barW = (val / maxVal) * barAreaW;
    const rowY = chartTop + idx * rowH;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.5);
    doc.setTextColor(...C.slate);
    doc.text(truncateLabel(item[labelKey], 14), x + 4, rowY + rowH * 0.72);
    doc.setFillColor(...color);
    doc.roundedRect(x + 48, rowY + 1, Math.max(barW, 0.5), rowH - 2, 1, 1, 'F');
    doc.setTextColor(...C.ink);
    doc.text(formatValue(val, item), x + w - 4, rowY + rowH * 0.72, { align: 'right' });
  });
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawStackedDistribution(doc, x, y, w, h, segments) {
  doc.setFillColor(...C.white);
  doc.setDrawColor(226, 232, 240);
  doc.roundedRect(x, y, w, h, 2, 2, 'S');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8);
  doc.setTextColor(...C.ink);
  doc.text('Inventory distribution (by condition)', x + 4, y + 6);

  const total = segments.reduce((s, seg) => s + (Number(seg.value) || 0), 0) || 1;
  const barY = y + 12;
  const barH = 10;
  const barX = x + 4;
  const barW = w - 8;
  let offset = 0;

  segments.forEach((seg) => {
    const frac = (Number(seg.value) || 0) / total;
    const segW = frac * barW;
    if (segW <= 0) return;
    doc.setFillColor(...seg.color);
    doc.rect(barX + offset, barY, segW, barH, 'F');
    offset += segW;
  });

  let legendY = barY + barH + 5;
  segments.forEach((seg) => {
    const pct = ((Number(seg.value) || 0) / total) * 100;
    doc.setFillColor(...seg.color);
    doc.circle(x + 6, legendY - 1.2, 1.5, 'F');
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.5);
    doc.setTextColor(...C.slate);
    doc.text(`${seg.label}: ${formatNumber(seg.value)} (${pct.toFixed(1)}%)`, x + 10, legendY);
    legendY += 5;
  });
}

/**
 * @param {import('jspdf').jsPDF} doc
 */
function drawRiskChart(doc, x, y, w, h, alerts) {
  const byWarehouse = new Map();
  alerts.forEach((a) => {
    const key = a.warehouse || 'Unknown';
    if (!byWarehouse.has(key)) {
      byWarehouse.set(key, { low: 0, out: 0 });
    }
    const row = byWarehouse.get(key);
    if (a.stock_status === 'Out of Stock') row.out += 1;
    else row.low += 1;
  });

  const items = [...byWarehouse.entries()]
    .map(([label, counts]) => {
      const total = counts.low + counts.out;
      return {
        label,
        value: total,
        display: `${total} (${counts.low} low / ${counts.out} out)`,
      };
    })
    .sort((a, b) => b.value - a.value)
    .slice(0, 6);

  if (!items.length) {
    doc.setFillColor(...C.white);
    doc.setDrawColor(226, 232, 240);
    doc.roundedRect(x, y, w, h, 2, 2, 'S');
    doc.setFontSize(8);
    doc.setTextColor(...C.slate);
    doc.text('Low stock risk — no alert lines', x + 4, y + 10);
    doc.text('All tracked lines are above minimum threshold.', x + 4, y + 16);
    return;
  }

  drawBarChart(doc, {
    x,
    y,
    w,
    h,
    title: 'Low stock risk (alert lines by warehouse)',
    items,
    valueKey: 'value',
    labelKey: 'label',
    color: C.amber,
    formatValue: (v, item) => item?.display || String(v),
  });
}

function tableStyles() {
  return {
    theme: 'plain',
    styles: {
      fontSize: 7.5,
      cellPadding: { top: 2.5, right: 2.5, bottom: 2.5, left: 2.5 },
      textColor: C.ink,
      lineColor: [226, 232, 240],
      lineWidth: 0.15,
      overflow: 'linebreak',
    },
    headStyles: {
      fillColor: TABLE_HEAD,
      textColor: C.white,
      fontStyle: 'bold',
      fontSize: 7.5,
    },
    alternateRowStyles: { fillColor: TABLE_ZEBRA },
    margin: { left: 12, right: 12 },
  };
}

function statusCellHook(statusColumnIndex = 5) {
  return {
    didParseCell(data) {
      if (data.section !== 'body' || data.column.index !== statusColumnIndex) return;
      const status = String(data.cell.raw || '');
      const rgb = STATUS_COLORS[status];
      if (!rgb) return;
      data.cell.styles.textColor = rgb;
      data.cell.styles.fontStyle = 'bold';
    },
  };
}

/**
 * Generates executive inventory audit PDF from /reports/inventory-audit payload.
 */
export function generateInventoryAuditPdf(report, { user, useUtc = false } = {}) {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 12;
  const contentBottom = pageHeight - 16;

  const generatedAt = report.generated_at || new Date().toISOString();
  const preparedBy =
    user?.username || report.generated_by?.username || report.generated_by?.email || 'System';
  const role = user?.role || report.generated_by?.role || '—';
  const reportId = buildReportId(generatedAt);
  const fs = report.financial_summary || {};
  const alerts = report.low_stock_alerts || [];
  const condition = report.condition_breakdown || {};
  const warehouses = report.warehouse_comparison || [];

  const detail = report.inventory_detail || [];
  const countByStatus = (status) => detail.filter((r) => r.stock_status === status).length;

  const meta = {
    reportId,
    generatedAt: formatDateTime(generatedAt, useUtc),
    preparedBy,
    role,
    lineCount: fs.inventory_lines ?? detail.length,
    productCount: fs.product_count ?? 0,
    inStockLines: fs.in_stock_lines ?? countByStatus('In Stock'),
    lowStockLines: fs.low_stock_lines ?? countByStatus('Low Stock'),
    outOfStockLines: fs.out_of_stock_lines ?? countByStatus('Out of Stock'),
  };

  let y = drawPremiumHeader(doc, pageWidth, margin, meta);
  y = drawMetaStrip(doc, margin, y, pageWidth, meta);
  y = drawSectionTitle(doc, margin, y, 'Executive summary', 'Key financial and operational indicators');
  y = drawKpiGrid(doc, margin, y, pageWidth, fs, alerts);

  const chartGap = 5;
  const chartW = (pageWidth - margin * 2 - chartGap) / 2;
  const chartH = 48;

  if (y + chartH > contentBottom - 20) {
    doc.addPage();
    y = margin + 4;
  }

  y = drawSectionTitle(
    doc,
    margin,
    y,
    'Analytics overview',
    'Distribution, warehouse comparison, and stock risk'
  );

  const conditionSegments = [
    { label: 'Available / Good', value: condition.available_qty ?? 0, color: C.emerald },
    { label: 'Damaged', value: condition.damaged_qty ?? 0, color: C.red },
    { label: 'Inspection', value: condition.inspection_qty ?? 0, color: C.amber },
  ].filter((s) => s.value > 0);

  drawStackedDistribution(doc, margin, y, chartW, chartH, conditionSegments.length ? conditionSegments : [
    { label: 'No stock', value: 1, color: C.slateLight },
  ]);

  const warehouseItems = warehouses.map((w) => ({
    label: w.warehouse_name,
    value: w.cost_value ?? w.total_units ?? 0,
  }));

  drawBarChart(doc, {
    x: margin + chartW + chartGap,
    y,
    w: chartW,
    h: chartH,
    title: 'Warehouse stock comparison (cost value)',
    items: warehouseItems,
    valueKey: 'value',
    labelKey: 'label',
    color: C.cyanDark,
    formatValue: (v) => formatCurrency(v),
  });

  y += chartH + 8;

  if (y + 42 > contentBottom) {
    doc.addPage();
    y = margin + 4;
  }

  drawRiskChart(doc, margin, y, pageWidth - margin * 2, 40, alerts);
  y += 46;

  const profitNote = `Estimated margin: ${formatCurrency(fs.estimated_profit)}`;
  doc.setFont('helvetica', 'italic');
  doc.setFontSize(7.5);
  doc.setTextColor(...C.slate);
  doc.text(profitNote, margin, y);
  y += 8;

  if (y > contentBottom - 30) {
    doc.addPage();
    y = margin + 4;
  }

  y = drawSectionTitle(
    doc,
    margin,
    y,
    'Inventory detail register',
    'Product × warehouse lines with condition split and valuation'
  );

  const detailBody = detail.map((row) => [
    row.sku,
    row.product_name,
    row.category,
    row.warehouse_name,
    String(row.current_quantity),
    row.stock_status,
    `G:${row.good_qty} D:${row.damaged_qty}`,
    formatCurrency(row.unit_cost),
    formatCurrency(row.line_cost_value),
  ]);

  autoTable(doc, {
    startY: y,
    head: [
      [
        'SKU',
        'Product',
        'Category',
        'Warehouse',
        'Qty',
        'Status',
        'Condition',
        'Unit cost',
        'Line value',
      ],
    ],
    body: detailBody.length
      ? detailBody
      : [['—', 'No inventory records', '—', '—', '0', '—', '—', '—', '—']],
    ...tableStyles(),
    columnStyles: {
      0: { cellWidth: 16 },
      1: { cellWidth: 28 },
      2: { cellWidth: 18 },
      3: { cellWidth: 22 },
      4: { cellWidth: 10, halign: 'right' },
      5: { cellWidth: 16, halign: 'center' },
      6: { cellWidth: 18 },
      7: { cellWidth: 16, halign: 'right' },
      8: { cellWidth: 18, halign: 'right' },
    },
    margin: { left: margin, right: margin, bottom: 16 },
    showHead: 'everyPage',
    ...statusCellHook(),
  });

  y = doc.lastAutoTable.finalY + 8;

  if (y > contentBottom - 40) {
    doc.addPage();
    y = margin + 4;
  }

  y = drawSectionTitle(doc, margin, y, 'High-risk stock alerts', 'Lines at or below minimum threshold');

  const alertBody = alerts.map((a) => [
    a.sku,
    a.product_name,
    a.warehouse,
    String(a.current_quantity),
    String(a.min_stock_threshold),
    a.stock_status,
    formatCurrency(a.line_cost_value),
  ]);

  autoTable(doc, {
    startY: y,
    head: [['SKU', 'Product', 'Warehouse', 'On hand', 'Min', 'Status', 'Cost value']],
    body: alertBody.length
      ? alertBody
      : [['—', 'No low-stock or out-of-stock lines', '—', '—', '—', 'In Stock', '—']],
    ...tableStyles(),
    headStyles: {
      fillColor: [180, 83, 9],
      textColor: C.white,
      fontStyle: 'bold',
      fontSize: 7.5,
    },
    columnStyles: {
      5: { halign: 'center' },
      6: { halign: 'right' },
    },
    margin: { left: margin, right: margin, bottom: 16 },
    ...statusCellHook(),
  });

  y = doc.lastAutoTable.finalY + 8;

  if (y > contentBottom - 35) {
    doc.addPage();
    y = margin + 4;
  }

  y = drawSectionTitle(doc, margin, y, 'Fast-moving products', `Top outbound SKUs (${90} days)`);

  const fast = report.fast_moving_products || [];
  autoTable(doc, {
    startY: y,
    head: [['Rank', 'SKU', 'Product', 'Category', 'Outbound units', 'Movements']],
    body: fast.map((f) => [
      String(f.rank),
      f.sku,
      f.product_name,
      f.category,
      String(f.outbound_units),
      String(f.movement_count),
    ]),
    ...tableStyles(),
    margin: { left: margin, right: margin, bottom: 16 },
  });

  applyFooters(doc, pageWidth, pageHeight, margin);

  const safeDate = new Date(generatedAt).toISOString().slice(0, 10);
  doc.save(`${BRAND.replace(/\s+/g, '-')}-Inventory-Audit-${safeDate}.pdf`);
}
