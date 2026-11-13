import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserPhotosScreen extends StatefulWidget{
  const UserPhotosScreen({super.key,required this.apiClient});
  final ApiClient apiClient;
  @override State<UserPhotosScreen> createState()=>_UserPhotosScreenState();
}
class _UserPhotosScreenState extends State<UserPhotosScreen>{
  bool loading=true,busy=false;String? error,notice;List<Map<String,dynamic>> photos=[];
  final picker=ImagePicker();
  final Map<String,Uint8List> cache={};
  @override void initState(){super.initState();load();}
  Future<void> load()async{setState(() { loading=true; error=null; });try{final r=await widget.apiClient.get('/user-profile/photos',authenticated:true);final d=r['data'];photos=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];for(final p in photos){final id=p['id']?.toString()??'';if(id.isNotEmpty&&!cache.containsKey(id)){try{cache[id]=await widget.apiClient.getBytes('/user-profile/photos/'+id+'/content',authenticated:true);}catch(_){}}}}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> upload() async {
    if (photos.length >= 6) { setState(()=>error='You can upload up to 6 photos.'); return; }
    final file=await picker.pickImage(source:ImageSource.gallery,imageQuality:88);
    if(file==null)return;
    final bytes=await file.readAsBytes();
    if(bytes.length>5*1024*1024){setState(()=>error='Photo size cannot exceed 5 MB.');return;}
    final ext=file.name.split('.').last.toLowerCase();
    if(!['jpg','jpeg','png','webp'].contains(ext)){setState(()=>error='Choose a JPG, PNG or WEBP image.');return;}
    setState(()=>busy=true);
    try{await widget.apiClient.postMultipartFile('/user-profile/photos',bytes:bytes,filename:file.name,fieldName:'photo',authenticated:true);}
    catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
    if(mounted){setState(()=>notice='Photo uploaded successfully.');await load();}
  }
  Future<void> action(String id,bool primary)async{setState(()=>busy=true);try{if(primary){await widget.apiClient.put('/user-profile/photos/'+id+'/primary',body:{},authenticated:true);}else{await widget.apiClient.delete('/user-profile/photos/'+id,authenticated:true);cache.remove(id);}await load();}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator(color:AppPalette.maroon));return RefreshIndicator(color:AppPalette.maroon,onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Profile photo gallery',style:TextStyle(fontSize:22,color:AppPalette.darkMaroon)),
    const SizedBox(height:8),
    if(error!=null)Text(error!,style:const TextStyle(color:AppPalette.error)),
    if(notice!=null)Text(notice!,style:const TextStyle(color:AppPalette.maroon)),
    Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:busy?null:upload,icon:const Icon(Icons.add_a_photo),label:const Text('Upload photo'))),
    const Text('Your profile photos and primary photo are managed here.',style:TextStyle(color:AppPalette.secondary)),
    const SizedBox(height:12),
    if(photos.isEmpty)const Card(color:AppPalette.surface,child:Padding(padding:EdgeInsets.all(20),child:Text('No profile photos uploaded yet.'))),
    ...photos.map((p){final id=p['id']?.toString()??'';final primary=p['isPrimary']==true;final bytes=cache[id];return Card(color:AppPalette.surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:AppPalette.border)),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(bytes!=null)ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.memory(bytes,width:double.infinity,height:220,fit:BoxFit.cover))
      else Container(height:150,width:double.infinity,decoration:BoxDecoration(color:AppPalette.champagne,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.image_not_supported_outlined,size:42,color:AppPalette.maroon)),
      const SizedBox(height:8),Row(children:[Expanded(child:Text(primary?'Primary photo':'Profile photo',style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon))),if(primary)const Chip(label:Text('Primary'))]),
      Text('Visibility: '+(p['visibility']??'Default').toString()+' · '+((p['fileSize']??0).toString())+' bytes',style:const TextStyle(fontSize:11,color:AppPalette.secondary)),
      Row(children:[if(!primary)Expanded(child:OutlinedButton(onPressed:busy||id.isEmpty?null:()=>action(id,true),child:const Text('Set as primary'))),if(!primary)const SizedBox(width:8),Expanded(child:TextButton(onPressed:busy||id.isEmpty?null:()=>action(id,false),child:const Text('Delete photo')))]),
    ])));}),
    const SizedBox(height:8),
    
  ]));}
}
