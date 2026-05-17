import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/smart_reader_viewmodel.dart';

class SmartReaderView extends StatelessWidget {
  const SmartReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SmartReaderViewModel()..init(),
      child: const _SmartReaderBody(),
    );
  }
}

class _SmartReaderBody extends StatefulWidget {
  const _SmartReaderBody();

  @override
  State<_SmartReaderBody> createState() => _SmartReaderBodyState();
}

class _SmartReaderBodyState extends State<_SmartReaderBody> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SmartReaderViewModel>();
      vm.scaffoldMessenger = ScaffoldMessenger.of(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) => _buildCourseDropdown(vm),
                ),
                const SizedBox(height: 12),
                _ControlCard(),
                const SizedBox(height: 20),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) => _buildCurrentTextCard(vm),
                ),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) {
                    if (vm.transcript.isNotEmpty && vm.summary.isEmpty) {
                      return Column(children: [
                        const SizedBox(height: 16),
                        _buildSummarizeButton(vm),
                      ]);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) {
                    if (vm.isSummarizing) {
                      return Column(children: [
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'جاري التلخيص',
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                      ]);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) {
                    if (vm.summary.isNotEmpty) {
                      return Column(children: [
                        const SizedBox(height: 20),
                        _buildSummaryCard(vm),
                        const SizedBox(height: 20),
                        _QaSection(),
                      ]);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) {
                    if (vm.errorMessage.isNotEmpty) {
                      return Column(children: [
                        const SizedBox(height: 12),
                        _buildErrorBanner(vm),
                      ]);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 30),
                Semantics(
                  label: 'قائمة المحاضرات المحفوظة',
                  child: Text(
                    'المحفوظة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<SmartReaderViewModel>(
                  builder: (_, vm, __) => _buildSavedNotesList(vm),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDropdown(SmartReaderViewModel vm) {
    return Semantics(
      label: 'اختيار المادة',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mintLight, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text('اختر المادة (اختياري)',
                style: GoogleFonts.cairo(color: AppColors.grey)),
            value: vm.selectedCourseId,
            items: vm.courses
                .map((course) {
                  final courseId =
                      (course['course_id'] ?? course['id'])?.toString();
                  if (courseId == null || courseId.isEmpty) return null;
                  return DropdownMenuItem<String>(
                    value: courseId,
                    child: Text((course['course_name'] ?? course['name'] ?? '').toString(),
                        style: GoogleFonts.cairo(color: AppColors.primaryDark)),
                  );
                })
                .whereType<DropdownMenuItem<String>>()
                .toList(),
            onChanged: vm.selectCourseById,
          ),
        ),
      ),
    );
  }


  Widget _buildCurrentTextCard(SmartReaderViewModel vm) {
    final isRec = vm.isRecording;
    return Semantics(
      label: 'النص المسجل',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.mintLight, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isRec ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isRec ? Colors.transparent : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRec ? Icons.mic_none_rounded : Icons.pause_rounded,
                    color: isRec ? const Color(0xFFD34B4B) : AppColors.white,
                    size: isRec ? 28 : 18,
                  ),
                ),
                Text(
                  'محاضرة جديدة - النص',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                isRec
                    ? 'جاري التسجيل... سيظهر النص بعد الإيقاف'
                    : (vm.transcript.isEmpty
                        ? 'ابدأ التسجيل وسيظهر النص بعد الإيقاف'
                        : vm.transcript),
                style: GoogleFonts.cairo(fontSize: 16, color: AppColors.darkGrey),
              ),
            ),
            if (vm.transcript.isNotEmpty && !isRec) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  label: 'استمع للنص المسجل',
                  button: true,
                  child: InkWell(
                    onTap: () => vm.readAloud(vm.transcript),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volume_up_rounded, color: AppColors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarizeButton(SmartReaderViewModel vm) {
    return Semantics(
      label: 'تلخيص بالذكاء الاصطناعي',
      button: true,
      child: ElevatedButton.icon(
        onPressed: () => vm.summarizeTranscript(),
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: Text('لخّص بالذكاء الاصطناعي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SmartReaderViewModel vm) {
    return Semantics(
      label: 'الملخص',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mintBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الملخص',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark)),
                Semantics(
                  label: 'استمع للملخص',
                  button: true,
                  child: InkWell(
                    onTap: () => vm.readAloud(vm.summary),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volume_up_rounded,
                          color: AppColors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(vm.summary,
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.primaryDark,
                      height: 1.7)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorBanner(SmartReaderViewModel vm) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(vm.errorMessage,
                style: GoogleFonts.cairo(color: Colors.red, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  Widget _buildSavedNotesList(SmartReaderViewModel vm) {
    if (vm.savedNotes.isEmpty) {
      return Semantics(
        label: 'لا توجد محاضرات محفوظة',
        child: Center(
          child: Text(
            'لا توجد محاضرات محفوظة',
            style: GoogleFonts.cairo(color: AppColors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.savedNotes.length,
      itemBuilder: (context, index) {
        final note = vm.savedNotes[index];
        return Semantics(
          label: 'ملخص ${note['title'] ?? ''}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'] ?? 'محاضرة ${index + 1}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        note['summary_content'] ?? note['transcript'] ?? 'عذراً، لم أستقبل نص المحاضرة.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 13, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'حذف الملخص',
                  button: true,
                  child: InkWell(
                    onTap: () => vm.deleteNote(note['id']),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'استمع للملخص',
                  button: true,
                  child: InkWell(
                    onTap: () => vm.readAloud(note['summary_content'] ?? note['transcript'] ?? ''),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartReaderViewModel>(
      builder: (_, vm, __) {
        final isRec = vm.isRecording;
        final statusColor = isRec ? const Color(0xFFD34B4B) : AppColors.primaryDark;
        final statusText = isRec ? 'يسجل الآن' : 'جاهز';

        return Semantics(
          label: 'لوحة التحكم، $statusText',
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.mintLight, width: 1.5),
            ),
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    statusText,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: isRec ? 'إيقاف التسجيل' : 'بدء التسجيل',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => vm.toggleRecording(),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isRec
                              ? const LinearGradient(
                                  colors: [Color(0xFFE53935), Color(0xFFD34B4B)],
                                )
                              : AppColors.primaryGradient,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isRec ? 'إيقاف التسجيل' : 'ابدأ التسجيل',
                              style: GoogleFonts.cairo(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              isRec ? Icons.pause_rounded : Icons.circle,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isRec) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    label: 'مدة التسجيل ${vm.formattedTime}',
                    child: Text(
                      vm.formattedTime,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD34B4B),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'حفظ التسجيل',
                        button: true,
                        child: OutlinedButton.icon(
                          onPressed: vm.transcript.isNotEmpty ? () => vm.saveToDatabase() : null,
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: Text('احفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.mintLight, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: 'إلغاء ومسح النص',
                        button: true,
                        child: OutlinedButton.icon(
                          onPressed: () => vm.clearAll(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.mintLight, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'قراءة نص من ورقة بالكاميرا',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: vm.isOcrLoading ? null : () => vm.readFromCamera(),
                      icon: vm.isOcrLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 20),
                      label: Text(
                        vm.isOcrLoading ? 'جاري القراءة...' : 'قراءة من ورقة (الكاميرا)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QaSection extends StatefulWidget {
  const _QaSection();

  @override
  State<_QaSection> createState() => _QaSectionState();
}

class _QaSectionState extends State<_QaSection> {
  final _qaController = TextEditingController();

  @override
  void dispose() {
    _qaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartReaderViewModel>(
      builder: (_, vm, __) {
        return Semantics(
          label: 'قسم الأسئلة',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mintLight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('اسأل عن المحاضرة',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          fontSize: 15)),
                ]),
                const SizedBox(height: 12),
                Semantics(
                  label: 'اكتب سؤالك',
                  child: TextField(
                    controller: _qaController,
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك هنا...',
                      hintStyle: GoogleFonts.cairo(color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: GoogleFonts.cairo(fontSize: 14),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        vm.askQuestion(value);
                        _qaController.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'إرسال السؤال',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_qaController.text.isNotEmpty) {
                          vm.askQuestion(_qaController.text);
                          _qaController.clear();
                          FocusScope.of(context).unfocus();
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('اسأل',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                if (vm.isQaLoading) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ],
                if (vm.qaAnswer.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(vm.qaAnswer,
                                style: GoogleFonts.cairo(
                                    fontSize: 14, color: AppColors.primaryDark, height: 1.6)),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label: 'استمع للإجابة',
                            button: true,
                            child: InkWell(
                              onTap: () => vm.readAloud(vm.qaAnswer),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volume_up_rounded,
                                    color: AppColors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
