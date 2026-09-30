

function serializeShop(id, shop) {
  return {
    id,
    name: shop.name,
    contactPhone: shop.contactPhone,
    address: shop.address,
    location: {latitude: shop.latitude ?? shop.location?.latitude, longitude: shop.longitude ?? shop.location?.longitude, placeId: shop.googlePlaceId || null},
    review: shop.review || null,
    onboarding: shop.onboarding || null,
    status: shop.status,
    categories: shop.categories,
    coverImageUrl: shop.coverImageUrl || null,
    createdAt: shop.createdAt,
    updatedAt: shop.updatedAt,
  };
}

function publicShopCard(id, shop, distanceKm = null, isFavourite = false) {
  return {
    id,
    name: shop.name,
    address: {
      area: shop.address.area,
      city: shop.address.city,
      formattedAddress: shop.address.formattedAddress,
    },
    location: {latitude: shop.latitude, longitude: shop.longitude},
    categories: shop.categories,
    coverImageUrl: shop.coverImageUrl || null,
    rating: {average: shop.ratingAverage, count: shop.ratingCount},
    startingPriceMinor: shop.minPriceMinor,
    currency: shop.currency,
    distanceKm: distanceKm === null ? null : Number(distanceKm.toFixed(2)),
    isFavourite,
  };
}

module.exports = {serializeShop, publicShopCard};
