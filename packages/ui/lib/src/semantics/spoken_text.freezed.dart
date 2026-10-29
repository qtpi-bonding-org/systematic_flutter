// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spoken_text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpokenText {
  Label get label;

  /// What activating the control will do, when the label alone is not enough.
  Label? get hint;

  /// Current value, for controls that have one (a slider, a progress count).
  Label? get value;

  /// Create a copy of SpokenText
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SpokenTextCopyWith<SpokenText> get copyWith =>
      _$SpokenTextCopyWithImpl<SpokenText>(this as SpokenText, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as SpokenText;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SpokenText &&
            (identical(other.label, _this.label) ||
                other.label == _this.label) &&
            (identical(other.hint, _this.hint) || other.hint == _this.hint) &&
            (identical(other.value, _this.value) ||
                other.value == _this.value));
  }

  @override
  int get hashCode {
    final _this = this as SpokenText;
    return Object.hash(runtimeType, _this.label, _this.hint, _this.value);
  }

  @override
  String toString() {
    final _this = this as SpokenText;
    return 'SpokenText(label: ${_this.label}, hint: ${_this.hint}, value: ${_this.value})';
  }
}

/// @nodoc
abstract mixin class $SpokenTextCopyWith<$Res> {
  factory $SpokenTextCopyWith(
          SpokenText value, $Res Function(SpokenText) _then) =
      _$SpokenTextCopyWithImpl;
  @useResult
  $Res call({Label label, Label? hint, Label? value});
}

/// @nodoc
class _$SpokenTextCopyWithImpl<$Res> implements $SpokenTextCopyWith<$Res> {
  _$SpokenTextCopyWithImpl(this._self, this._then);

  final SpokenText _self;
  final $Res Function(SpokenText) _then;

  /// Create a copy of SpokenText
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? hint = freezed,
    Object? value = freezed,
  }) {
    return _then(SpokenText(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as Label,
      hint: freezed == hint
          ? _self.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as Label?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Label?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SpokenText].
extension SpokenTextPatterns on SpokenText {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SpokenText value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SpokenText() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SpokenText value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SpokenText():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SpokenText value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SpokenText() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Label label, Label? hint, Label? value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SpokenText() when $default != null:
        return $default(_that.label, _that.hint, _that.value);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Label label, Label? hint, Label? value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SpokenText():
        return $default(_that.label, _that.hint, _that.value);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Label label, Label? hint, Label? value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SpokenText() when $default != null:
        return $default(_that.label, _that.hint, _that.value);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SpokenText implements SpokenText {
  const _SpokenText({required this.label, this.hint, this.value});

  @override
  final Label label;

  /// What activating the control will do, when the label alone is not enough.
  @override
  final Label? hint;

  /// Current value, for controls that have one (a slider, a progress count).
  @override
  final Label? value;

  /// Create a copy of SpokenText
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SpokenTextCopyWith<_SpokenText> get copyWith =>
      __$SpokenTextCopyWithImpl<_SpokenText>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SpokenText &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, label, hint, value);
  }

  @override
  String toString() {
    return 'SpokenText(label: $label, hint: $hint, value: $value)';
  }
}

/// @nodoc
abstract mixin class _$SpokenTextCopyWith<$Res>
    implements $SpokenTextCopyWith<$Res> {
  factory _$SpokenTextCopyWith(
          _SpokenText value, $Res Function(_SpokenText) _then) =
      __$SpokenTextCopyWithImpl;
  @override
  @useResult
  $Res call({Label label, Label? hint, Label? value});
}

/// @nodoc
class __$SpokenTextCopyWithImpl<$Res> implements _$SpokenTextCopyWith<$Res> {
  __$SpokenTextCopyWithImpl(this._self, this._then);

  final _SpokenText _self;
  final $Res Function(_SpokenText) _then;

  /// Create a copy of SpokenText
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? label = null,
    Object? hint = freezed,
    Object? value = freezed,
  }) {
    return _then(_SpokenText(
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as Label,
      hint: freezed == hint
          ? _self.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as Label?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Label?,
    ));
  }
}

// dart format on
