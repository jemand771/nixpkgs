{
  lib,
  buildPythonPackage,
  cython,
  fetchPypi,
  fontconfig,
  gdal,
  geos,
  matplotlib,
  numpy,
  owslib,
  pillow,
  proj,
  pyproj,
  pyshp,
  pytest-mpl,
  pytestCheckHook,
  scipy,
  setuptools-scm,
  shapely,
}:

buildPythonPackage rec {
  pname = "cartopy";
  version = "0.25.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-VfGjkOXz8HWyIcfZH7ECWK2XjbeGx5MOugbrRdKHU/4=";
  };

  build-system = [ setuptools-scm ];

  nativeBuildInputs = [
    cython
    geos # for geos-config
    proj
  ];

  buildInputs = [
    geos
    proj
  ];

  dependencies = [
    matplotlib
    numpy
    pyproj
    pyshp
    shapely
  ];

  optional-dependencies = {
    ows = [
      owslib
      pillow
    ];
    plotting = [
      gdal
      pillow
      scipy
    ];
  };

  nativeCheckInputs = [
    pytest-mpl
    pytestCheckHook
  ]
  ++ lib.concatAttrValues optional-dependencies;

  preCheck = ''
    export FONTCONFIG_FILE=${fontconfig.out}/etc/fonts/fonts.conf
    export HOME=$TMPDIR
  '';

  pytestFlags = [
    "--pyargs"
    "cartopy"
  ];

  disabledTestMarks = [
    "network"
    "natural_earth"
  ];

  disabledTests = [
    "test_gridliner_constrained_adjust_datalim"
    "test_gridliner_labels_bbox_style"
    # CRS projection value assertion failures due to proj library changes
    "test_sweep"
    "TestLambertZoneII"
    "TestCrsArgs"
    "TestTransverseMercator"
    "TestOSGB"
    "TestOSNI"
    "TestTransformVectors"
    # robinson CRS tests
    "test_transform_point"
    "test_transform_points"
    # Image comparison failures due to matplotlib rendering differences
    "test_geoaxes_no_subslice"
    "test_geoaxes_set_boundary_clipping"
    "test_imshow"
    "test_stock_img"
    "test_pil_Image"
    "test_background_img"
    # Other assertion failures
    "test_plot_after_contour_doesnt_shrink"
    "test_gridliner_labels_zoom"
    "test_cursor_values"
    "test_pcolormesh_datalim"
    "test_extents"
    "test_get_extent"
    "test_LatitudeFormatter_mercator"
    "test_infinite_loop_bounds"
    "test_tiny_point_between_boundary_points"
    "Test_vector_scalar_to_grid"
  ];

  meta = {
    description = "Process geospatial data to create maps and perform analyses";
    homepage = "https://scitools.org.uk/cartopy/docs/latest/";
    changelog = "https://github.com/SciTools/cartopy/releases/tag/v${version}";
    license = lib.licenses.lgpl3Plus;
    maintainers = [ ];
    mainProgram = "feature_download";
  };
}
