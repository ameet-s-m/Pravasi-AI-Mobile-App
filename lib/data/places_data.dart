import '../models/place_model.dart';

class PlacesData {
  static List<PlaceModel> getPlaces() {
    return [
      PlaceModel(
        name: 'Taj Mahal',
        location: 'Agra, Uttar Pradesh',
        description: 'A magnificent white marble mausoleum, one of the Seven Wonders of the World',
        modelPath: 'assets/models/taj_mahal.glb',
        imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800',
      ),
      PlaceModel(
        name: 'India Gate',
        location: 'New Delhi',
        description: 'A war memorial arch dedicated to the soldiers of the British Indian Army',
        modelPath: 'assets/models/india_gate.glb',
        imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
      ),
      // Only include places with actual model files
      // Other models (golden_temple, ayodhya, kedarnath) don't exist yet
    ];
  }
}

