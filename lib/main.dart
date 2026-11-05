import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const String _repairLogo = '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';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final path = p.join(await getDatabasesPath(), 'cover_inventory.db');
  final db = await openDatabase(path, version: 1, onCreate: (db, _) async {
    await db.execute('''CREATE TABLE stock(id INTEGER PRIMARY KEY AUTOINCREMENT, phone_id TEXT NOT NULL UNIQUE, brand TEXT NOT NULL, model TEXT NOT NULL, image_path TEXT, image_url TEXT, quantity INTEGER NOT NULL DEFAULT 0, description TEXT NOT NULL DEFAULT '')''');
  });
  runApp(CoverApp(db: db));
}

class Phone {
  final String id, brand, model;
  final String? image;
  final String searchText;
  final Set<String> searchTokens;
  Phone(this.id, this.brand, this.model, this.image)
      : searchText = '$brand $model'.toLowerCase(),
        searchTokens = '$brand $model'.toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
            .split(RegExp(r'\s+'))
            .where((token) => token.isNotEmpty).toSet();
  factory Phone.fromJson(Map<String, dynamic> j) {
    String read(dynamic value) {
      if (value is Map) return (value['name'] ?? value['slug'] ?? value['title'] ?? '').toString().trim();
      return value?.toString().trim() ?? '';
    }
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = read(j[key]);
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final id = pick(['slug','id','key','model_id']);
    final rawBrand = pick(['brand','manufacturer','maker','vendor']);
    final rawModel = pick(['name','marketing_name','model_name','model','device','title']);
    final source = '$rawBrand $rawModel $id'.replaceAll('_',' ').replaceAll('-',' ').toLowerCase();

    const brandPatterns = <String, String>{
      'samsung':'Samsung','galaxy':'Samsung','sm ':'Samsung','apple':'Apple','iphone':'Apple',
      'oppo':'OPPO','cph':'OPPO','vivo':'vivo','iqoo':'iQOO','infinix':'Infinix',
      'tecno':'TECNO','realme':'Realme','rmx':'Realme','xiaomi':'Xiaomi','redmi':'Xiaomi',
      'poco':'POCO','oneplus':'OnePlus','huawei':'Huawei','honor':'Honor','google':'Google',
      'pixel':'Google','nothing':'Nothing','motorola':'Motorola','moto':'Motorola','nokia':'Nokia',
      'sony':'Sony','asus':'ASUS','lenovo':'Lenovo','zte':'ZTE','nubia':'Nubia',
      'itel':'itel','tcl':'TCL','blackview':'Blackview','doogee':'DOOGEE','ulefone':'Ulefone'
    };
    var brand = '';
    final b = rawBrand.toLowerCase().trim();
    if (b.isNotEmpty && b != 'other' && !b.startsWith('other ')) {
      for (final entry in brandPatterns.entries) {
        if (b == entry.key || b.startsWith(entry.key) || b.contains(entry.key)) {
          brand = entry.value;
          break;
        }
      }
      if (brand.isEmpty) brand = rawBrand.trim();
    }
    if (brand.isEmpty) {
      for (final entry in brandPatterns.entries) {
        if (RegExp(r'(^|[^a-z0-9])' + RegExp.escape(entry.key) + r'([^a-z0-9]|$)', caseSensitive:false).hasMatch(source)) {
          brand = entry.value;
          break;
        }
      }
    }
    if (brand.isEmpty) brand = 'Other';

    var model = rawModel;
    model = model.replaceFirst(RegExp(r'^other\s+',caseSensitive:false),'');
    model = model.replaceFirst(RegExp(r'^(?:' + RegExp.escape(rawBrand) + r')\s+',caseSensitive:false),'');
    model = model.replaceAll(RegExp(r'\b(?:SM|CPH|RMX)\s*[-_]?[A-Z0-9]{3,}\b',caseSensitive:false),' ');
    model = model.replaceAll(RegExp(r'\b(?:19|20)\d{2}\b.*$'),' ');
    model = model.replaceAll(RegExp(r'\b(?:premium edition|standard edition|dual sim|td-lte|fdd-lte|lte|5g nr|128gb|256gb|512gb|64gb|32gb|cn|hk|tw|us|in|id|my|pk|v1)\b.*$',caseSensitive:false),' ');
    model = model.replaceAll(RegExp(r'\([^)]*\)'),' ');
    model = model.replaceAll(RegExp(r'\s+'),' ').trim();

    RegExpMatch? match;
    if (brand == 'Samsung') {
      match = RegExp(r'(Galaxy\s+(?:[ASMFZ]\s*)?\d{1,3}[A-Za-z]?(?:\s+(?:5G|4G|FE|Ultra|Plus|Pro|Edge|Note|Fold|Flip))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Apple') {
      match = RegExp(r'(iPhone\s+(?:SE(?:\s*\d{0,2})?|\d{1,2}[A-Za-z]?(?:\s+(?:Pro|Max|Plus|mini))?(?:\s+(?:Pro|Max))?))',caseSensitive:false).firstMatch(model);
    } else if (brand == 'OPPO') {
      match = RegExp(r'\b(A\d{1,3}[A-Za-z]?(?:\s+(?:Pro|Plus|s))?|Reno\s*\d{0,2}[A-Za-z]?(?:\s+(?:Pro|Plus|Z))?|Find\s+[A-Za-z0-9 ]+?)\b',caseSensitive:false).firstMatch(model);
    } else if (brand == 'vivo' || brand == 'iQOO') {
      match = RegExp(r'\b([YVXZT]\s*\d{1,3}[A-Za-z]?(?:\s+(?:Pro|Plus|Lite|e|T))?)\b',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Xiaomi' || brand == 'POCO') {
      match = RegExp(r'\b((?:Redmi\s+)?(?:Note\s+)?(?:\d{1,2}[A-Za-z]?(?:\s+(?:Pro|Plus|Ultra|Max|5G|4G))*)|POCO\s+[A-Za-z0-9 ]+)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Infinix') {
      match = RegExp(r'\b((?:Hot|Note|Zero|Smart|GT)\s+[A-Za-z0-9]+(?:\s+(?:Pro|Plus|Ultra|5G|4G|X))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'TECNO') {
      match = RegExp(r'\b((?:Spark|Camon|Pova|Phantom|Pop)\s+[A-Za-z0-9]+(?:\s+(?:Pro|Plus|Premier|Ultra|5G|4G))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Realme') {
      match = RegExp(r'\b((?:C|GT|Narzo|Number)\s*\d{1,3}[A-Za-z]?(?:\s+(?:Pro|Plus|Ultra|5G|4G|Master))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'OnePlus') {
      match = RegExp(r'\b((?:Nord\s+)?(?:CE\s*)?\d{1,2}[A-Za-z]?(?:\s+(?:R|Pro|Plus|Lite))?)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Google') {
      match = RegExp(r'\b(Pixel\s+\d+[A-Za-z]?(?:\s+(?:Pro|XL|a|Fold))?)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Honor') {
      match = RegExp(r'\b((?:Magic|X|Play|90|200)\s*[A-Za-z0-9]+(?:\s+(?:Pro|Plus|Lite|Ultra))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Huawei') {
      match = RegExp(r'\b((?:Pura|Mate|Nova|P)\s*\d+[A-Za-z]?(?:\s+(?:Pro|Plus|Ultra|Lite))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Motorola') {
      match = RegExp(r'\b((?:Moto\s+)?(?:G|E|Edge|Razr)\s*\d{1,3}[A-Za-z]?(?:\s+(?:Power|Play|Plus|Ultra|Pro))*)',caseSensitive:false).firstMatch(model);
    } else if (brand == 'Nothing') {
      match = RegExp(r'\b(Phone\s*\(?\d+[A-Za-z]?\)?)',caseSensitive:false).firstMatch(model);
    }
    if (match != null) model = match.group(1)!.trim();
    if (brand == 'Samsung') model = model.replaceFirst(RegExp(r'^Galaxy\s+',caseSensitive:false),'').trim();
    model = model.replaceAll(RegExp(r'\s+'),' ').trim();
    if (model.isEmpty) model = 'Unknown model';

    final image = pick(['image_url','imageUrl','image','photo','thumbnail','picture']);
    return Phone(id.isEmpty ? '${brand}_${model}' : id, brand, model, image.isEmpty ? null : image);
  }
}

List<Phone> _decodePhoneCatalogue(String source) {
  final decoded = jsonDecode(source);
  dynamic rows = decoded;
  if (decoded is Map) rows = decoded['results'] ?? decoded['data'] ?? decoded['phones'] ?? decoded['items'];
  if (rows is! List) throw const FormatException('Bundled catalogue has an unknown format');
  return rows.whereType<Map>().map((e) => Phone.fromJson(Map<String, dynamic>.from(e)))
      .where((phone) => phone.model != 'Unknown model').toList(growable: false);
}
Future<List<Phone>> _loadPhoneCatalogue() async {
  final source = await rootBundle.loadString('assets/phones.json');
  return compute(_decodePhoneCatalogue, source);
}

class CoverApp extends StatelessWidget {
  final Database db;
  const CoverApp({super.key, required this.db});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Repair X Zone Cover Management', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F6B)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F7F7)),
    home: HomePage(db: db),
  );
}

class HomePage extends StatefulWidget {
  final Database db;
  const HomePage({super.key, required this.db});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static Future<List<Phone>>? _catalogueFuture;
  final search = TextEditingController();
  List<Phone> matches = [];
  List<Map<String, Object?>> stock = [];
  bool busy = false, searched = false;
  String? error;
  int tab = 0;

  @override
  void initState() { super.initState(); loadStock(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> loadStock() async {
    final rows = await widget.db.query('stock', orderBy: 'brand COLLATE NOCASE, model COLLATE NOCASE');
    if (mounted) setState(() => stock = rows);
  }

  Future<void> findPhones() async {
    if (search.text.trim().isEmpty) return;
    setState(() { busy = true; searched = true; error = null; });
    try {
      // Decode once off the UI thread, then reuse the normalized catalogue for later searches.
      final all = await (_catalogueFuture ??= _loadPhoneCatalogue());
      final q = search.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
      final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final ranked = <({Phone phone, int score})>[];
      final seen = <String>{};
      for (final phone in all) {
        final display = phone.searchText;
        if (!terms.every(phone.searchTokens.contains)) continue;
        final identity = '${phone.brand.toLowerCase()}|${phone.model.toLowerCase()}';
        if (!seen.add(identity)) continue;
        var score = display == q ? 1000 : display.startsWith(q) ? 500 : 100;
        if (phone.model.toLowerCase().startsWith(q)) score += 200;
        ranked.add((phone: phone, score: score));
      }
      ranked.sort((a,b) { final byScore=b.score.compareTo(a.score); if(byScore!=0) return byScore; final byBrand=a.phone.brand.toLowerCase().compareTo(b.phone.brand.toLowerCase()); return byBrand!=0 ? byBrand : a.phone.model.toLowerCase().compareTo(b.phone.model.toLowerCase()); });
      if (mounted) setState(() => matches = ranked.take(24).map((e) => e.phone).toList());
    } catch (e) {
      _catalogueFuture = null;
      if (mounted) setState(() { matches = []; error = 'Could not load the phone catalogue. ($e)'; });
    } finally { if (mounted) setState(() => busy = false); }
  }

  Map<String,Object?>? saved(Phone phone) {
    for (final row in stock) { if (row['phone_id'] == phone.id) return row; }
    return null;
  }

  Future<String?> commonsImage(String query) async {
    try {
      final uri = Uri.https('commons.wikimedia.org','/w/api.php',{
        'action':'query','generator':'search','gsrsearch':query,'gsrnamespace':'6',
        'gsrlimit':'5','prop':'imageinfo','iiprop':'url','iiurlwidth':'360','format':'json'
      });
      final r = await http.get(uri,headers:{'User-Agent':'MobileCoverManager/1.0'}).timeout(const Duration(seconds:15));
      if (r.statusCode != 200) return null;
      final pages = (jsonDecode(r.body)['query']?['pages'] as Map?)?.values;
      if (pages == null) return null;
      for (final page in pages) {
        final info = (page['imageinfo'] as List?)?.first;
        final url = info?['thumburl'] ?? info?['url'];
        if (url is String && url.startsWith('https://')) return url;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> cacheImage(Phone phone) async {
    return _PhoneThumbState.loadOfficialPhoto(phone.brand, phone.model);
  }

  Future<void> edit(Phone phone, {Map<String,Object?>? old}) async {
    final qty = TextEditingController(text: '${old?['quantity'] ?? 0}');
    final desc = TextEditingController(text: '${old?['description'] ?? ''}');
    var saving = false;
    await showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(sheet) =>
      StatefulBuilder(builder:(context,setSheet) => Padding(
        padding:EdgeInsets.fromLTRB(20,12,20,MediaQuery.of(context).viewInsets.bottom+24),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(old == null ? 'Add cover stock' : 'Edit cover stock',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:6),Text('${phone.brand} ${phone.model}'),
          const SizedBox(height:16),
          TextField(controller:qty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Number of covers available',border:OutlineInputBorder(),prefixIcon:Icon(Icons.inventory_2_outlined))),
          const SizedBox(height:12),
          TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'Description (optional)',hintText:'Transparent, black, silicone, premium...',border:OutlineInputBorder())),
          const SizedBox(height:16),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:saving ? null : () async {
              final count = int.tryParse(qty.text.trim());
              if (count == null || count < 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid quantity (0 or more).'))); return; }
              setSheet(() => saving = true);
              final oldPath = old?['image_path'] as String?;
              final imagePath = oldPath != null && oldPath.contains('official_phone_photos')
                  ? oldPath : await cacheImage(phone);
              await widget.db.insert('stock',{
                'phone_id':phone.id,'brand':phone.brand,'model':phone.model,
                'image_path':imagePath,'image_url':phone.image,
                'quantity':count,'description':desc.text.trim()
              },conflictAlgorithm:ConflictAlgorithm.replace);
              if (sheet.mounted) Navigator.pop(sheet);
              await loadStock();
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content:Text('Saved on this device.')));
            },
            icon:const Icon(Icons.save_outlined),label:Text(saving ? 'Saving...' : 'Save phone')
          ))
        ])
      ))
    );
    qty.dispose(); desc.dispose();
  }

  Future<void> remove(Map<String,Object?> row) async {
    final yes = await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Delete saved phone?'),
      content:Text('Remove ${row['brand']} ${row['model']} from stock?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]
    ));
    if (yes == true) { await widget.db.delete('stock',where:'id = ?',whereArgs:[row['id']]); await loadStock(); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:Row(children:[
      ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.memory(base64Decode(_repairLogo),width:48,height:52,fit:BoxFit.contain)),
      const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        const Text('REPAIR X ZONE',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
        Text(tab == 0 ? 'COVER MANAGEMENT' : 'YOUR COVER INVENTORY',style:const TextStyle(fontSize:10,color:Colors.black54,fontWeight:FontWeight.w600))
      ]))
    ])),
    body:SafeArea(child:tab == 0 ? searchView() : inventoryView()),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.search),label:'Find phone'),
      NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'My stock')
    ])
  );

  Widget searchView() => ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xFF087F6B),Color(0xFF145D70)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Find a phone model',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:22)),
      SizedBox(height:5),Text('Search the phone catalogue, then save your cover quantity.',style:TextStyle(color:Colors.white70))
    ])),
    const SizedBox(height:14),
    Row(children:[
      Expanded(child:TextField(controller:search,textInputAction:TextInputAction.search,onSubmitted:(_)=>findPhones(),decoration:InputDecoration(hintText:'Samsung A15, iPhone 15 Pro...',prefixIcon:const Icon(Icons.search),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide.none)))),
      const SizedBox(width:8),
      SizedBox(height:56,child:FilledButton(onPressed:busy ? null : findPhones,child:busy ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.arrow_forward)))
    ]),
    const SizedBox(height:4),const Text('Search works offline · Official rear photos save to this device',style:TextStyle(fontSize:12,color:Colors.black54)),
    if(error != null) Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
    if(!searched) ...[
      const SizedBox(height:20),const Text('Popular brands',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      const SizedBox(height:8),
      Wrap(spacing:7,runSpacing:7,children:['Samsung','Apple','Infinix','OPPO','vivo','Xiaomi','OnePlus','Huawei','Google Pixel','Nothing','TECNO','Realme','Motorola','Honor'].map((b)=>ActionChip(label:Text(b),onPressed:(){search.text=b;findPhones();})).toList()),
      const SizedBox(height:20),const Text('• Search the offline phone catalogue\n• Official back-panel photos are saved on this device\n• Enter cover quantity and save your stock offline')
    ],
    if(searched) ...[
      const SizedBox(height:12),Text('${matches.length} matching models',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(matches.isEmpty && !busy && error == null) const Padding(padding:EdgeInsets.all(20),child:Text('No matching models found. Try a shorter search.')),
      ...matches.map((phone){
        final old=saved(phone);
        return Card(elevation:0,color:Colors.white,child:ListTile(
          leading:PhoneThumb(key:ValueKey('${phone.brand} ${phone.model}'),brand:phone.brand,model:phone.model),
          title:Text('${phone.brand} ${phone.model}',style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text(old == null ? 'Not saved yet' : 'Saved · ${old['quantity']} cover(s)'),
          trailing:Icon(old == null ? Icons.add_circle_outline : Icons.edit_outlined,color:const Color(0xFF087F6B)),
          onTap:()=>edit(phone,old:old)
        ));
      })
    ]
  ]);

  Widget inventoryView() {
    final total=stock.fold<int>(0,(s,r)=>s+((r['quantity'] as int?)??0));
    if(stock.isEmpty) return const Center(child:Padding(padding:EdgeInsets.all(28),child:Text('No saved phones yet. Search for a phone and add stock.',textAlign:TextAlign.center)));
    return Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:Row(children:[
        Expanded(child:_Metric(label:'PHONE MODELS',value:'${stock.length}')),
        const SizedBox(width:10),Expanded(child:_Metric(label:'TOTAL COVERS',value:'$total'))
      ])),
      Expanded(child:ListView.builder(padding:const EdgeInsets.fromLTRB(14,0,14,16),itemCount:stock.length,itemBuilder:(context,index){
        final row=stock[index];
        final path=row['image_path'] as String?;
        return Card(elevation:0,color:Colors.white,child:ListTile(
          leading:PhoneThumb(key:ValueKey('${row['brand']} ${row['model']}'),brand:'${row['brand']}',model:'${row['model']}',path:path),
          title:Text('${row['brand']} ${row['model']}',style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((row['quantity'] as int)>0 ? 'AVAILABLE · ${row['quantity']} cover(s)' : 'OUT OF STOCK',style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:(row['quantity'] as int)>0 ? const Color(0xFF087F6B) : Colors.red)),
            if((row['description'] as String).isNotEmpty) Text(row['description'] as String,maxLines:2,overflow:TextOverflow.ellipsis)
          ]),
          trailing:PopupMenuButton<String>(onSelected:(v){
            final phone=Phone('${row['phone_id']}','${row['brand']}','${row['model']}',row['image_url'] as String?);
            if(v=='edit') edit(phone,old:row); else remove(row);
          },itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit stock')),PopupMenuItem(value:'delete',child:Text('Delete'))])
        ));
      }))
    ]);
  }
}

class PhoneThumb extends StatefulWidget {
  final String brand, model;
  final String? path, url;
  const PhoneThumb({super.key, required this.brand, required this.model, this.path, this.url});
  @override
  State<PhoneThumb> createState() => _PhoneThumbState();
}

class _PhoneThumbState extends State<PhoneThumb> {
  static final Map<String, Future<String?>> _photoTasks = {};

  static String _key(String brand, String model) =>
      (brand + '_' + model).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static const Map<String, List<String>> _officialDomains = {
    'samsung': ['samsungmobilepress.com', 'images.samsung.com'],
    'apple': ['apple.com', 'is1-ssl.mzstatic.com'],
    'iphone': ['apple.com', 'is1-ssl.mzstatic.com'],
    'oneplus': ['oneplus.com', 'image01.oneplus.net', 'oasis.opstatics.com'],
    'xiaomi': ['mi.com', 'appmifile.com', 'mi-img.com'],
    'redmi': ['mi.com', 'appmifile.com', 'mi-img.com'],
    'poco': ['mi.com', 'appmifile.com', 'mi-img.com'],
    'oppo': ['oppo.com', 'image.oppo.com'],
    'vivo': ['vivo.com', 'vivofs.com'],
    'iqoo': ['iqoo.com', 'vivo.com', 'vivofs.com'],
    'realme': ['realme.com', 'realme.net'],
    'tecno': ['tecno-mobile.com'],
    'infinix': ['infinixmobility.com'],
    'itel': ['itel-life.com'],
    'honor': ['honor.com', 'honorfile.com'],
    'huawei': ['huawei.com'],
    'google': ['google.com', 'googleusercontent.com'],
    'pixel': ['google.com', 'googleusercontent.com'],
    'motorola': ['motorola.com'],
    'nothing': ['nothing.tech'],
    'asus': ['asus.com'],
    'sony': ['sony.com', 'sony.net'],
    'nokia': ['hmd.com'],
    'hmd': ['hmd.com'],
    'zte': ['zte.com'],
    'nubia': ['nubia.com'],
    'tcl': ['tcl.com'],
    'meizu': ['meizu.com'],
    'lava': ['lavainternational.in'],
  };

  static bool _isOfficialHost(String host, List<String> allowed) =>
      allowed.any((domain) => host == domain || host.endsWith('.' + domain));

  static String _decodeSearchUrl(String value) => value
      .replaceAll(r'\u003d', '=')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u003a', ':')
      .replaceAll(r'\/', '/')
      .replaceAll('&amp;', '&');

  static Future<String?> _officialBackImageUrl(String brand, String model) async {
    final brandKey = brand.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final allowed = _officialDomains[brandKey];
    if (allowed == null || model.trim().isEmpty) return null;

    try {
      // Samsung publishes explicit, manufacturer-labelled rear images in its
      // Mobile Press media library. Use that library instead of image search.
      if (brandKey == 'samsung') {
        final q = 'site:api.samsungmobilepress.com/media-assets "Galaxy ' +
            model.trim() + '"';
        final searchUri = Uri.https('www.google.com', '/search', {'q': q});
        final searchResponse = await http.get(searchUri, headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36'
        }).timeout(const Duration(seconds: 12));
        if (searchResponse.statusCode == 200) {
          final links = RegExp(r'https?://api\.samsungmobilepress\.com/media-assets/[a-z0-9-]+',
              caseSensitive: false).allMatches(_decodeSearchUrl(searchResponse.body));
          for (final link in links) {
            final page = await http.get(Uri.parse(link.group(0)!)).timeout(const Duration(seconds: 12));
            if (page.statusCode != 200) continue;
            final html = page.body;
            final anchors = RegExp(r'<a\b([^>]*)>([\s\S]*?)</a>', caseSensitive: false);
            for (final match in anchors.allMatches(html)) {
              final attrs = match.group(1) ?? '';
              final body = match.group(2) ?? '';
              final img = RegExp(r'<img\b([^>]*)>', caseSensitive: false)
                  .firstMatch(body)?.group(1) ?? '';
              final label = ('$attrs $body $img')
                  .replaceAll(RegExp(r'<[^>]*>'), ' ')
                  .replaceAll(RegExp(r'&[^;]+;'), ' ')
                  .toLowerCase();
              if (!RegExp(r'\b(back|rear)\b').hasMatch(label)) continue;
              final href = RegExp(r'''href=["']([^"']+)["']''', caseSensitive: false)
                  .firstMatch(attrs)?.group(1);
              if (href == null) continue;
              final asset = Uri.parse('https://api.samsungmobilepress.com').resolve(href);
              if (asset.host == 'api.samsungmobilepress.com' &&
                  asset.path.startsWith('/file/')) return asset.toString();
            }
          }
        }
      }

      // Other manufacturers: search only their own domains and known official
      // image CDNs. The result must explicitly identify a rear/back view.
      final domains = allowed.map((d) => 'site:' + d).join(' OR ');
      final query = '($domains) "' + brand + ' ' + model.trim() +
          '" (back view OR rear view OR back panel) official product image';
      final uri = Uri.https('www.google.com', '/search', {
        'tbm': 'isch',
        'q': query,
        'safe': 'active'
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36'
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final html = _decodeSearchUrl(response.body);
      final candidates = <String>[];
      final murl = RegExp(r'"(https?://[^" ]+)"').allMatches(html);
      for (final match in murl) {
        final raw = match.group(1);
        if (raw == null) continue;
        final candidate = raw.replaceAll(r'\u003d', '=').replaceAll(r'\u0026', '&');
        final parsed = Uri.tryParse(candidate);
        if (parsed == null || parsed.scheme != 'https' ||
            !_isOfficialHost(parsed.host.toLowerCase(), allowed)) continue;
        if (!RegExp(r'\.(jpg|jpeg|png|webp)(\?|$)', caseSensitive: false)
            .hasMatch(parsed.path + (parsed.hasQuery ? '?' + parsed.query : ''))) continue;

        final at = match.start;
        final context = html.substring(
          at > 900 ? at - 900 : 0,
          (at + 900 < html.length) ? at + 900 : html.length
        ).toLowerCase();
        if (!RegExp(r'\b(back|rear|rear view|back view|back panel)\b').hasMatch(context)) continue;
        if (!candidates.contains(candidate)) candidates.add(candidate);
      }
      if (candidates.isNotEmpty) return candidates.first;
    } catch (_) {}
    return null;
  }

  static Future<String?> loadOfficialPhoto(String brand, String model) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'official_phone_photos'));
      if (!await folder.exists()) await folder.create(recursive: true);
      final file = File(p.join(folder.path, _key(brand, model) + '.img'));
      if (await file.exists() && await file.length() > 0) return file.path;

      final url = await _officialBackImageUrl(brand, model);
      if (url == null) return null;
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('text/html')) return null;
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _photo() {
    final key = _key(widget.brand, widget.model);
    return _photoTasks.putIfAbsent(key, () async {
      if (widget.path != null && widget.path!.contains('official_phone_photos')) {
        final existing = File(widget.path!);
        if (await existing.exists() && await existing.length() > 0) return existing.path;
      }
      return loadOfficialPhoto(widget.brand, widget.model);
    });
  }

  Widget _placeholder() => CircleAvatar(
    backgroundColor: const Color(0xFFEAF0EF),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Icon(Icons.phone_android, size: 23, color: Color(0xFF087F6B)),
      Text('No official photo', style: TextStyle(fontSize: 6, color: Colors.black54))
    ])
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _photo(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircleAvatar(
          backgroundColor: Color(0xFFEAF0EF),
          child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
        );
      }
      final path = snapshot.data;
      if (path == null || path.isEmpty) return _placeholder();
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path), width: 58, height: 58, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder()
        )
      );
    }
  );
}

class _Metric extends StatelessWidget {
  final String label,value;
  const _Metric({required this.label,required this.value});
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(fontSize:10,color:Colors.black54))]));
}