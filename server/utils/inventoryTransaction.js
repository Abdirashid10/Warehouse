/**
 * Runs inventory writes without MongoDB multi-document transactions.
 * Standalone MongoDB can hang on withTransaction(); sequential writes are sufficient here.
 */
async function runInventoryOperation(operation) {
  return operation(null);
}

module.exports = { runInventoryOperation };
