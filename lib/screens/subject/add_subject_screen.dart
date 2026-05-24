import 'package:flutter/material.dart';
//  MODELS
import '../../models/subject.dart';
//  SERVICES
import '../../services/database_service.dart';
//------------------------------------------------------------

class AddSubjectScreen extends StatefulWidget {
  final Subject? subject;

  const AddSubjectScreen({super.key, this.subject});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _selectedIcon;
  late int _selectedColor;
  late int _minAttendence;

  late final List<IconData> _iconOptions = [
    Icons.book_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.access_time_rounded,
    Icons.palette_rounded,
    Icons.code_rounded,
    Icons.fitness_center_rounded,
    Icons.music_note_rounded,
  ];
  final List<Color> _colorOptions = [
    const Color(0xFF06B6D4), // Electric Cyan
    const Color(0xFF6366F1), // Indigo / Premium Purple
    const Color(0xFFEF4444), // Crimson Red
    const Color(0xFF4ADE80), // Pastel Green
    const Color(0xFFF59E0B), // Amber Orange
    const Color(0xFFA855F7), // Deep Purple
    const Color(0xFFEC4899), // Hot Pink
    const Color(0xFFFBBF24), // Canary Yellow
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? "");
    _selectedIcon =
        widget.subject?.iconCodePoint ?? Icons.book_rounded.codePoint;
    _selectedColor = widget.subject?.colorValue ?? Color(0xFF06B6D4).value;
    _minAttendence = widget.subject?.minAttend ?? 75;
  }

  void _saveSubject() async {
    // Validation
    if (!_formKey.currentState!.validate()) return;
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
        widget.subject!.minAttend = _minAttendence;
        await DatabaseService.saveSubject(widget.subject!);
      } else {
        // CREATE MODE
        final newSubject = Subject(
          name: _nameController.text.trim(),
          iconCodePoint: _selectedIcon,
          colorValue: _selectedColor,
          minAttend: _minAttendence,
        );
        await DatabaseService.saveSubject(newSubject);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("Error saving subject: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    }
  }

  void _deleteSubject() async {
    if (widget.subject == null) return;

    // Show a confirmation dialog to prevent accidental clicks
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete Subject?"),
        content: Text(
            "This will permanently remove '${widget.subject!.name}' and all its associated data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(dialogCtx); // Close dialog box modal

              // Call delete directly on the Hive Object instance
              await widget.subject!.delete();

              if (context.mounted) {
                Navigator.of(context)
                    .pop(true); // Return to dashboard with a refresh token
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeAccentColor = Color(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.subject != null ? "Edit Subject" : "Add Subject",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // 1. DYNAMIC PREVIEW HERO AVATAR
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeAccentColor.withOpacity(0.12),
                      border: Border.all(
                        color: activeAccentColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
                        size: 56,
                        color: activeAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. FORM INPUT FIELD FOR SUBJECT NAME
            Text(
              "Subject Name",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                  color: colorScheme.onSurface, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Enter subject name...",
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.25),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? "Please enter a subject name"
                  : null,
            ),
            const SizedBox(height: 18),

            // 3. ICON SELECTION GRID MATRIX
            Text(
              "Choose Icon",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Clean, proportional column tracking
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _iconOptions.length,
              itemBuilder: (context, idx) {
                final iconData = _iconOptions[idx];
                final isSelected = _selectedIcon == iconData.codePoint;

                return InkWell(
                  onTap: () =>
                      setState(() => _selectedIcon = iconData.codePoint),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeAccentColor
                          : colorScheme.surfaceContainerHighest
                              .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : colorScheme.onSurface.withOpacity(0.06),
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.65),
                      size: 22,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),

            // 4. COLOR SELECTION WRAP WITH DOT SHADOWS
            Text(
              "Choose Color",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color.value;

                return InkWell(
                  onTap: () => setState(() => _selectedColor = color.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.surface,
                              width: 3,
                              strokeAlign: BorderSide.strokeAlignInside)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            color: colorScheme.surface, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 5. ATTENDANCE CRITERIA DOCK SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Minimum Attendance",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                Text(
                  "$_minAttendence%",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: activeAccentColor),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeAccentColor,
                inactiveTrackColor:
                    colorScheme.surfaceContainerHighest.withOpacity(0.3),
                thumbColor: activeAccentColor,
                overlayColor: activeAccentColor.withOpacity(0.12),
                trackHeight: 4,
                tickMarkShape:
                    const RoundSliderTickMarkShape(tickMarkRadius: 2),
                activeTickMarkColor: Colors.transparent,
                inactiveTickMarkColor: colorScheme.onSurface.withOpacity(0.15),
              ),
              child: Slider(
                value: _minAttendence.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (double value) {
                  setState(() {
                    _minAttendence = value.toInt();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["0%", "20%", "40%", "60%", "80%", "100%"]
                    .map((label) => Text(
                          label,
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.35),
                              fontWeight: FontWeight.w500),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.subject != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteSubject,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text(
                        "Delete",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 12), // Spacer gutter between action zones
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSubject,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                        widget.subject != null
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        size: 20),
                    label: Text(
                      widget.subject != null ? "Update" : "Create",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
