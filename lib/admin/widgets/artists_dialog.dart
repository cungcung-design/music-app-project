// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import '../../services/database_service.dart';
// import '../../models/artist.dart';

// class ArtistDialog extends StatefulWidget {
//   final DatabaseService db;
//   final Artist? artist;
//   const ArtistDialog({super.key, required this.db, this.artist});

//   @override
//   State<ArtistDialog> createState() => _ArtistDialogState();
// }

// class _ArtistDialogState extends State<ArtistDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController nameController;
//   late TextEditingController bioController;
//   late TextEditingController aboutController;

//   Uint8List? selectedImageBytes;
//   String? selectedFileName;
//   String? contentType;
//   bool _isSaving = false; // Prevents multiple taps and UI lag

//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.artist?.name ?? '');
//     bioController = TextEditingController(text: widget.artist?.bio ?? '');
//     aboutController = TextEditingController(text: widget.artist?.about ?? '');
    
//     if (widget.artist != null) {
//       _loadExistingImage();
//     }
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     bioController.dispose();
//     aboutController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadExistingImage() async {
//     if (widget.artist?.artistProfileUrl != null) {
//       try {
//         final response = await http.get(Uri.parse(widget.artist!.artistProfileUrl!));
//         if (response.statusCode == 200 && mounted) {
//           setState(() => selectedImageBytes = response.bodyBytes);
//         }
//       } catch (e) {
//         debugPrint("Error loading image: $e");
//       }
//     }
//   }

//   Future<void> _pickImage() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//       allowMultiple: false,
//       withData: true, // Crucial for mobile
//     );

//     if (result != null && result.files.single.bytes != null) {
//       final file = result.files.single;
//       final extension = file.extension?.toLowerCase();
      
//       setState(() {
//         selectedImageBytes = file.bytes;
//         selectedFileName = file.name;
//         contentType = (extension == 'jpg' || extension == 'jpeg') ? 'image/jpeg' : 'image/png';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: const Color(0xFF1E1E1E),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Text(
//         widget.artist == null ? "Add Artist" : "Edit Artist",
//         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//       ),
//       content: Form(
//         key: _formKey,
//         child: SizedBox(
//           width: 350,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildTextField(nameController, "Artist Name", Icons.person),
//                 const SizedBox(height: 20),
                
//                 // Image Selection Area
//                 GestureDetector(
//                   onTap: _pickImage,
//                   child: Container(
//                     height: 150,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.black26,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: selectedImageBytes != null
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(11),
//                             child: Image.memory(
//                               selectedImageBytes!,
//                               fit: BoxFit.cover,
//                               cacheWidth: 400, // FIX: Downscale image in memory to prevent Buffer Error
//                             ),
//                           )
//                         : const Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.add_a_photo, color: Colors.green, size: 40),
//                               SizedBox(height: 8),
//                               Text("Upload Profile Image", style: TextStyle(color: Colors.grey)),
//                             ],
//                           ),
//                   ),
//                 ),
//                 if (selectedFileName != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(selectedFileName!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isSaving ? null : () => Navigator.pop(context),
//           child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//         ),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             disabledBackgroundColor: Colors.grey,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           onPressed: _isSaving ? null : _saveArtist,
//           child: _isSaving 
//             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//             : Text(widget.artist == null ? "Add" : "Update", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: Colors.green, size: 20),
//         hintText: hint,
//         hintStyle: const TextStyle(color: Colors.grey),
//         filled: true,
//         fillColor: Colors.black26,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//       ),
//       validator: (val) => val!.isEmpty ? "Required" : null,
//     );
//   }

//   Future<void> _saveArtist() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSaving = true);
//     try {
//       if (widget.artist == null) {
//         await widget.db.addArtist(
//           name: nameController.text,
//           bio: bioController.text,
//           about: aboutController.text,
//           imageBytes: selectedImageBytes,
//           contentType: contentType,
//         );
//       } else {
//         await widget.db.updateArtist(
//           artistId: widget.artist!.id,
//           name: nameController.text,
//           bio: bioController.text,
//           about: aboutController.text,
//           newImageBytes: selectedImageBytes,
//           contentType: contentType,
//         );
//       }
//       if (mounted) Navigator.pop(context, true);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
// }

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';
import '../../models/artist.dart';

class ArtistDialog extends StatefulWidget {
  final DatabaseService db;
  final Artist? artist;
  const ArtistDialog({super.key, required this.db, this.artist});

  @override
  State<ArtistDialog> createState() => _ArtistDialogState();
}

class _ArtistDialogState extends State<ArtistDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  Uint8List? selectedImageBytes;
  String? selectedFileName;
  String? contentType;
  bool _isSaving = false; // New: To prevent UI lag/double taps during large image processing

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      nameController.text = widget.artist!.name;
      _loadExistingImage();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingImage() async {
    if (widget.artist?.artistProfileUrl != null) {
      try {
        final response = await http.get(Uri.parse(widget.artist!.artistProfileUrl!));
        if (response.statusCode == 200 && mounted) {
          setState(() {
            selectedImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        debugPrint("Error loading existing image: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Needed for Web and some Android versions
    );

    if (result != null && result.files.single.bytes != null) {
      final fileName = result.files.single.name;
      String? detectedContentType;
      final extension = fileName.split('.').last.toLowerCase();
      
      if (extension == 'jpg' || extension == 'jpeg') {
        detectedContentType = 'image/jpeg';
      } else {
        detectedContentType = 'image/png';
      }

      setState(() {
        selectedImageBytes = result.files.single.bytes;
        selectedFileName = fileName;
        contentType = detectedContentType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        widget.artist == null ? "Add Artist" : "Edit Artist",
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Artist Name',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter artist name" : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Artist Image"),
                ),
                if (selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(selectedFileName!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                
                // --- IMAGE PREVIEW FIX ---
                if (selectedImageBytes != null)
                  Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        selectedImageBytes!,
                        height: 160, width: 160,
                        fit: BoxFit.cover,
                       
                        cacheWidth: 300, 
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _isSaving ? null : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isSaving = true);
              try {
                if (widget.artist == null) {
                  await widget.db.addArtist(
                    name: nameController.text,
                    bio: bioController.text,
                    about: aboutController.text,
                    imageBytes: selectedImageBytes,
                    contentType: contentType,
                  );
                } else {
                  await widget.db.updateArtist(
                    artistId: widget.artist!.id,
                    name: nameController.text,
                    bio: bioController.text,
                    about: aboutController.text,
                    newImageBytes: selectedImageBytes,
                    contentType: contentType,
                  );
                }
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            }
          },
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(widget.artist == null ? "Add" : "Update"),
        ),
      ],
    );
  }
}