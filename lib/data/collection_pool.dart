import '../features/library/models/collection_card.dart';

final List<CollectionCard> collectionPool = [
  // ==========================================
  // SET 1: BİLGE AMCA (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'ba_01',
      name: 'Bilge Şapkası',
      description: 'Yılların birikimiyle ağırlaşmış kadim bir şapka.',
      stars: 1,
      imagePath: 'lib/assets/cards/bilge_sapkasi.png',
      setName: 'Bilge Amca'
  ),
  CollectionCard(
      id: 'ba_02',
      name: 'Bilge Bastonu',
      description: 'Yürürken her adımda yere bilgelik fısıldayan baston.',
      stars: 1,
      imagePath: 'lib/assets/cards/bilge_bastonu.png',
      setName: 'Bilge Amca'
  ),
  CollectionCard(
      id: 'ba_03',
      name: 'Bilge Gözlüğü',
      description: 'Gözden kaçan en küçük satır arası detayları bile büyütür.',
      stars: 2,
      imagePath: 'lib/assets/cards/bilge_gozlugu.png',
      setName: 'Bilge Amca'
  ),
  CollectionCard(
      id: 'ba_04',
      name: 'Bilge Parşömeni',
      description: 'Üzerine henüz yazılmamış gelecek sırlarını barındırır.',
      stars: 2,
      imagePath: 'lib/assets/cards/bilge_parsemeni.png',
      setName: 'Bilge Amca'
  ),
  CollectionCard(
      id: 'ba_05',
      name: 'Bilge Tüy Kalemi',
      description: 'Kendi mürekkebini kendi üreten efsanevi yazı aracı.',
      stars: 3,
      imagePath: 'lib/assets/cards/bilge_tuy_kalemi.png',
      setName: 'Bilge Amca'
  ),
  CollectionCard(
      id: 'ba_06',
      name: 'Bilgelik Kitabı',
      description: 'Kütüphanenin en korunaklı rafında saklanan başyapıt.',
      stars: 3,
      imagePath: 'lib/assets/cards/bilgelik_kitabi.png',
      setName: 'Bilge Amca'
  ),

  // ==========================================
  // SET 2: KÜTÜPHANE KEDİSİ (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'kk_01',
      name: 'Mama Kabı',
      description: 'Asla boş kalmaması gereken gizemli bir kap.',
      stars: 1,
      imagePath: 'lib/assets/cards/mama_kabi.png',
      setName: 'Kütüphane Kedisi'
  ),
  CollectionCard(
      id: 'kk_02',
      name: 'Yün Yumak',
      description: 'Kütüphane rafları arasında yuvarlanan renkli oyuncak.',
      stars: 1,
      imagePath: 'lib/assets/cards/yun_yumak.png',
      setName: 'Kütüphane Kedisi'
  ),
  CollectionCard(
      id: 'kk_03',
      name: 'Oyuncak Fare',
      description: 'Kedinin en sevdiği sahte avı.',
      stars: 1,
      imagePath: 'lib/assets/cards/oyuncak_fare.png',
      setName: 'Kütüphane Kedisi'
  ),
  CollectionCard(
      id: 'kk_04',
      name: 'Kedi Yastığı',
      description: 'Üzerinde en derin uykuların çekildiği yumuşak minder.',
      stars: 2,
      imagePath: 'lib/assets/cards/kedi_yastigi.png',
      setName: 'Kütüphane Kedisi'
  ),
  CollectionCard(
      id: 'kk_05',
      name: 'Çanlı Tasma',
      description: 'Kütüphanede sessizliği hafifçe bozan gümüş çıngırak.',
      stars: 2,
      imagePath: 'lib/assets/cards/canli_tasma.png',
      setName: 'Kütüphane Kedisi'
  ),
  CollectionCard(
      id: 'kk_06',
      name: 'Altın Tasma',
      description: 'Sadece kütüphanenin gerçek sahibine layık asil bir tasma.',
      stars: 3,
      imagePath: 'lib/assets/cards/altin_tasma.png',
      setName: 'Kütüphane Kedisi'
  ),

  // ==========================================
  // SET 3: AKADEMİ BAYKUŞU (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'ab_01',
      name: 'Baykuş Tüyü',
      description: 'Gecenin karanlığında havada süzülen hafif bir tüy.',
      stars: 1,
      imagePath: 'lib/assets/cards/baykus_tuyu.png',
      setName: 'Akademi Baykuşu'
  ),
  CollectionCard(
      id: 'ab_02',
      name: 'Mektup Tomarı',
      description: 'Uzak diyarlardan önemli haberler getiren rulo.',
      stars: 1,
      imagePath: 'lib/assets/cards/mektup_tomari.png',
      setName: 'Akademi Baykuşu'
  ),
  CollectionCard(
      id: 'ab_03',
      name: 'Gece Lambası',
      description: 'Gece çalışan akademisyenlerin sadık dostu.',
      stars: 2,
      imagePath: 'lib/assets/cards/gece_lambasi.png',
      setName: 'Akademi Baykuşu'
  ),
  CollectionCard(
      id: 'ab_04',
      name: 'Gümüş Pençe',
      description: 'Bilgiyi sıkıca kavrayan metalik bir pençe motifi.',
      stars: 2,
      imagePath: 'lib/assets/cards/gumus_pence.png',
      setName: 'Akademi Baykuşu'
  ),
  CollectionCard(
      id: 'ab_05',
      name: 'Akademi Rozeti',
      description: 'Başarıyla tamamlanan sınavların onurlu nişanı.',
      stars: 3,
      imagePath: 'lib/assets/cards/akademi_rozeti.png',
      setName: 'Akademi Baykuşu'
  ),
  CollectionCard(
      id: 'ab_06',
      name: 'Bilgelik Madalyası',
      description: 'Sadece en yüksek skora ulaşan dehalara verilir.',
      stars: 3,
      imagePath: 'lib/assets/cards/bilgelik_madalyasi.png',
      setName: 'Akademi Baykuşu'
  ),

  // ==========================================
  // SET 4: ZAMAN BEKÇİSİ (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'zb_01',
      name: 'Saat Anahtarı',
      description: 'Zamanı ileri sarmak için kullanılan minik mekanik anahtar.',
      stars: 1,
      imagePath: 'lib/assets/cards/saat_anahtari.png',
      setName: 'Zaman Bekçisi'
  ),
  CollectionCard(
      id: 'zb_02',
      name: 'Saat Zinciri',
      description: 'Köstekli saatleri koruyan sağlam metal örgü.',
      stars: 1,
      imagePath: 'lib/assets/cards/saat_zinciri.png',
      setName: 'Zaman Bekçisi'
  ),
  CollectionCard(
      id: 'zb_03',
      name: 'Bronz Saat',
      description: 'Tık tık sesleriyle kütüphane ritmini tutan eski saat.',
      stars: 2,
      imagePath: 'lib/assets/cards/bronz_saat.png',
      setName: 'Zaman Bekçisi'
  ),
  CollectionCard(
      id: 'zb_04',
      name: 'Cep Saati',
      description: 'Cepte taşınan, altın kaplama hassas zaman ölçer.',
      stars: 2,
      imagePath: 'lib/assets/cards/cep_saati.png',
      setName: 'Zaman Bekçisi'
  ),
  CollectionCard(
      id: 'zb_05',
      name: 'Kum Saati',
      description: 'Akan kumların gizemiyle büyüleyen kadim zaman aracı.',
      stars: 3,
      imagePath: 'lib/assets/cards/kum_saati.png',
      setName: 'Zaman Bekçisi'
  ),
  CollectionCard(
      id: 'zb_06',
      name: 'Sonsuz Saat',
      description: 'Zamanı tamamen durdurma gücüne sahip relik.',
      stars: 3,
      imagePath: 'lib/assets/cards/sonsuz_saat.png',
      setName: 'Zaman Bekçisi'
  ),

  // ==========================================
  // SET 5: GİZEMLİ KOLEKSİYONCU (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'gk_01',
      name: 'Monokl',
      description: 'Tek gözle antika detayları inceleme merceği.',
      stars: 1,
      imagePath: 'lib/assets/cards/monokl.png',
      setName: 'Gizemli Koleksiyoncu'
  ),
  CollectionCard(
      id: 'gk_02',
      name: 'Deri Eldiven',
      description: 'Eserlere zarar vermeden dokunmayı sağlayan şık eldiven.',
      stars: 1,
      imagePath: 'lib/assets/cards/deri_eldiven.png',
      setName: 'Gizemli Koleksiyoncu'
  ),
  CollectionCard(
      id: 'gk_03',
      name: 'Silindir Şapka',
      description: 'Koleksiyoncunun asil ve gizemli tarzını tamamlayan şapka.',
      stars: 2,
      imagePath: 'lib/assets/cards/silindir_sapka.png',
      setName: 'Gizemli Koleksiyoncu'
  ),
  CollectionCard(
      id: 'gk_04',
      name: 'Baston',
      description: 'İçinde gizli bir harita bölmesi barındıran şık baston.',
      stars: 2,
      imagePath: 'lib/assets/cards/baston.png',
      setName: 'Gizemli Koleksiyoncu'
  ),
  CollectionCard(
      id: 'gk_05',
      name: 'Gizli Günlük',
      description: 'Nadir bulunan tüm parçaların lokasyon şifreleri.',
      stars: 3,
      imagePath: 'lib/assets/cards/gizli_gunluk.png',
      setName: 'Gizemli Koleksiyoncu'
  ),
  CollectionCard(
      id: 'gk_06',
      name: 'Gizem Kutusu',
      description: 'Açılması için özel bir bulmacanın çözülmesi gereken kutu.',
      stars: 3,
      imagePath: 'lib/assets/cards/gizem_kutusu.png',
      setName: 'Gizemli Koleksiyoncu'
  ),

  // ==========================================
  // SET 6: ESKİ KAŞİF (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'ek_01',
      name: 'Pusula',
      description: 'Kayıp kütüphanelerin yönünü asla şaşırmadan gösterir.',
      stars: 1,
      imagePath: 'lib/assets/cards/pusula.png',
      setName: 'Eski Kaşif'
  ),
  CollectionCard(
      id: 'ek_02',
      name: 'Harita',
      description: 'Üzerinde tehlikeli geçitlerin işaretlendiği eski deri parşömen.',
      stars: 1,
      imagePath: 'lib/assets/cards/harita.png',
      setName: 'Eski Kaşif'
  ),
  CollectionCard(
      id: 'ek_03',
      name: 'Dürbün',
      description: 'Uzak ufuklardaki gizli adaları ve tapınakları yakınlaştırır.',
      stars: 2,
      imagePath: 'lib/assets/cards/durbun.png',
      setName: 'Eski Kaşif'
  ),
  CollectionCard(
      id: 'ek_04',
      name: 'Seyir Defteri',
      description: 'Gidilen tehlikeli yolların gün gün not edildiği defter.',
      stars: 2,
      imagePath: 'lib/assets/cards/seyir_defteri.png',
      setName: 'Eski Kaşif'
  ),
  CollectionCard(
      id: 'ek_05',
      name: 'Kaptan Şapkası',
      description: 'Fırtınalı denizlerde dalgalara meydan okumuş kaşif şapkası.',
      stars: 3,
      imagePath: 'lib/assets/cards/kaptan_sapkasi.png',
      setName: 'Eski Kaşif'
  ),
  CollectionCard(
      id: 'ek_06',
      name: 'Hazine Sandığı',
      description: 'İçi parıldayan kadim madeni paralarla dolu kilitli sandık.',
      stars: 3,
      imagePath: 'lib/assets/cards/hazine_sandigi.png',
      setName: 'Eski Kaşif'
  ),

  // ==========================================
  // SET 7: ÇILGIN SİMYACI (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'cs_01',
      name: 'Deney Tüpü',
      description: 'İçinde yeşil fosforlu sıvıların köpürdüğü cam tüp.',
      stars: 1,
      imagePath: 'lib/assets/cards/deney_tupu.png',
      setName: 'Çlgın Simyacı'
  ),
  CollectionCard(
      id: 'cs_02',
      name: 'Simya Kaşığı',
      description: 'Toz elementleri hassas ölçülerle karıştırma kaşığı.',
      stars: 1,
      imagePath: 'lib/assets/cards/simya_kasigi.png',
      setName: 'Çlgın Simyacı'
  ),
  CollectionCard(
      id: 'cs_03',
      name: 'İksir Şişesi',
      description: 'Gece karanlığında hafifçe parıldayan mistik bir iksir.',
      stars: 2,
      imagePath: 'lib/assets/cards/iksir_sisesi.png',
      setName: 'Çlgın Simyacı'
  ),
  CollectionCard(
      id: 'cs_04',
      name: 'Kristal Parçası',
      description: 'Enerji dalgaları yayan saf bir element kristali.',
      stars: 2,
      imagePath: 'lib/assets/cards/kristal_parcasi.png',
      setName: 'Çlgın Simyacı'
  ),
  CollectionCard(
      id: 'cs_05',
      name: 'Simya Lambası',
      description: 'Normal ateşle değil, büyü enerjisiyle yanan lamba.',
      stars: 3,
      imagePath: 'lib/assets/cards/simya_lambasi.png',
      setName: 'Çlgın Simyacı'
  ),
  CollectionCard(
      id: 'cs_06',
      name: 'Altın İksir',
      description: 'Değersiz metalleri altına dönüştürme formülünün sıvısı.',
      stars: 3,
      imagePath: 'lib/assets/cards/altin_iksir.png',
      setName: 'Çlgın Simyacı'
  ),

  // ==========================================
  // SET 8: USTA SANATÇI (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'us_01',
      name: 'Fırça',
      description: 'Kıldan ucuyla tuvale hayat üfleyen narin fırça.',
      stars: 1,
      imagePath: 'lib/assets/cards/firca.png',
      setName: 'Usta Sanatçı'
  ),
  CollectionCard(
      id: 'us_02',
      name: 'Boya Paleti',
      description: 'Tüm ana ve ara renklerin ahenkle dizildiği ahşap palet.',
      stars: 1,
      imagePath: 'lib/assets/cards/boya_paleti.png',
      setName: 'Usta Sanatçı'
  ),
  CollectionCard(
      id: 'us_03',
      name: 'Şövale',
      description: 'Geleceğin başyapıtlarını üzerinde taşıyan güçlü stand.',
      stars: 2,
      imagePath: 'lib/assets/cards/sovale.png',
      setName: 'Usta Sanatçı'
  ),
  CollectionCard(
      id: 'us_04',
      name: 'Heykel Taslağı',
      description: 'Mermerden yontulmaya başlanmış zarif bir siluet.',
      stars: 2,
      imagePath: 'lib/assets/cards/heykel_taslagi.png',
      setName: 'Usta Sanatçı'
  ),
  CollectionCard(
      id: 'us_05',
      name: 'Altın Çerçeve',
      description: 'Tabloların değerini yüz katına çıkaran işlemeli çerçeve.',
      stars: 3,
      imagePath: 'lib/assets/cards/altin_cerceve.png',
      setName: 'Usta Sanatçı'
  ),
  CollectionCard(
      id: 'us_06',
      name: 'Usta Tablo',
      description: 'Baktıkça insanı içine çeken, kütüphanenin en canlı resmi.',
      stars: 3,
      imagePath: 'lib/assets/cards/usta_tablo.png',
      setName: 'Usta Sanatçı'
  ),

  // ==========================================
  // SET 9: GENÇ MUCİT (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'gm_01',
      name: 'Dişli',
      description: 'Mekanik sistemlerin tıkır tıkır dönmesini sağlayan çark.',
      stars: 1,
      imagePath: 'lib/assets/cards/disli.png',
      setName: 'Genç Mucit'
  ),
  CollectionCard(
      id: 'gm_02',
      name: 'Vida Anahtarı',
      description: 'Gevşeyen vidaları sıkan, mucidin en pratik el aleti.',
      stars: 1,
      imagePath: 'lib/assets/cards/vida_anahtari.png',
      setName: 'Genç Mucit'
  ),
  CollectionCard(
      id: 'gm_03',
      name: 'Bakır Boru',
      description: 'Buhar gücünü ve enerjiyi ileten bükülmüş hatlar.',
      stars: 2,
      imagePath: 'lib/assets/cards/bakir_boru.png',
      setName: 'Genç Mucit'
  ),
  CollectionCard(
      id: 'gm_04',
      name: 'Çizim Defteri',
      description: 'Henüz üretilmemiş robotların ve çılgın icatların şemaları.',
      stars: 2,
      imagePath: 'lib/assets/cards/cizim_defteri.png',
      setName: 'Genç Mucit'
  ),
  CollectionCard(
      id: 'gm_05',
      name: 'Mekanik Kuş',
      description: 'Dişlilerle çalışan ve kütüphane tavanında uçabilen yapay kuş.',
      stars: 3,
      imagePath: 'lib/assets/cards/mekanik_kus.png',
      setName: 'Genç Mucit'
  ),
  CollectionCard(
      id: 'gm_06',
      name: 'Mini Robot',
      description: 'Gözleri parlayan ve küçük tamiratları kendi yapan otonom dost.',
      stars: 3,
      imagePath: 'lib/assets/cards/mini_robot.png',
      setName: 'Genç Mucit'
  ),

  // ==========================================
  // SET 10: KRALİYET HAZİNESİ (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'kh_01',
      name: 'Kraliyet Mührü',
      description: 'Geri alınamaz mutlak kararların mum üzerine basılan nişanı.',
      stars: 1,
      imagePath: 'lib/assets/cards/kraliyet_muhru.png',
      setName: 'Kraliyet Hazinesi'
  ),
  CollectionCard(
      id: 'kh_02',
      name: 'Kristal Kadeh',
      description: 'Sarayı süsleyen, ışığı gökkuşağı renklerine bölen kadeh.',
      stars: 1,
      imagePath: 'lib/assets/cards/kristal_kadeh.png',
      setName: 'Kraliyet Hazinesi'
  ),
  CollectionCard(
      id: 'kh_03',
      name: 'Mücevher Kutusu',
      description: 'İçi yakut ve zümrüt kolyelerle parıldayan kadife kutu.',
      stars: 2,
      imagePath: 'lib/assets/cards/mucevher_kutusu.png',
      setName: 'Kraliyet Hazinesi'
  ),
  CollectionCard(
      id: 'kh_04',
      name: 'Taht Minyatürü',
      description: 'Altından yapılmış, gücü simgeleyen ince işçilikli bir maket.',
      stars: 2,
      imagePath: 'lib/assets/cards/taht_minyaturu.png',
      setName: 'Kraliyet Hazinesi'
  ),
  CollectionCard(
      id: 'kh_05',
      name: 'Altın Asa',
      description: 'Görkemli taşlarla bezeli, hükümdarın kudret simgesi.',
      stars: 3,
      imagePath: 'lib/assets/cards/altin_asa.png',
      setName: 'Kraliyet Hazinesi'
  ),
  CollectionCard(
      id: 'kh_06',
      name: 'Kraliyet Tacı',
      description: 'Saf altından, üzerinde en nadide elmasların parladığı başlık.',
      stars: 3,
      imagePath: 'lib/assets/cards/kraliyet_taci.png',
      setName: 'Kraliyet Hazinesi'
  ),

  // ==========================================
  // SET 11: GİZEMLİ ESERLER (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'ge_01',
      name: 'Kara Anahtar',
      description: 'Hangi kapıyı açtığı bilinmeyen, soğuk metalden anahtar.',
      stars: 1,
      imagePath: 'lib/assets/cards/kara_anahtar.png',
      setName: 'Gizemli Eserler'
  ),
  CollectionCard(
      id: 'ge_02',
      name: 'Mühürlü Parşömen',
      description: 'Büyülü bir bağla kilitlenmiş, açılması tehlikeli rulo.',
      stars: 1,
      imagePath: 'lib/assets/cards/muhurlu_parsemen.png',
      setName: 'Gizemli Eserler'
  ),
  CollectionCard(
      id: 'ge_03',
      name: 'Gizemli Maske',
      description: 'Takana kütüphanedeki gizli geçitleri gösteren antik maske.',
      stars: 2,
      imagePath: 'lib/assets/cards/gizemli_maske.png',
      setName: 'Gizemli Eserler'
  ),
  CollectionCard(
      id: 'ge_04',
      name: 'Kristal Küre',
      description: 'İçinde sürekli sis bulutlarının döndüğü kehanet küresi.',
      stars: 2,
      imagePath: 'lib/assets/cards/kristal_kure.png',
      setName: 'Gizemli Eserler'
  ),
  CollectionCard(
      id: 'ge_05',
      name: 'Kara Kitap',
      description: 'Sayfaları simsiyahtır, sadece ay ışığında gerçek yazılar belirir.',
      stars: 3,
      imagePath: 'lib/assets/cards/kara_kitap.png',
      setName: 'Gizemli Eserler'
  ),
  CollectionCard(
      id: 'ge_06',
      name: 'Antik Relik',
      description: 'Kendi etrafında yavaşça dönen, havada asılı enerji kaynağı.',
      stars: 3,
      imagePath: 'lib/assets/cards/antik_relik.png',
      setName: 'Gizemli Eserler'
  ),

  // ==========================================
  // SET 12: SONSUZ BİLGELİK (6 Kart)
  // ==========================================
  CollectionCard(
      id: 'sb_01',
      name: 'Altın Yaprak',
      description: 'Hayat ağacından düşmüş, kurumayan efsanevi yaprak.',
      stars: 1,
      imagePath: 'lib/assets/cards/altin_yaprak.png',
      setName: 'Sonsuz Bilgelik'
  ),
  CollectionCard(
      id: 'sb_02',
      name: 'Hafıza Kristali',
      description: 'Geçmiş uygarlıkların tüm anılarını içinde depolayan taş.',
      stars: 1,
      imagePath: 'lib/assets/cards/hafiza_kristali.png',
      setName: 'Sonsuz Bilgelik'
  ),
  CollectionCard(
      id: 'sb_03',
      name: 'Bilgi Çekirdeği',
      description: 'Zihne yerleştirildiğinde dilleri anında çözebilen parça.',
      stars: 2,
      imagePath: 'lib/assets/cards/bilgi_cekirdegi.png',
      setName: 'Sonsuz Bilgelik'
  ),
  CollectionCard(
      id: 'sb_04',
      name: 'Bilgelik Küresi',
      description: 'Evrenin tüm matematiksel düzenini içinde saklayan küre.',
      stars: 2,
      imagePath: 'lib/assets/cards/bilgelik_kuresi.png',
      setName: 'Sonsuz Bilgelik'
  ),
  CollectionCard(
      id: 'sb_05',
      name: 'Kozmik Harita',
      description: 'Yıldızların ve boyutlar arası geçiş kapılarının canlı haritası.',
      stars: 3,
      imagePath: 'lib/assets/cards/kozmik_harita.png',
      setName: 'Sonsuz Bilgelik'
  ),
  CollectionCard(
      id: 'sb_06',
      name: 'Sonsuz Kitap',
      description: 'Sayfaları hiç bitmeyen, okudukça derinleşen nihai kaynak.',
      stars: 3,
      imagePath: 'lib/assets/cards/sonsuz_kitap.png',
      setName: 'Sonsuz Bilgelik'
  ),
];