var assert = require('chai').assert;

module.exports = async function (promise) {
    try {
        await promise;
    } catch (err) {
        return;
    }
    assert(false, 'Expected throw not received');
}