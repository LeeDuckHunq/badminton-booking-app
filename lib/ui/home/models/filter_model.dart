// lib/ui/home/models/filter_model.dart

class FilterModel {

  final int? openBeforeHour;
  final int? closeAfterHour;

  const FilterModel({
    this.openBeforeHour,
    this.closeAfterHour,
  });

  bool get isEmpty => openBeforeHour == null && closeAfterHour == null;

  FilterModel copyWith({
    int? openBeforeHour,
    int? closeAfterHour,
    bool clearOpen = false,
    bool clearClose = false,
  }) {
    return FilterModel(
      openBeforeHour: clearOpen ? null : openBeforeHour ?? this.openBeforeHour,
      closeAfterHour: clearClose ? null : closeAfterHour ?? this.closeAfterHour,
    );
  }
}