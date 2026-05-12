'use strict';

// All money is stored in paise (integer). Convert to/from rupees only at the edge.
function paiseToRupees(p) {
  return Number((p / 100).toFixed(2));
}

function formatINR(paise) {
  return `₹${paiseToRupees(paise).toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
}

module.exports = { paiseToRupees, formatINR };
