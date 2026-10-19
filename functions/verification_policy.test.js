const test = require('node:test');
const assert = require('node:assert/strict');
const { validMedia, portfolioContribution } = require('./verification_policy');
test('optional portfolio contribution is capped at six and ignores empty skills',()=>{
  assert.equal(portfolioContribution({a:0}),0);
  assert.equal(portfolioContribution({a:5}),2);
  assert.equal(portfolioContribution({a:5,b:1,c:1,d:2}),6);
});
test('media limits reject oversized, unsupported, and empty uploads', () => {
  assert.equal(validMedia('image/jpeg', 10 * 1024 * 1024), true);
  assert.equal(validMedia('video/mp4', 50 * 1024 * 1024), false);
  assert.equal(validMedia('image/jpeg', 11 * 1024 * 1024), false);
  assert.equal(validMedia('video/mp4', 51 * 1024 * 1024), false);
  assert.equal(validMedia('application/pdf', 10), false);
  assert.equal(validMedia('image/png', 0), false);
});
