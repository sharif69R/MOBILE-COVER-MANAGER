import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
  const Phone(this.id, this.brand, this.model, this.image);
  factory Phone.fromJson(Map<String, dynamic> j) {
    String get(List<String> keys, [String fallback = '']) {
      for (final k in keys) {
        final v = j[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
      return fallback;
    }
    var brand = get(['brand','manufacturer','maker','vendor']);
    final rawBrand = j['brand'];
    if (brand.isEmpty && rawBrand is Map) {
      brand = (rawBrand['name'] ?? rawBrand['slug'] ?? '').toString().trim();
    }
    final slug = get(['slug','id','key']);
    if (brand.isEmpty) {
      final known = <String,String>{
        'samsung':'Samsung','galaxy':'Samsung','apple':'Apple','iphone':'Apple',
        'infinix':'Infinix','tecno':'TECNO','oppo':'OPPO','vivo':'vivo',
        'oneplus':'OnePlus','huawei':'Huawei','honor':'Honor','xiaomi':'Xiaomi',
        'redmi':'Xiaomi','poco':'POCO','google':'Google','pixel':'Google',
        'nothing':'Nothing','motorola':'Motorola','realme':'Realme','nokia':'Nokia',
        'sony':'Sony','asus':'ASUS','lenovo':'Lenovo','zte':'ZTE','nubia':'Nubia',
        'iqoo':'iQOO','meizu':'Meizu','htc':'HTC','lg':'LG','sharp':'Sharp',
        'fairphone':'Fairphone','blackview':'Blackview','doogee':'DOOGEE',
        'ulefone':'Ulefone','tcl':'TCL','itel':'itel'
      };
      final first = slug.split('-').first.toLowerCase();
      brand = known[first] ?? 'Other';
    }
    final model = get(['model','name','title','device','model_name'], 'Unknown model');
    final img = get(['image_url','imageUrl','image','photo','thumbnail','picture']);
    return Phone(slug.isEmpty ? '${brand}_$model' : slug, brand, model, img.isEmpty ? null : img);
  }
}

class CoverApp extends StatelessWidget {
  final Database db;
  const CoverApp({super.key, required this.db});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mobile Cover Manager', debugShowCheckedModeBanner: false,
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
      // The catalogue is downloaded during the APK build and bundled locally.
      // Searching therefore works without DNS, an API key, or an internet connection.
      final decoded = jsonDecode(await rootBundle.loadString('assets/phones.json'));
      dynamic rows = decoded;
      if (decoded is Map) {
        rows = decoded['results'] ?? decoded['data'] ?? decoded['phones'] ?? decoded['items'];
      }
      if (rows is! List) throw const FormatException('Bundled catalogue has an unknown format');
      final all = rows.whereType<Map>().map((e) => Phone.fromJson(Map<String,dynamic>.from(e))).where((p) => p.model != 'Unknown model').toList();
      final q = search.text.trim().toLowerCase();
      final terms = q.split(RegExp(r'\s+'));
      final ranked = <({Phone phone, int score})>[];
      for (final phone in all) {
        final text = '${phone.brand} ${phone.model}'.toLowerCase();
        var score = text == q ? 100 : text.startsWith(q) ? 60 : text.contains(q) ? 30 : 0;
        for (final term in terms) { if (text.contains(term)) score += 10; }
        if (score > 0) ranked.add((phone: phone, score: score));
      }
      ranked.sort((a,b) => b.score.compareTo(a.score));
      if (mounted) setState(() => matches = ranked.take(60).map((e) => e.phone).toList());
    } catch (e) {
      if (mounted) setState(() { matches = []; error = 'Could not load the free phone catalogue. Check internet and retry. ($e)'; });
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
        'gsrlimit':'5','prop':'imageinfo','iiprop':'url','iiurlwidth':'320','format':'json'
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
    final url = phone.image ?? await commonsImage('${phone.brand} ${phone.model} smartphone');
    if (url == null) return null;
    try {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds:15));
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) return null;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path,'phone_${url.hashCode}.img'));
      await file.writeAsBytes(r.bodyBytes,flush:true);
      return file.path;
    } catch (_) { return null; }
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
              final imagePath = old?['image_path'] as String? ?? await cacheImage(phone);
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
    appBar:AppBar(title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('MOBILE COVER MANAGER',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
      Text(tab == 0 ? 'Search phones · Save cover stock' : 'Your inventory · Works offline',style:const TextStyle(fontSize:11,color:Colors.black54))
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
    const SizedBox(height:4),const Text('Built-in phone catalogue · Search works offline',style:TextStyle(fontSize:12,color:Colors.black54)),
    if(error != null) Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.red))),
    if(!searched) ...[
      const SizedBox(height:20),const Text('Popular brands',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      const SizedBox(height:8),
      Wrap(spacing:7,runSpacing:7,children:['Samsung','Apple','Infinix','OPPO','vivo','Xiaomi','OnePlus','Huawei','Google Pixel','Nothing','TECNO','Realme','Motorola','Honor'].map((b)=>ActionChip(label:Text(b),onPressed:(){search.text=b;findPhones();})).toList()),
      const SizedBox(height:20),const Text('• Search the online phone catalogue\n• Enter cover quantity and an optional description\n• Save locally and access your stock offline')
    ],
    if(searched) ...[
      const SizedBox(height:12),Text('${matches.length} matching models',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(matches.isEmpty && !busy && error == null) const Padding(padding:EdgeInsets.all(20),child:Text('No matching models found. Try a shorter search.')),
      ...matches.map((phone){
        final old=saved(phone);
        return Card(elevation:0,color:Colors.white,child:ListTile(
          leading:const CircleAvatar(child:Icon(Icons.phone_android)),
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
          leading:PhoneThumb(path:path,url:row['image_url'] as String?),
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

class PhoneThumb extends StatelessWidget {
  final String? path,url;
  const PhoneThumb({super.key,this.path,this.url});
  @override
  Widget build(BuildContext context) {
    final fallback=const CircleAvatar(child:Icon(Icons.phone_android));
    if(path != null && File(path!).existsSync()) return ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(path!),width:54,height:54,fit:BoxFit.contain,errorBuilder:(_,__,___)=>fallback));
    if(url != null && url!.startsWith('http')) return ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(url!,width:54,height:54,fit:BoxFit.contain,errorBuilder:(_,__,___)=>fallback));
    return fallback;
  }
}

class _Metric extends StatelessWidget {
  final String label,value;
  const _Metric({required this.label,required this.value});
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(fontSize:10,color:Colors.black54))]));
}