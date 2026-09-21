

function encodeGeohash(latitude, longitude, precision = 9) {
  const alphabet = "0123456789bcdefghjkmnpqrstuvwxyz";
  let minLatitude = -90;
  let maxLatitude = 90;
  let minLongitude = -180;
  let maxLongitude = 180;
  let hash = "";
  let bit = 0;
  let character = 0;
  let longitudeBit = true;

  while (hash.length < precision) {
    const midpoint = longitudeBit ?
      (minLongitude + maxLongitude) / 2 : (minLatitude + maxLatitude) / 2;
    const value = longitudeBit ? longitude : latitude;
    if (value >= midpoint) {
      character = (character << 1) + 1;
      if (longitudeBit) minLongitude = midpoint;
      else minLatitude = midpoint;
    } else {
      character <<= 1;
      if (longitudeBit) maxLongitude = midpoint;
      else maxLatitude = midpoint;
    }
    longitudeBit = !longitudeBit;
    bit += 1;
    if (bit === 5) {
      hash += alphabet[character];
      bit = 0;
      character = 0;
    }
  }
  return hash;
}

module.exports = {encodeGeohash};
