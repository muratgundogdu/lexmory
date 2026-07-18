import '../features/library/models/collection_card.dart';
import '../features/library/models/card_rarity.dart';

final List<CollectionCard> collectionPool = [
  // SET 1: Bilge Amca (set_01)
  const CollectionCard(id: 'ba_01', name: 'Bilge Şapkası', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/bilge_amca/bilge_sapkasi.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 1),
  const CollectionCard(id: 'ba_02', name: 'Bilge Bastonu', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/bilge_amca/bilge_bastonu.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 1),
  const CollectionCard(id: 'ba_03', name: 'Bilge Gözlüğü', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/bilge_amca/bilge_gozlugu.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 1),
  const CollectionCard(id: 'ba_04', name: 'Bilge Parşömeni', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/bilge_amca/bilge_parsemeni.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 2),
  const CollectionCard(id: 'ba_05', name: 'Bilge Tüy Kalemi', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/bilge_amca/bilge_tuy_kalemi.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 2),
  const CollectionCard(id: 'ba_06', name: 'Bilgelik Kitabı', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/bilge_amca/bilgelik_kitabi.webp', collectionId: 'set_01', setName: 'Bilge Amca', stars: 3),

  // SET 2: Kütüphane Kedisi (set_02)
  const CollectionCard(id: 'kk_01', name: 'Mama Kabı', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kutuphane_kedisi/mama_kabi.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 1),
  const CollectionCard(id: 'kk_02', name: 'Yün Yumak', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kutuphane_kedisi/yun_yumak.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 1),
  const CollectionCard(id: 'kk_03', name: 'Oyuncak Fare', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kutuphane_kedisi/oyuncak_fare.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 1),
  const CollectionCard(id: 'kk_04', name: 'Kedi Yastığı', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/kutuphane_kedisi/kedi_yastigi.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 2),
  const CollectionCard(id: 'kk_05', name: 'Çanlı Tasma', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/kutuphane_kedisi/canli_tasma.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 2),
  const CollectionCard(id: 'kk_06', name: 'Altın Tasma', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/kutuphane_kedisi/altin_tasma.webp', collectionId: 'set_02', setName: 'Kütüphane Kedisi', stars: 3),

  // SET 3: Akademi Baykuşu (set_03)
  const CollectionCard(id: 'ab_01', name: 'Baykuş Tüyü', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/akademi_baykusu/baykus_tuyu.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 1),
  const CollectionCard(id: 'ab_02', name: 'Mektup Tomarı', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/akademi_baykusu/mektup_tomari.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 1),
  const CollectionCard(id: 'ab_03', name: 'Gece Lambası', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/akademi_baykusu/gece_lambasi.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 1),
  const CollectionCard(id: 'ab_04', name: 'Gümüş Pençe', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/akademi_baykusu/gumus_pence.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 2),
  const CollectionCard(id: 'ab_05', name: 'Akademi Rozeti', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/akademi_baykusu/akademi_rozeti.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 2),
  const CollectionCard(id: 'ab_06', name: 'Bilgelik Madalyası', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/akademi_baykusu/bilgelik_madalyasi.webp', collectionId: 'set_03', setName: 'Akademi Baykuşu', stars: 3),

  // SET 4: Zaman Bekçisi (set_04)
  const CollectionCard(id: 'zb_01', name: 'Saat Anahtarı', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/zaman_bekcisi/saat_anahtari.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 1),
  const CollectionCard(id: 'zb_02', name: 'Saat Zinciri', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/zaman_bekcisi/saat_zinciri.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 1),
  const CollectionCard(id: 'zb_03', name: 'Bronz Saat', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/zaman_bekcisi/bronz_saat.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 1),
  const CollectionCard(id: 'zb_04', name: 'Cep Saati', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/zaman_bekcisi/cep_saati.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 2),
  const CollectionCard(id: 'zb_05', name: 'Kum Saati', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/zaman_bekcisi/kum_saati.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 2),
  const CollectionCard(id: 'zb_06', name: 'Sonsuz Saat', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/zaman_bekcisi/sonsuz_saat.webp', collectionId: 'set_04', setName: 'Zaman Bekçisi', stars: 3),

  // SET 5: Gizemli Koleksiyoncu (set_05)
  const CollectionCard(id: 'gk_01', name: 'Monokl', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/monokl.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 1),
  const CollectionCard(id: 'gk_02', name: 'Deri Eldiven', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/deri_eldiven.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 1),
  const CollectionCard(id: 'gk_03', name: 'Silindir Şapka', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/silindir_sapka.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 1),
  const CollectionCard(id: 'gk_04', name: 'Baston', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/baston.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 2),
  const CollectionCard(id: 'gk_05', name: 'Gizli Günlük', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/gizli_gunluk.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 2),
  const CollectionCard(id: 'gk_06', name: 'Gizem Kutusu', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/gizemli_koleksiyoncu/gizem_kutusu.webp', collectionId: 'set_05', setName: 'Gizemli Koleksiyoncu', stars: 3),

  // SET 6: Eski Kaşif (set_06)
  const CollectionCard(id: 'ek_01', name: 'Pusula', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/eski_kasif/pusula.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 1),
  const CollectionCard(id: 'ek_02', name: 'Harita', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/eski_kasif/harita.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 1),
  const CollectionCard(id: 'ek_03', name: 'Dürbün', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/eski_kasif/durbun.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 1),
  const CollectionCard(id: 'ek_04', name: 'Seyir Defteri', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/eski_kasif/seyir_defteri.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 2),
  const CollectionCard(id: 'ek_05', name: 'Kaptan Şapkası', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/eski_kasif/kaptan_sapkasi.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 2),
  const CollectionCard(id: 'ek_06', name: 'Hazine Sandığı', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/eski_kasif/hazine_sandigi.webp', collectionId: 'set_06', setName: 'Eski Kaşif', stars: 3),

  // SET 7: Çılgın Simyacı (set_07)
  const CollectionCard(id: 'cs_01', name: 'Deney Tüpü', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/cilgin_simyaci/deney_tupu.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 1),
  const CollectionCard(id: 'cs_02', name: 'Simya Kaşığı', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/cilgin_simyaci/simya_kasigi.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 1),
  const CollectionCard(id: 'cs_03', name: 'İksir Şişesi', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/cilgin_simyaci/iksir_sisesi.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 1),
  const CollectionCard(id: 'cs_04', name: 'Kristal Parçası', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/cilgin_simyaci/kristal_parcasi.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 2),
  const CollectionCard(id: 'cs_05', name: 'Simya Lambası', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/cilgin_simyaci/simya_lambasi.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 2),
  const CollectionCard(id: 'cs_06', name: 'Altın İksir', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/cilgin_simyaci/altin_iksir.webp', collectionId: 'set_07', setName: 'Çılgın Simyacı', stars: 3),

  // SET 8: Usta Sanatçı (set_08)
  const CollectionCard(id: 'us_01', name: 'Fırça', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/usta_sanatci/firca.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 1),
  const CollectionCard(id: 'us_02', name: 'Boya Paleti', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/usta_sanatci/boya_paleti.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 1),
  const CollectionCard(id: 'us_03', name: 'Şövale', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/usta_sanatci/sovale.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 1),
  const CollectionCard(id: 'us_04', name: 'Heykel Taslağı', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/usta_sanatci/heykel_taslagi.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 2),
  const CollectionCard(id: 'us_05', name: 'Altın Çerçeve', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/usta_sanatci/altin_cerceve.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 2),
  const CollectionCard(id: 'us_06', name: 'Usta Tablo', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/usta_sanatci/usta_tablo.webp', collectionId: 'set_08', setName: 'Usta Sanatçı', stars: 3),

  // SET 9: Genç Mucit (set_09)
  const CollectionCard(id: 'gm_01', name: 'Dişli', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/genc_mucit/disli.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 1),
  const CollectionCard(id: 'gm_02', name: 'Vida Anahtarı', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/genc_mucit/vida_anahtari.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 1),
  const CollectionCard(id: 'gm_03', name: 'Bakır Boru', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/genc_mucit/bakir_boru.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 1),
  const CollectionCard(id: 'gm_04', name: 'Çizim Defteri', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/genc_mucit/cizim_defteri.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 2),
  const CollectionCard(id: 'gm_05', name: 'Mekanik Kuş', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/genc_mucit/mekanik_kus.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 2),
  const CollectionCard(id: 'gm_06', name: 'Mini Robot', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/genc_mucit/mini_robot.webp', collectionId: 'set_09', setName: 'Genç Mucit', stars: 3),

  // SET 10: Kraliyet Hazinesi (set_10)
  const CollectionCard(id: 'kh_01', name: 'Kraliyet Mührü', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kraliyet_hazinesi/kraliyet_muhru.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 1),
  const CollectionCard(id: 'kh_02', name: 'Kristal Kadeh', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kraliyet_hazinesi/kristal_kadeh.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 1),
  const CollectionCard(id: 'kh_03', name: 'Mücevher Kutusu', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/kraliyet_hazinesi/mucevher_kutusu.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 1),
  const CollectionCard(id: 'kh_04', name: 'Taht Minyatürü', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/kraliyet_hazinesi/taht_minyaturu.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 2),
  const CollectionCard(id: 'kh_05', name: 'Altın Asa', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/kraliyet_hazinesi/altin_asa.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 2),
  const CollectionCard(id: 'kh_06', name: 'Kraliyet Tacı', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/kraliyet_hazinesi/kraliyet_taci.webp', collectionId: 'set_10', setName: 'Kraliyet Hazinesi', stars: 3),

  // SET 11: Gizemli Eserler (set_11)
  const CollectionCard(id: 'ge_01', name: 'Kara Anahtar', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_eserler/kara_anahtar.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 1),
  const CollectionCard(id: 'ge_02', name: 'Mühürlü Parşömen', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_eserler/muhurlu_parsemen.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 1),
  const CollectionCard(id: 'ge_03', name: 'Gizemli Maske', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/gizemli_eserler/gizemli_maske.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 1),
  const CollectionCard(id: 'ge_04', name: 'Kristal Küre', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/gizemli_eserler/kristal_kure.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 2),
  const CollectionCard(id: 'ge_05', name: 'Kara Kitap', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/gizemli_eserler/kara_kitap.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 2),
  const CollectionCard(id: 'ge_06', name: 'Antik Relik', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/gizemli_eserler/antik_relik.webp', collectionId: 'set_11', setName: 'Gizemli Eserler', stars: 3),

  // SET 12: Sonsuz Bilgelik (set_12)
  const CollectionCard(id: 'sb_01', name: 'Altın Yaprak', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/sonsuz_bilgelik/altin_yaprak.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 1),
  const CollectionCard(id: 'sb_02', name: 'Hafıza Kristali', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/sonsuz_bilgelik/hafiza_kristali.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 1),
  const CollectionCard(id: 'sb_03', name: 'Bilgi Çekirdeği', description: '...', rarity: CardRarity.common, imagePath: 'lib/assets/cards/sonsuz_bilgelik/bilgi_cekirdegi.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 1),
  const CollectionCard(id: 'sb_04', name: 'Bilgelik Küresi', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/sonsuz_bilgelik/bilgelik_kuresi.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 2),
  const CollectionCard(id: 'sb_05', name: 'Kozmik Harita', description: '...', rarity: CardRarity.rare, imagePath: 'lib/assets/cards/sonsuz_bilgelik/kozmik_harita.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 2),
  const CollectionCard(id: 'sb_06', name: 'Sonsuz Kitap', description: '...', rarity: CardRarity.legendary, imagePath: 'lib/assets/cards/sonsuz_bilgelik/sonsuz_kitap.webp', collectionId: 'set_12', setName: 'Sonsuz Bilgelik', stars: 3),
];
