// lib/data/dummy_data.dart
import '../models/models.dart';

class DummyData {
  // All dummy trip data removed - using real TripDataService instead
  static List<Trip> trips = [];
  static List<PlannedTrip> plannedTrips = [];

  static List<VideoPost> videos = [
    VideoPost(
      username: '@kerala_traveler',
      userAvatarUrl: 'https://placehold.co/100x100/AEC6CF/FFFFFF?text=KT',
      videoUrl: 'lib/reels/Kerala itinerary _ Kerala trip plan _ check out description for detailed itinerary.mp4',
      caption: 'Complete Kerala itinerary guide! Perfect trip plan for your next vacation 🏖️',
      likes: '2.4k',
      comments: '156',
      shares: '89',
      location: 'Kerala, India',
      tags: ['Kerala', 'Travel Guide', 'Itinerary', 'South India']
    ),
    VideoPost(
      username: '@wanderbees',
      userAvatarUrl: 'https://placehold.co/100x100/FF6B6B/FFFFFF?text=WB',
      videoUrl: 'lib/reels/Top 10 places to visit in Karnataka😍 _ Shwetha salian _ WanderBees #karnataka #shorts.mp4',
      caption: 'Top 10 must-visit places in Karnataka! Which one is your favorite? 😍',
      likes: '5.2k',
      comments: '342',
      shares: '201',
      location: 'Karnataka, India',
      tags: ['Karnataka', 'Travel', 'Tourism', 'Shorts']
    ),
    VideoPost(
      username: '@foodie_india',
      userAvatarUrl: 'https://placehold.co/100x100/4ECDC4/FFFFFF?text=FI',
      videoUrl: 'lib/reels/\$2.50 Thali & Filter Coffee in India 🇮🇳 #streetfood #india #travelblogger #travel #foodie.mp4',
      caption: 'Amazing \$2.50 thali in India! Best budget food experience 🇮🇳',
      likes: '8.9k',
      comments: '567',
      shares: '312',
      location: 'India',
      tags: ['Street Food', 'Budget Travel', 'Foodie', 'India']
    ),
    VideoPost(
      username: '@travel_jaipur',
      userAvatarUrl: 'https://placehold.co/100x100/FFA07A/FFFFFF?text=TJ',
      videoUrl: 'lib/reels/3 Day Jaipur India Travel Itinerary -- PART ONE #indiatravel #jaipur #jaipurcity.mp4',
      caption: '3 Day Jaipur itinerary - Part 1! Pink City travel guide 🏰',
      likes: '3.7k',
      comments: '234',
      shares: '145',
      location: 'Jaipur, Rajasthan',
      tags: ['Jaipur', 'Rajasthan', 'Travel Itinerary', 'Heritage']
    ),
    VideoPost(
      username: '@travel_guide_india',
      userAvatarUrl: 'https://placehold.co/100x100/98D8C8/FFFFFF?text=TGI',
      videoUrl: 'lib/reels/8 Best Places to Visit in India (May to December) 🧳 _ Monthly Travel Guide 2025.mp4',
      caption: '8 Best places to visit in India from May to December! Monthly travel guide 🧳',
      likes: '12.5k',
      comments: '892',
      shares: '567',
      location: 'India',
      tags: ['Travel Guide', 'India', 'Tourism', '2025']
    ),
    VideoPost(
      username: '@south_india_travel',
      userAvatarUrl: 'https://placehold.co/100x100/F7DC6F/FFFFFF?text=SIT',
      videoUrl: 'lib/reels/9 Places To Visit In South India (June to August) #travel #southindia #trip #shorts #india.mp4',
      caption: '9 amazing places in South India perfect for June-August! Monsoon travel 🌧️',
      likes: '6.8k',
      comments: '445',
      shares: '278',
      location: 'South India',
      tags: ['South India', 'Monsoon', 'Travel', 'Shorts']
    ),
    VideoPost(
      username: '@solo_traveler',
      userAvatarUrl: 'https://placehold.co/100x100/BB8FCE/FFFFFF?text=ST',
      videoUrl: 'lib/reels/Best Budget SOLO Travel Destinations in INDIA which are SAFE for Female Travel _ Khushboo Vasudeva.mp4',
      caption: 'Best budget solo travel destinations in India - Safe for female travelers! ✈️',
      likes: '15.3k',
      comments: '1.2k',
      shares: '789',
      location: 'India',
      tags: ['Solo Travel', 'Female Travel', 'Budget', 'Safety']
    ),
    VideoPost(
      username: '@luxury_resorts',
      userAvatarUrl: 'https://placehold.co/100x100/FFB347/FFFFFF?text=LR',
      videoUrl: 'lib/reels/Breathtaking resorts in India 🇮🇳 Must visit!.mp4',
      caption: 'Breathtaking resorts in India you must visit! Luxury travel destinations 🇮🇳',
      likes: '9.4k',
      comments: '623',
      shares: '456',
      location: 'India',
      tags: ['Resorts', 'Luxury', 'Travel', 'India']
    ),
    VideoPost(
      username: '@notonthemap',
      userAvatarUrl: 'https://placehold.co/100x100/85C1E2/FFFFFF?text=NM',
      videoUrl: 'lib/reels/Have you been to this iconic temple in south India by @notonthemap.     #shorts  #shotoniphone.mp4',
      caption: 'Iconic temple in South India! Hidden gem you must visit 🏛️',
      likes: '4.1k',
      comments: '289',
      shares: '198',
      location: 'South India',
      tags: ['Temple', 'South India', 'Shorts', 'Hidden Gems']
    ),
    VideoPost(
      username: '@karnataka_tourism',
      userAvatarUrl: 'https://placehold.co/100x100/52BE80/FFFFFF?text=KT',
      videoUrl: 'lib/reels/Places To Visit In Monsoon _ Karnataka Tourism _ Monsoon Travel.mp4',
      caption: 'Best places to visit in Karnataka during monsoon! Perfect rainy season travel 🌧️',
      likes: '7.6k',
      comments: '512',
      shares: '334',
      location: 'Karnataka, India',
      tags: ['Karnataka', 'Monsoon', 'Tourism', 'Travel']
    ),
  ];

  // Community trips - dummy data for demonstration
  static List<CommunityTrip> communityTrips = [
    // Heritage Trips
    CommunityTrip(
      title: 'Weekend Exploration: Fort Kochi Heritage Walk',
      author: 'by Sarah Johnson',
      date: '2/15/2024',
      participants: '8/15 participants',
      description: 'Join us for a cultural heritage walk through the historic streets of Fort Kochi. We will explore ancient churches, colonial buildings, and the famous Chinese fishing nets.',
      tags: ['Heritage', 'Walking', 'Culture', 'Photography'],
      difficulty: 'easy',
      avatarLetter: 'S'
    ),
    CommunityTrip(
      title: 'Munnar Tea Plantation Heritage Tour',
      author: 'by Priya Menon',
      date: '2/18/2024',
      participants: '15/25 participants',
      description: 'Discover the rich history of tea plantations in Munnar. Visit century-old tea estates, learn about the colonial era, and enjoy breathtaking mountain views.',
      tags: ['Heritage', 'Nature', 'History', 'Tea'],
      difficulty: 'medium',
      avatarLetter: 'P'
    ),
    CommunityTrip(
      title: 'Padmanabhaswamy Temple & Palace Heritage Trail',
      author: 'by Anil Nair',
      date: '2/20/2024',
      participants: '20/30 participants',
      description: 'Explore the architectural marvels of Trivandrum. Visit the famous Padmanabhaswamy Temple, Padmanabhapuram Palace, and learn about Kerala\'s royal history.',
      tags: ['Heritage', 'Temple', 'Architecture', 'History'],
      difficulty: 'easy',
      avatarLetter: 'A'
    ),
    // Walking Trips
    CommunityTrip(
      title: 'Sunrise Beach Walk - Kovalam',
      author: 'by Rahul Sharma',
      date: '2/16/2024',
      participants: '25/40 participants',
      description: 'Start your day with a peaceful sunrise walk along Kovalam beach. Enjoy the morning breeze, collect seashells, and connect with nature.',
      tags: ['Walking', 'Beach', 'Sunrise', 'Nature'],
      difficulty: 'easy',
      avatarLetter: 'R'
    ),
    CommunityTrip(
      title: 'Hill Station Trek - Wayanad',
      author: 'by Deepak Menon',
      date: '2/19/2024',
      participants: '18/25 participants',
      description: 'Moderate trek through Wayanad\'s scenic hills. Experience lush green forests, waterfalls, and panoramic views. Suitable for beginners.',
      tags: ['Walking', 'Trekking', 'Nature', 'Adventure'],
      difficulty: 'medium',
      avatarLetter: 'D'
    ),
    // Data Collection Trips
    CommunityTrip(
      title: 'Public Transport Challenge: Complete City Coverage',
      author: 'by Rajesh Kumar',
      date: '2/17/2024',
      participants: '12/20 participants',
      description: 'Experience the entire public transport network of Thiruvananthapuram in one day. Bus, auto, metro... let\'s see if we can do it all!',
      tags: ['Public Transport', 'Data Collection', 'Urban Planning'],
      difficulty: 'medium',
      avatarLetter: 'R'
    ),
  ];
  // REMOVED: All dummy community trips - use real community service instead
  /*
  static List<CommunityTrip> communityTrips = [
      // Heritage Trips
      CommunityTrip(
        title: 'Weekend Exploration: Fort Kochi Heritage Walk',
        author: 'by Sarah Johnson',
        date: '2/15/2024',
        participants: '8/15 participants',
        description: 'Join us for a cultural heritage walk through the historic streets of Fort Kochi. We will explore ancient churches, colonial buildings, and the famous Chinese fishing nets.',
        tags: ['Heritage', 'Walking', 'Culture', 'Photography'],
        difficulty: 'easy',
        avatarLetter: 'S'
      ),
      CommunityTrip(
        title: 'Munnar Tea Plantation Heritage Tour',
        author: 'by Priya Menon',
        date: '2/18/2024',
        participants: '15/25 participants',
        description: 'Discover the rich history of tea plantations in Munnar. Visit century-old tea estates, learn about the colonial era, and enjoy breathtaking mountain views.',
        tags: ['Heritage', 'Nature', 'History', 'Tea'],
        difficulty: 'medium',
        avatarLetter: 'P'
      ),
      CommunityTrip(
        title: 'Padmanabhaswamy Temple & Palace Heritage Trail',
        author: 'by Anil Nair',
        date: '2/20/2024',
        participants: '20/30 participants',
        description: 'Explore the architectural marvels of Trivandrum. Visit the famous Padmanabhaswamy Temple, Padmanabhapuram Palace, and learn about Kerala\'s royal history.',
        tags: ['Heritage', 'Temple', 'Architecture', 'History'],
        difficulty: 'easy',
        avatarLetter: 'A'
      ),
      CommunityTrip(
        title: 'Bekal Fort & Kasaragod Heritage Walk',
        author: 'by Meera Krishnan',
        date: '2/22/2024',
        participants: '12/20 participants',
        description: 'A journey through time exploring Bekal Fort, ancient mosques, and traditional architecture of North Kerala. Perfect for history enthusiasts.',
        tags: ['Heritage', 'Fort', 'Architecture', 'Culture'],
        difficulty: 'medium',
        avatarLetter: 'M'
      ),
      
      // Walking Trips
      CommunityTrip(
        title: 'Sunrise Beach Walk - Kovalam',
        author: 'by Rahul Sharma',
        date: '2/16/2024',
        participants: '25/40 participants',
        description: 'Start your day with a peaceful sunrise walk along Kovalam beach. Enjoy the morning breeze, collect seashells, and connect with nature.',
        tags: ['Walking', 'Beach', 'Sunrise', 'Nature'],
        difficulty: 'easy',
        avatarLetter: 'R'
      ),
      CommunityTrip(
        title: 'Hill Station Trek - Wayanad',
        author: 'by Deepak Menon',
        date: '2/19/2024',
        participants: '18/25 participants',
        description: 'Moderate trek through Wayanad\'s scenic hills. Experience lush green forests, waterfalls, and panoramic views. Suitable for beginners.',
        tags: ['Walking', 'Trekking', 'Nature', 'Adventure'],
        difficulty: 'medium',
        avatarLetter: 'D'
      ),
      CommunityTrip(
        title: 'City Center Walking Tour - Trivandrum',
        author: 'by Lakshmi Devi',
        date: '2/21/2024',
        participants: '30/50 participants',
        description: 'Explore Trivandrum city center on foot. Visit local markets, street food stalls, and hidden gems. Great for food lovers and urban explorers.',
        tags: ['Walking', 'City', 'Food', 'Culture'],
        difficulty: 'easy',
        avatarLetter: 'L'
      ),
      CommunityTrip(
        title: 'Backwaters Walking Trail - Alleppey',
        author: 'by Suresh Kumar',
        date: '2/23/2024',
        participants: '14/20 participants',
        description: 'A serene walk along the backwaters of Alleppey. Experience village life, paddy fields, and traditional Kerala architecture.',
        tags: ['Walking', 'Backwaters', 'Village', 'Nature'],
        difficulty: 'easy',
        avatarLetter: 'S'
      ),
      
      // Data Collection Trips
      CommunityTrip(
        title: 'Public Transport Challenge: Complete City Coverage',
        author: 'by Rajesh Kumar',
        date: '2/17/2024',
        participants: '12/20 participants',
        description: 'Experience the entire public transport network of Thiruvananthapuram in one day. Bus, auto, metro... let\'s see if we can do it all!',
        tags: ['Public Transport', 'Data Collection', 'Urban Planning'],
        difficulty: 'medium',
        avatarLetter: 'R'
      ),
      CommunityTrip(
        title: 'Rural Transport Data Collection - Kollam',
        author: 'by Geetha Pillai',
        date: '2/19/2024',
        participants: '10/15 participants',
        description: 'Help collect data on rural transport patterns in Kollam district. Document bus routes, frequency, and passenger flow for research purposes.',
        tags: ['Data Collection', 'Rural', 'Research', 'Transport'],
        difficulty: 'medium',
        avatarLetter: 'G'
      ),
      CommunityTrip(
        title: 'Metro Usage Analytics - Kochi',
        author: 'by Vipin Nair',
        date: '2/20/2024',
        participants: '8/12 participants',
        description: 'Join our team to collect metro usage data in Kochi. Track peak hours, passenger demographics, and route preferences.',
        tags: ['Data Collection', 'Metro', 'Analytics', 'Urban'],
        difficulty: 'easy',
        avatarLetter: 'V'
      ),
      CommunityTrip(
        title: 'Accessibility Survey - Public Spaces',
        author: 'by Maya Suresh',
        date: '2/24/2024',
        participants: '15/25 participants',
        description: 'Survey public spaces for accessibility features. Help make Kerala more inclusive by documenting accessibility infrastructure.',
        tags: ['Data Collection', 'Accessibility', 'Inclusion', 'Survey'],
        difficulty: 'easy',
        avatarLetter: 'M'
      ),
      // More Heritage Trips
      CommunityTrip(
        title: 'Mattancherry Palace & Jewish Synagogue Heritage Tour',
        author: 'by Meera Krishnan',
        date: '2/22/2024',
        participants: '12/18 participants',
        description: 'Step back in time as we explore the Dutch Palace and the historic Jewish Synagogue. Learn about the multicultural heritage of Kochi.',
        tags: ['Heritage', 'History', 'Culture', 'Architecture'],
        difficulty: 'easy',
        avatarLetter: 'M'
      ),
      CommunityTrip(
        title: 'Bekal Fort & Kasaragod Heritage Journey',
        author: 'by Vishnu Pillai',
        date: '2/25/2024',
        participants: '18/25 participants',
        description: 'Discover the magnificent Bekal Fort overlooking the Arabian Sea. Explore ancient fortifications and enjoy stunning coastal views.',
        tags: ['Heritage', 'Fort', 'Coastal', 'History'],
        difficulty: 'medium',
        avatarLetter: 'V'
      ),
      // More Walking Trips
      CommunityTrip(
        title: 'Early Morning Beach Walk - Kovalam',
        author: 'by Lakshmi Devi',
        date: '2/16/2024',
        participants: '25/30 participants',
        description: 'Start your day with a refreshing 5km beach walk along Kovalam. Perfect for fitness enthusiasts and nature lovers. We\'ll meet at sunrise!',
        tags: ['Walking', 'Fitness', 'Beach', 'Morning'],
        difficulty: 'easy',
        avatarLetter: 'L'
      ),
      CommunityTrip(
        title: 'Hill Station Trek: Wayanad Nature Walk',
        author: 'by Arun Gopal',
        date: '2/19/2024',
        participants: '15/20 participants',
        description: 'Moderate difficulty trek through Wayanad\'s lush forests. Spot wildlife, enjoy waterfalls, and experience the beauty of Kerala\'s Western Ghats.',
        tags: ['Walking', 'Trekking', 'Nature', 'Adventure'],
        difficulty: 'medium',
        avatarLetter: 'A'
      ),
      CommunityTrip(
        title: 'City Heritage Walk - Trivandrum Old Town',
        author: 'by Deepa Suresh',
        date: '2/21/2024',
        participants: '22/30 participants',
        description: 'Explore Trivandrum\'s old quarters on foot. Visit traditional markets, ancient temples, and colonial-era buildings. Comfortable walking shoes recommended.',
        tags: ['Walking', 'Heritage', 'City', 'Culture'],
        difficulty: 'easy',
        avatarLetter: 'D'
      ),
      CommunityTrip(
        title: 'Sunset Walk: Varkala Cliff Trail',
        author: 'by Ravi Menon',
        date: '2/23/2024',
        participants: '30/35 participants',
        description: 'Beautiful evening walk along Varkala cliffs. Watch the sunset over the Arabian Sea while walking through this scenic coastal path.',
        tags: ['Walking', 'Sunset', 'Coastal', 'Scenic'],
        difficulty: 'easy',
        avatarLetter: 'R'
      ),
      CommunityTrip(
        title: 'Forest Trail: Silent Valley National Park',
        author: 'by Kavya Nair',
        date: '2/26/2024',
        participants: '10/15 participants',
        description: 'Guided walking tour through Silent Valley. Experience pristine nature, diverse flora and fauna. Limited spots available for this exclusive trip.',
        tags: ['Walking', 'Nature', 'Wildlife', 'Forest'],
        difficulty: 'hard',
        avatarLetter: 'K'
      ),
      CommunityTrip(
        title: 'Riverside Walk: Periyar River Trail',
        author: 'by Suresh Kumar',
        date: '2/27/2024',
        participants: '18/25 participants',
        description: 'Peaceful walk along the Periyar River. Perfect for bird watching and enjoying Kerala\'s natural beauty. Bring your camera!',
        tags: ['Walking', 'Nature', 'River', 'Bird Watching'],
        difficulty: 'easy',
        avatarLetter: 'S'
      ),
      // More Data Collection Trips
      CommunityTrip(
        title: 'Rural Transport Data Collection - Kuttanad',
        author: 'by Geetha Pillai',
        date: '2/24/2024',
        participants: '8/15 participants',
        description: 'Help collect data on rural transport patterns in Kuttanad region. Document boat services, local buses, and unique transport modes.',
        tags: ['Data Collection', 'Rural', 'Research', 'Transport'],
        difficulty: 'medium',
        avatarLetter: 'G'
      ),
      CommunityTrip(
        title: 'Metro Usage Patterns Study - Kochi',
        author: 'by Manoj Nair',
        date: '2/28/2024',
        participants: '20/25 participants',
        description: 'Research trip to study Kochi Metro usage patterns. Collect data on peak hours, popular stations, and passenger demographics.',
        tags: ['Data Collection', 'Metro', 'Urban Planning', 'Research'],
        difficulty: 'easy',
        avatarLetter: 'M'
      ),
      CommunityTrip(
        title: 'School Bus Route Optimization Study',
        author: 'by Radha Krishnan',
        date: '3/1/2024',
        participants: '6/10 participants',
        description: 'Help optimize school bus routes by collecting data on student locations, traffic patterns, and route efficiency. Great for urban planning students!',
        tags: ['Data Collection', 'Education', 'Transport', 'Optimization'],
        difficulty: 'easy',
        avatarLetter: 'R'
      ),
      CommunityTrip(
        title: 'Last Mile Connectivity Survey',
        author: 'by Ajith Kumar',
        date: '3/2/2024',
        participants: '15/20 participants',
        description: 'Survey last-mile connectivity options from major transport hubs. Document auto-rickshaw, bike taxi, and walking route data.',
        tags: ['Data Collection', 'Connectivity', 'Survey', 'Transport'],
        difficulty: 'easy',
        avatarLetter: 'A'
      ),
  ];
  */
  
  // Chat messages removed - use real AI service
  static List<ChatMessage> chatMessages = [];
  
  // Achievements removed - calculate from real data
  static List<Achievement> achievements = [];
}