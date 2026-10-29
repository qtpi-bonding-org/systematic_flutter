// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'control_behavior.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ControlBehavior {
  ControlRole get role;
  bool? get selected;
  bool? get expanded;
  bool? get toggled;
  bool? get checked;
  bool get enabled;
  bool get liveRegion;

  /// Create a copy of ControlBehavior
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ControlBehaviorCopyWith<ControlBehavior> get copyWith =>
      _$ControlBehaviorCopyWithImpl<ControlBehavior>(
          this as ControlBehavior, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ControlBehavior;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ControlBehavior &&
            (identical(other.role, _this.role) || other.role == _this.role) &&
            (identical(other.selected, _this.selected) ||
                other.selected == _this.selected) &&
            (identical(other.expanded, _this.expanded) ||
                other.expanded == _this.expanded) &&
            (identical(other.toggled, _this.toggled) ||
                other.toggled == _this.toggled) &&
            (identical(other.checked, _this.checked) ||
                other.checked == _this.checked) &&
            (identical(other.enabled, _this.enabled) ||
                other.enabled == _this.enabled) &&
            (identical(other.liveRegion, _this.liveRegion) ||
                other.liveRegion == _this.liveRegion));
  }

  @override
  int get hashCode {
    final _this = this as ControlBehavior;
    return Object.hash(runtimeType, _this.role, _this.selected, _this.expanded,
        _this.toggled, _this.checked, _this.enabled, _this.liveRegion);
  }

  @override
  String toString() {
    final _this = this as ControlBehavior;
    return 'ControlBehavior(role: ${_this.role}, selected: ${_this.selected}, expanded: ${_this.expanded}, toggled: ${_this.toggled}, checked: ${_this.checked}, enabled: ${_this.enabled}, liveRegion: ${_this.liveRegion})';
  }
}

/// @nodoc
abstract mixin class $ControlBehaviorCopyWith<$Res> {
  factory $ControlBehaviorCopyWith(
          ControlBehavior value, $Res Function(ControlBehavior) _then) =
      _$ControlBehaviorCopyWithImpl;
  @useResult
  $Res call(
      {ControlRole role,
      bool? selected,
      bool? expanded,
      bool? toggled,
      bool? checked,
      bool enabled,
      bool liveRegion});
}

/// @nodoc
class _$ControlBehaviorCopyWithImpl<$Res>
    implements $ControlBehaviorCopyWith<$Res> {
  _$ControlBehaviorCopyWithImpl(this._self, this._then);

  final ControlBehavior _self;
  final $Res Function(ControlBehavior) _then;

  /// Create a copy of ControlBehavior
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? selected = freezed,
    Object? expanded = freezed,
    Object? toggled = freezed,
    Object? checked = freezed,
    Object? enabled = null,
    Object? liveRegion = null,
  }) {
    return _then(ControlBehavior(
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as ControlRole,
      selected: freezed == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool?,
      expanded: freezed == expanded
          ? _self.expanded
          : expanded // ignore: cast_nullable_to_non_nullable
              as bool?,
      toggled: freezed == toggled
          ? _self.toggled
          : toggled // ignore: cast_nullable_to_non_nullable
              as bool?,
      checked: freezed == checked
          ? _self.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool?,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      liveRegion: null == liveRegion
          ? _self.liveRegion
          : liveRegion // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ControlBehavior].
extension ControlBehaviorPatterns on ControlBehavior {
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
    TResult Function(_ControlBehavior value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior() when $default != null:
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
    TResult Function(_ControlBehavior value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior():
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
    TResult? Function(_ControlBehavior value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior() when $default != null:
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
    TResult Function(ControlRole role, bool? selected, bool? expanded,
            bool? toggled, bool? checked, bool enabled, bool liveRegion)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior() when $default != null:
        return $default(_that.role, _that.selected, _that.expanded,
            _that.toggled, _that.checked, _that.enabled, _that.liveRegion);
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
    TResult Function(ControlRole role, bool? selected, bool? expanded,
            bool? toggled, bool? checked, bool enabled, bool liveRegion)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior():
        return $default(_that.role, _that.selected, _that.expanded,
            _that.toggled, _that.checked, _that.enabled, _that.liveRegion);
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
    TResult? Function(ControlRole role, bool? selected, bool? expanded,
            bool? toggled, bool? checked, bool enabled, bool liveRegion)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ControlBehavior() when $default != null:
        return $default(_that.role, _that.selected, _that.expanded,
            _that.toggled, _that.checked, _that.enabled, _that.liveRegion);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ControlBehavior implements ControlBehavior {
  const _ControlBehavior(
      {required this.role,
      this.selected,
      this.expanded,
      this.toggled,
      this.checked,
      this.enabled = true,
      this.liveRegion = false})
      : assert(role != ControlRole.tab || selected != null,
            'A tab must say whether it is selected'),
        assert(role != ControlRole.switchToggle || toggled != null,
            'A switch must say whether it is on'),
        assert(role != ControlRole.checkbox || checked != null,
            'A checkbox must say whether it is checked'),
        assert(
            !liveRegion ||
                (role != ControlRole.status && role != ControlRole.alert),
            'status and alert roles are already announced; do not also set liveRegion');

  @override
  final ControlRole role;
  @override
  final bool? selected;
  @override
  final bool? expanded;
  @override
  final bool? toggled;
  @override
  final bool? checked;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final bool liveRegion;

  /// Create a copy of ControlBehavior
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ControlBehaviorCopyWith<_ControlBehavior> get copyWith =>
      __$ControlBehaviorCopyWithImpl<_ControlBehavior>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ControlBehavior &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.expanded, expanded) ||
                other.expanded == expanded) &&
            (identical(other.toggled, toggled) || other.toggled == toggled) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.liveRegion, liveRegion) ||
                other.liveRegion == liveRegion));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, role, selected, expanded, toggled, checked,
        enabled, liveRegion);
  }

  @override
  String toString() {
    return 'ControlBehavior(role: $role, selected: $selected, expanded: $expanded, toggled: $toggled, checked: $checked, enabled: $enabled, liveRegion: $liveRegion)';
  }
}

/// @nodoc
abstract mixin class _$ControlBehaviorCopyWith<$Res>
    implements $ControlBehaviorCopyWith<$Res> {
  factory _$ControlBehaviorCopyWith(
          _ControlBehavior value, $Res Function(_ControlBehavior) _then) =
      __$ControlBehaviorCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ControlRole role,
      bool? selected,
      bool? expanded,
      bool? toggled,
      bool? checked,
      bool enabled,
      bool liveRegion});
}

/// @nodoc
class __$ControlBehaviorCopyWithImpl<$Res>
    implements _$ControlBehaviorCopyWith<$Res> {
  __$ControlBehaviorCopyWithImpl(this._self, this._then);

  final _ControlBehavior _self;
  final $Res Function(_ControlBehavior) _then;

  /// Create a copy of ControlBehavior
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? role = null,
    Object? selected = freezed,
    Object? expanded = freezed,
    Object? toggled = freezed,
    Object? checked = freezed,
    Object? enabled = null,
    Object? liveRegion = null,
  }) {
    return _then(_ControlBehavior(
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as ControlRole,
      selected: freezed == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool?,
      expanded: freezed == expanded
          ? _self.expanded
          : expanded // ignore: cast_nullable_to_non_nullable
              as bool?,
      toggled: freezed == toggled
          ? _self.toggled
          : toggled // ignore: cast_nullable_to_non_nullable
              as bool?,
      checked: freezed == checked
          ? _self.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool?,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      liveRegion: null == liveRegion
          ? _self.liveRegion
          : liveRegion // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
