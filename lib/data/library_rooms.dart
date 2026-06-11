// lib/data/library_rooms.dart

final List<Map<String, dynamic>> libraryRooms = [
  {
    'id': 'room_01',
    'name': 'Küçük Çalışma Odası',
    'description': 'Kendi kütüphanenizin ilk adımı.',
    'multiplier': 1.0,
    'totalStages': 7,
    'unlockRequirement': null, // İlk oda her zaman açık
    'baseCosts': [300, 500, 750, 1000, 1300, 1700, 2200],
    'stageTitles': [
      "Başlangıç", // Stage 0
      "İlk Rafı Kur", // Stage 1
      "İlk Kitapları Yerleştir", // Stage 2
      "Çalışma Masası", // Stage 3
      "Okuma Lambası", // Stage 4
      "Halı", // Stage 5
      "Dünya Küresi", // Stage 6
      "Odayı Tamamla" // Stage 7
    ],
  },
  {
    'id': 'room_02',
    'name': 'Doğa Kanadı',
    'description': 'Huzur veren yeşil bir okuma alanı.',
    'multiplier': 1.4,
    'totalStages': 7,
    'unlockRequirement': 'room_01', // Küçük Çalışma Odası bitince açılır
    'baseCosts': [300, 500, 750, 1000, 1300, 1700, 2200],
    'stageTitles': [
      "Başlangıç",
      "Sarmaşıkları Ekle",
      "Bambu Raflar",
      "Bahçe Koltuğu",
      "Su Şelalesi",
      "Doğal Taş Zemin",
      "Nadir Bitkiler",
      "Kanadı Tamamla"
    ],
  },
  {
    'id': 'room_03',
    'name': 'Antik Galeri',
    'description': 'Tarihin tozlu raflarında bir yolculuk.',
    'multiplier': 1.8,
    'totalStages': 7,
    'unlockRequirement': 'room_02',
    'baseCosts': [300, 500, 750, 1000, 1300, 1700, 2200],
    'stageTitles': [
      "Başlangıç",
      "Mermer Sütunlar",
      "Antik Parşömenler",
      "Büyük Arşiv",
      "Heykel Kaideleri",
      "Yağlı Boya Tablolar",
      "Altın Vurgular",
      "Galeriyi Tamamla"
    ],
  },
  {
    'id': 'room_04',
    'name': 'Teknoloji Merkezi',
    'description': 'Geleceğin bilgisi burada depolanıyor.',
    'multiplier': 2.3,
    'totalStages': 7,
    'unlockRequirement': 'room_03',
    'baseCosts': [300, 500, 750, 1000, 1300, 1700, 2200],
    'stageTitles': [
      "Başlangıç",
      "Server Kabinleri",
      "Hologram Masası",
      "Neon Aydınlatma",
      "Veri Depolama",
      "Akıllı Paneller",
      "VR İstasyonu",
      "Merkezi Tamamla"
    ],
  },
  {
    'id': 'room_05',
    'name': 'Kraliyet Salonu',
    'description': 'Sadece en bilge olanlar için en görkemli salon.',
    'multiplier': 3.0,
    'totalStages': 7,
    'unlockRequirement': 'room_04',
    'baseCosts': [300, 500, 750, 1000, 1300, 1700, 2200],
    'stageTitles': [
      "Başlangıç",
      "Kadife Perdeler",
      "Dev Avize",
      "Kraliyet Kitaplığı",
      "Taht ve Masa",
      "İşlemeli Tavan",
      "Nadir Eserler",
      "Salonu Tamamla"
    ],
  },
];