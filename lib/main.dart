import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i yapılandırın:
  // 1. firebase_options.dart dosyasını oluşturun (flutterfire configure komutuyla)
  // 2. Aşağıdaki satırı firebase_options.dart ile değiştirin:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  runApp(DepoUygulamasi());
}

// Sabit stil sınıfı
class AppStyle {
  static const Color primaryColor = Colors.white;
  static const Color accentColor = Colors.greenAccent;
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3E50),
      Color(0xFF3498DB),
    ],
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 15,
        spreadRadius: 5,
        offset: Offset(0, 5),
      ),
    ],
  );

  static final glassMorphism = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.1),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
    ),
  );
}

// Cam efekti container'ı
class GlassMorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;

  const GlassMorphicContainer({
    Key? key,
    required this.child,
    this.blur = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: AppStyle.glassMorphism,
          child: child,
        ),
      ),
    );
  }
}

// Ürün modeli
class Urun {
  final String id;
  final String ad;
  final int miktar;
  final String konum;
  final DateTime eklemeTarihi;

  Urun({
    required this.id,
    required this.ad,
    required this.miktar,
    required this.konum,
    required this.eklemeTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad.toLowerCase(),
      'miktar': miktar,
      'konum': konum,
      'eklemeTarihi': eklemeTarihi.toIso8601String(),
    };
  }

  factory Urun.fromMap(Map<String, dynamic> map) {
    return Urun(
      id: map['id'],
      ad: map['ad'],
      miktar: map['miktar'],
      konum: map['konum'],
      eklemeTarihi: DateTime.parse(map['eklemeTarihi']),
    );
  }
}

// Depo Model sınıfı
class DepoModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Urun> _urunler = [];
  List<Urun> _filtrelenmisUrunler = [];

  List<Urun> get urunler => _urunler;
  List<Urun> get filtrelenmisUrunler => _filtrelenmisUrunler;

  Future<void> urunleriGetir() async {
    try {
      final snapshot = await _firestore.collection('urunler').get();
      _urunler = snapshot.docs.map((doc) => Urun.fromMap(doc.data())).toList();
      _filtrelenmisUrunler = List.from(_urunler);
      notifyListeners();
    } catch (e) {
      print('Veri getirme hatası: $e');
    }
  }

  void urunleriFiltrele(String aramaMetni) {
    if (aramaMetni.isEmpty) {
      _filtrelenmisUrunler = List.from(_urunler);
    } else {
      _filtrelenmisUrunler = _urunler
          .where((urun) =>
              urun.ad.toLowerCase().contains(aramaMetni.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> urunEkle(String ad, int miktar, String konum) async {
    try {
      final String id = _firestore.collection('urunler').doc().id;
      final yeniUrun = Urun(
        id: id,
        ad: ad,
        miktar: miktar,
        konum: konum,
        eklemeTarihi: DateTime.now(),
      );

      await _firestore.collection('urunler').doc(id).set(yeniUrun.toMap());
      _urunler.add(yeniUrun);
      _filtrelenmisUrunler = List.from(_urunler);
      notifyListeners();
    } catch (e) {
      print('Ekleme hatası: $e');
      throw e;
    }
  }

  Future<void> urunSil(String id) async {
    try {
      await _firestore.collection('urunler').doc(id).delete();
      _urunler.removeWhere((urun) => urun.id == id);
      _filtrelenmisUrunler = List.from(_urunler);
      notifyListeners();
    } catch (e) {
      print('Silme hatası: $e');
      throw e;
    }
  }

  Future<void> urunGuncelle(
      String id, String ad, int miktar, String konum) async {
    try {
      final guncelUrun = Urun(
        id: id,
        ad: ad,
        miktar: miktar,
        konum: konum,
        eklemeTarihi: DateTime.now(),
      );

      await _firestore.collection('urunler').doc(id).update(guncelUrun.toMap());

      final index = _urunler.indexWhere((urun) => urun.id == id);
      if (index != -1) {
        _urunler[index] = guncelUrun;
        _filtrelenmisUrunler = List.from(_urunler);
        notifyListeners();
      }
    } catch (e) {
      print('Güncelleme hatası: $e');
      throw e;
    }
  }
}

// Ana uygulama widget'ı
class DepoUygulamasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DepoModel()..urunleriGetir(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppStyle.primaryColor,
          scaffoldBackgroundColor: AppStyle.backgroundColor,
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white70,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: DepoAnasayfa(),
      ),
    );
  }
}

// Ana sayfa
class DepoAnasayfa extends StatefulWidget {
  @override
  _DepoAnasayfaState createState() => _DepoAnasayfaState();
}

class _DepoAnasayfaState extends State<DepoAnasayfa>
    with SingleTickerProviderStateMixin {
  final TextEditingController _aramaController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Depo Yönetimi'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(1),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/beyaz.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(height: kToolbarHeight + 60),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GlassMorphicContainer(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _aramaController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ürün Ara',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            Provider.of<DepoModel>(context, listen: false)
                                .urunleriFiltrele(value);
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Consumer<DepoModel>(
                      builder: (context, depoModel, child) {
                        final urunler = depoModel.filtrelenmisUrunler;

                        if (urunler.isEmpty) {
                          return Center(
                            child: Text(
                              'Ürün bulunamadı',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: urunler.length,
                          itemBuilder: (context, index) {
                            final urun = urunler[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: GlassMorphicContainer(
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  title: Text(
                                    urun.ad,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.inventory,
                                        'Miktar: ${urun.miktar}',
                                      ),
                                      SizedBox(height: 4),
                                      _buildInfoRow(
                                        Icons.location_on,
                                        'Konum: ${urun.konum}',
                                      ),
                                      SizedBox(height: 4),
                                      _buildInfoRow(
                                        Icons.calendar_today,
                                        'Eklenme: ${urun.eklemeTarihi.toString().split('.')[0]}',
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    icon: Icon(Icons.more_vert,
                                        color: Colors.white),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Düzenle'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.red),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sil',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _urunGuncelle(urun);
                                      } else if (value == 'delete') {
                                        _urunSil(urun);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UrunEkleSayfasi()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: AppStyle.accentColor,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Future<void> _urunSil(Urun urun) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürün Silme'),
        content: Text('${urun.ad} ürününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await Provider.of<DepoModel>(context, listen: false).urunSil(urun.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün silinirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _urunGuncelle(Urun urun) async {
    final TextEditingController adController =
        TextEditingController(text: urun.ad);
    final TextEditingController miktarController =
        TextEditingController(text: urun.miktar.toString());
    final TextEditingController konumController =
        TextEditingController(text: urun.konum);

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürün Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              decoration: InputDecoration(labelText: 'Ürün Adı'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: miktarController,
              decoration: InputDecoration(labelText: 'Miktar'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: konumController,
              decoration: InputDecoration(labelText: 'Konum'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Güncelle'),
          ),
        ],
      ),
    );

    if (sonuc == true) {
      try {
        await Provider.of<DepoModel>(context, listen: false).urunGuncelle(
          urun.id,
          adController.text,
          int.parse(miktarController.text),
          konumController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla güncellendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün güncellenirken hata oluştu')),
        );
      }
    }
  }
}

// Ürün Ekleme Sayfası
class UrunEkleSayfasi extends StatefulWidget {
  @override
  _UrunEkleSayfasiState createState() => _UrunEkleSayfasiState();
}

class _UrunEkleSayfasiState extends State<UrunEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Yeni Ürün Ekle'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/beyaz.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 50, 16, 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassMorphicContainer(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _adController,
                              label: 'Ürün Adı',
                              icon: Icons.inventory,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen ürün adı girin';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _miktarController,
                              label: 'Miktar',
                              icon: Icons.numbers,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen miktar girin';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) <= 0) {
                                  return 'Geçerli bir miktar girin';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _konumController,
                              label: 'Konum',
                              icon: Icons.location_on,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen konum girin';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  await Provider.of<DepoModel>(
                                    context,
                                    listen: false,
                                  ).urunEkle(
                                    _adController.text,
                                    int.parse(_miktarController.text),
                                    _konumController.text,
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Ürün eklenirken hata oluştu'),
                                    ),
                                  );
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Ürün Ekle',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _adController.dispose();
    _miktarController.dispose();
    _konumController.dispose();
    super.dispose();
  }
}
