import 'package:flutter/material.dart';
//  MODELS
import '../models/subject.dart';
//  SERVICES
import '../services/database_service.dart';
//------------------------------------------------------------

class AddSubjectScreen extends StatefulWidget {
  final Subject? subject;

  const AddSubjectScreen({super.key, this.subject});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  late TextEditingController _nameController;
  late int _selectedIcon;
  late int _selectedColor;
  late int _minAttendence;
  late final List<IconData> _iconOptions = [
    Icons.book,
    Icons.science,
    Icons.calculate,
    Icons.history,
    Icons.palette,
    Icons.code,
    Icons.fitness_center,
    Icons.music_note
  ];
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? "");
    _selectedIcon = widget.subject?.iconCodePoint ?? Icons.book.codePoint;
    _selectedColor = widget.subject?.colorValue ?? Colors.blue.value;
    _minAttendence = widget.subject?.minAttend ?? 75;
  }

  void _saveSubject() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a subject name")),
      );
      return;
    }
    try {
      if (widget.subject != null) {
        // EDIT MODE
        widget.subject!.name = _nameController.text.trim();
        widget.subject!.iconCodePoint = _selectedIcon;
        widget.subject!.colorValue = _selectedColor;
        await DatabaseService.saveSubject(widget.subject!);
      } else {
        // CREATE MODE
        final newSubject = Subject(
          name: _nameController.text.trim(),
          iconCodePoint: _selectedIcon,
          colorValue: _selectedColor,
        );
        await DatabaseService.saveSubject(newSubject);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error saving subject: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject != null ? "Edit Subject" : "New Subject"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Subject Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Select Icon",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _iconOptions.map((icon) {
              final isSelected = _selectedIcon == icon.codePoint;
              return IconButton(
                onPressed: () => setState(() => _selectedIcon = icon.codePoint),
                icon: Icon(icon),
                color: isSelected ? Color(_selectedColor) : Colors.grey,
                style: IconButton.styleFrom(
                  backgroundColor: isSelected
                      ? Color(_selectedColor).withOpacity(0.1)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Text("Select Color",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 15,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor == color.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color.value),
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 18,
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Minimum Attendance: $_minAttendence %",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _minAttendence.toDouble(),
                min: 0,
                max: 100,
                divisions: 20, // Snaps to every 5% (5, 10, 15...)
                label: "$_minAttendence%",
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (double value) {
                  setState(() {
                    _minAttendence = value.toInt();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              _saveSubject();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.subject != null ? "Update" : "Create"),
          ),
        ],
      ),
    );
  }
}
