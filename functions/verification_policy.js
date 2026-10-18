'use strict';
function portfolioContribution(counts) { return Math.min(3,Object.values(counts).filter(n=>n>0).length)*2; }
function validMedia(contentType, bytes) {
  return Number(bytes)>0 && ((['image/jpeg','image/png','image/webp'].includes(contentType) && bytes<=10*1024*1024) ||
    (['video/mp4','video/quicktime','video/webm'].includes(contentType) && bytes<=50*1024*1024));
}
module.exports={validMedia,portfolioContribution};
