import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_state.dart';

/// Cubit managing the list and CRUD operations of sticker templates.
class TemplateListCubit extends Cubit<TemplateListState> {
  /// Creates a [TemplateListCubit] instance.
  TemplateListCubit(
    this._templateRepository,
    this._fileStorageService,
  ) : super(const TemplateListInitial());

  final TemplateRepository _templateRepository;
  final FileStorageService _fileStorageService;

  /// Loads all templates from the repository and emits loaded status.
  Future<void> loadTemplates() async {
    emit(const TemplateListLoading());
    final result = await _templateRepository.fetchTemplates();
    switch (result) {
      case Success(value: final templates):
        emit(TemplateListLoaded(templates));
      case Failure(error: final err):
        emit(TemplateListError(err.message));
    }
  }

  /// Deletes the template with [id] and reloads the template list.
  Future<void> deleteTemplate(String id) async {
    final result = await _templateRepository.deleteTemplate(id);
    switch (result) {
      case Success():
        await loadTemplates();
      case Failure(error: final err):
        emit(TemplateListError(err.message));
    }
  }

  /// Creates a new template with [name] and optional local [imageUrl],
  /// copies the image locally using [FileStorageService] if it's a local file,
  /// and reloads the template list.
  Future<LabelTemplate?> createNewTemplate(String name, {String? imageUrl}) async {
    final result = await _templateRepository.createTemplate(name);
    switch (result) {
      case Success(value: var template):
        if (imageUrl != null && imageUrl.isNotEmpty) {
          if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
            final file = File(imageUrl);
            if (file.existsSync()) {
              final uploadResult = await _fileStorageService.uploadTemplateImage(file);
              switch (uploadResult) {
                case Success(value: final savedPath):
                  template = template.copyWith(imageUrl: savedPath);
                  // Update template in repository
                  await _templateRepository.saveTemplate(template);
                case Failure(error: final err):
                  emit(TemplateListError('Failed to save template image: ${err.message}'));
                  return null;
              }
            }
          }
        }
        await loadTemplates();
        return template;
      case Failure(error: final err):
        emit(TemplateListError(err.message));
        return null;
    }
  }

  /// Updates an existing template's name and optional image.
  Future<void> updateTemplateDetails(
    LabelTemplate template, {
    required String newName,
    String? newImageUrl,
  }) async {
    emit(const TemplateListLoading());
    var updatedTemplate = template.copyWith(name: newName);

    if (newImageUrl != template.imageUrl) {
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        if (!newImageUrl.startsWith('http://') && !newImageUrl.startsWith('https://')) {
          final file = File(newImageUrl);
          if (file.existsSync()) {
            final uploadResult = await _fileStorageService.uploadTemplateImage(file);
            switch (uploadResult) {
              case Success(value: final savedPath):
                updatedTemplate = updatedTemplate.copyWith(imageUrl: savedPath);
              case Failure(error: final err):
                emit(TemplateListError('Failed to save template image: ${err.message}'));
                return;
            }
          } else {
            updatedTemplate = updatedTemplate.copyWith(imageUrl: newImageUrl);
          }
        } else {
          updatedTemplate = updatedTemplate.copyWith(imageUrl: newImageUrl);
        }
      } else {
        // Image was cleared
        updatedTemplate = LabelTemplate(
          id: template.id,
          name: newName,
          sheetConfig: template.sheetConfig,
          stickerConfig: template.stickerConfig,
          elements: template.elements,
          isFinalized: template.isFinalized,
          updatedAt: DateTime.now(),
        );
      }
    }

    final result = await _templateRepository.saveTemplate(updatedTemplate);
    switch (result) {
      case Success():
        await loadTemplates();
      case Failure(error: final err):
        emit(TemplateListError(err.message));
    }
  }

  /// Copies an existing [sourceTemplate] with a new [newName] and saves it locally and remotely.
  Future<LabelTemplate?> copyTemplate(LabelTemplate sourceTemplate, String newName) async {
    emit(const TemplateListLoading());
    final createResult = await _templateRepository.createTemplate(newName);
    switch (createResult) {
      case Success(value: final newShell):
        var copiedTemplate = newShell.copyWith(
          sheetConfig: sourceTemplate.sheetConfig,
          stickerConfig: sourceTemplate.stickerConfig,
          elements: sourceTemplate.elements,
          isFinalized: sourceTemplate.isFinalized,
          updatedAt: DateTime.now(),
        );

        if (sourceTemplate.imageUrl != null && sourceTemplate.imageUrl!.isNotEmpty) {
          final imageUrl = sourceTemplate.imageUrl!;
          if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
            final file = File(imageUrl);
            if (file.existsSync()) {
              final uploadResult = await _fileStorageService.uploadTemplateImage(file);
              switch (uploadResult) {
                case Success(value: final savedPath):
                  copiedTemplate = copiedTemplate.copyWith(imageUrl: savedPath);
                case Failure():
                  copiedTemplate = copiedTemplate.copyWith(imageUrl: imageUrl);
              }
            } else {
              copiedTemplate = copiedTemplate.copyWith(imageUrl: imageUrl);
            }
          } else {
            copiedTemplate = copiedTemplate.copyWith(imageUrl: imageUrl);
          }
        }

        final saveResult = await _templateRepository.saveTemplate(copiedTemplate);
        switch (saveResult) {
          case Success():
            await loadTemplates();
            return copiedTemplate;
          case Failure(error: final err):
            emit(TemplateListError(err.message));
            return null;
        }
      case Failure(error: final err):
        emit(TemplateListError(err.message));
        return null;
    }
  }
}
