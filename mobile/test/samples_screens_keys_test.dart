import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:agua/features/auth/providers/auth_provider.dart';
import 'package:agua/features/samples/screens/history_screen.dart';
import 'package:agua/features/samples/screens/new_sample_screen.dart';
import 'package:agua/shared/models/models.dart';
import 'package:agua/shared/models/sample.dart';
import 'package:agua/shared/services/api_service.dart';

/// In-memory catalog: the bug lives in the widget tree, not in the network, and
/// `ApiService` is a plain class, so overriding the three getters the sample
/// screens call is enough to get both dropdowns into the same `Column`.
///
/// The catalog must be non-empty: that is the only branch that renders the
/// dropdowns at all, and the only branch where two keys can collide.
class _FakeApiService extends ApiService {
  _FakeApiService() : super(baseUrl: 'http://fake.invalid');

  static final List<AnalysisType> _types = <AnalysisType>[
    AnalysisType(
      id: 'type-ph',
      codigo: 'PH',
      nombre: 'pH',
      requiereDescripcion: false,
    ),
    AnalysisType(
      id: 'type-cloro',
      codigo: 'CLORO',
      nombre: 'Cloro residual',
      requiereDescripcion: false,
    ),
  ];

  // Only the keys the screens actually read.
  static final List<Map<String, dynamic>> _sources = <Map<String, dynamic>>[
    <String, dynamic>{'id': 'src-grifo', 'nombre': 'Grifo de cocina', 'tipo': 'GRIFO'},
    <String, dynamic>{'id': 'src-pozo', 'nombre': 'Pozo norte', 'tipo': 'POZO'},
  ];

  @override
  Future<List<AnalysisType>> getAnalysisTypes() async => _types;

  @override
  Future<List<Map<String, dynamic>>> getSampleSources() async => _sources;

  @override
  Future<List<SampleRecord>> getHistory({
    String? fuenteId,
    String? tipoAnalisisId,
    String? fechaDesde,
    String? fechaHasta,
  }) async =>
      <SampleRecord>[];
}

/// Mirrors `main()`: the screens read the api from the tree, never from a
/// global, so a `ChangeNotifierProvider` is all they need.
Widget _host(Widget screen) {
  final api = _FakeApiService();
  return ChangeNotifierProvider<AuthProvider>.value(
    value: AuthProvider(api: api),
    child: MaterialApp(home: screen),
  );
}

/// Pumps past the async catalog load.
///
/// `pumpAndSettle` is unusable here: the loading branch renders a
/// `CircularProgressIndicator`, which schedules frames forever, so settling
/// times out instead of reaching the non-empty branch the bug lives in.
Future<void> _pumpCatalogLoaded(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

/// Records the errors Flutter's error handler sees while a screen builds.
///
/// The duplicate-key assert is reported through `FlutterError.onError` from
/// inside the Column's build, and reporting it also aborts that build: by the
/// time the finders run, the subtree is already empty, so "the dropdowns are
/// missing" is the symptom, never the cause. Capturing it here lets the
/// assertion name the crash instead of only the wreckage.
///
/// The previous handler is called through, so the test binding still records
/// the error and `takeException()` keeps working.
class _BuildErrorRecorder {
  _BuildErrorRecorder() : _previous = FlutterError.onError {
    FlutterError.onError = _record;
  }

  final void Function(FlutterErrorDetails details)? _previous;
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];

  void _record(FlutterErrorDetails details) {
    errors.add(details);
    _previous?.call(details);
  }

  void dispose() => FlutterError.onError = _previous;

  Iterable<String> get messages =>
      errors.map((details) => '${details.exception}');
}

void _expectNoDuplicateKeyAssert(_BuildErrorRecorder recorder) {
  expect(
    recorder.messages.where((m) => m.contains('Duplicate keys found')),
    isEmpty,
    reason: 'the two dropdown keys must be namespaced',
  );
}

/// Asserts the screen is showing the loaded, non-empty branch: two dropdowns,
/// each backed by the whole fake catalog.
///
/// The items are the only proof the catalog actually arrived -- a
/// `DropdownButtonFormField` exposes no `items`, they are handed to the
/// `DropdownButton` it builds internally.
void _expectCatalogPopulated(WidgetTester tester) {
  expect(
    find.byType(DropdownButtonFormField<String>),
    findsNWidgets(2),
    reason: 'the two dropdowns must be siblings in the same Column',
  );

  final menus = tester
      .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
      .toList();
  expect(menus, hasLength(2));
  for (final menu in menus) {
    expect(menu.items, hasLength(2));
  }
}

/// The regression itself: the keys are built from selection state that is null
/// on the first render, so unless they are namespaced they are equal siblings
/// and the build trips Flutter's "Duplicate keys found" assert.
void _expectKeysAreNamespaced(WidgetTester tester) {
  final keys = tester
      .widgetList<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      )
      .map((dropdown) => dropdown.key)
      .toList();
  expect(keys.toSet(), hasLength(2), reason: 'sibling dropdown keys collided');
}

/// Regression tests for the "Duplicate keys found" crash.
///
/// Both sample screens keyed two `DropdownButtonFormField`s from selection
/// state that is null on the first render, and the keys were siblings in the
/// same `Column` -- so the non-empty-catalog build always hit two children with
/// the same key and threw. The fix namespaces the keys; these tests render both
/// screens with a populated catalog and fail if the two keys ever collide again.
void main() {
  testWidgets('NewSampleScreen renders both dropdowns without duplicate keys',
      (WidgetTester tester) async {
    final recorder = _BuildErrorRecorder();
    addTearDown(recorder.dispose);

    await tester.pumpWidget(_host(const NewSampleScreen()));
    await _pumpCatalogLoaded(tester);

    // The error checks come first, and therefore report first: the
    // duplicate-key assert also aborts the build, so the finders below would
    // otherwise blame the empty tree instead of the real cause.
    _expectNoDuplicateKeyAssert(recorder);
    expect(tester.takeException(), isNull);

    _expectCatalogPopulated(tester);
    _expectKeysAreNamespaced(tester);
  });

  testWidgets('HistoryScreen renders both filter dropdowns without duplicate keys',
      (WidgetTester tester) async {
    final recorder = _BuildErrorRecorder();
    addTearDown(recorder.dispose);

    await tester.pumpWidget(_host(const HistoryScreen()));
    await _pumpCatalogLoaded(tester);

    _expectNoDuplicateKeyAssert(recorder);
    expect(tester.takeException(), isNull);

    _expectCatalogPopulated(tester);
    _expectKeysAreNamespaced(tester);
  });
}
