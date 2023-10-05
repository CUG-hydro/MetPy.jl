@testset "test_wind_comps_basic" begin
  mask = [false, true, false, true, false, true, false, true, false]
  speed = array_type([4, 4, 4, 4, 25, 25, 25, 25, 10.0], "mph"; mask)
  dirs = array_type([0, 45, 90, 135, 180, 225, 270, 315, 360], "deg", mask=mask)

  u, v = wind_components(speed, dirs)

  s2 = sqrt(2)
  true_u = array_type([0, -4 / s2, -4, -4 / s2, 0, 25 / s2, 25, 25 / s2, 0],
    "mph"; mask)
  true_v = array_type([-4, -4 / s2, 0, 4 / s2, 25, 25 / s2, 0, -25 / s2, -10],
    "mph"; mask)

  assert_almost_equal(true_u, u, 6)
  assert_almost_equal(true_v, v, 6)
end


@testset "test_wind_comps_scalar" begin
  """Test wind components calculation with scalars."""
  u, v = wind_components(8 * units("m/s"), 150 * units.deg)
  assert_almost_equal(u, -4 * units("m/s"), 3)
  assert_almost_equal(v, 6.9282 * units("m/s"), 3)
end

@testset "test_speed" begin
  """Test calculating wind speed."""
  mask = [false, true, false, true]
  u = array_type([4.0, 2.0, 0.0, 0.0], "m/s", mask=mask)
  v = array_type([0.0, 2.0, 4.0, 0.0], "m/s", mask=mask)

  speed = wind_speed(u, v)

  s2 = numpy.sqrt(2.0)
  true_speed = array_type([4.0, 2 * s2, 4.0, 0.0], "m/s", mask=mask)

  assert_almost_equal(true_speed, speed, 4)
end

@testset "test_direction" begin
  """Test calculating wind direction."""
  # The last two (u, v) pairs and their masks test masking calm and negative directions
  mask = [false, true, false, true, true]
  u = array_type([4.0, 2.0, 0.0, 0.0, 1.0], "m/s", mask=mask)
  v = array_type([0.0, 2.0, 4.0, 0.0, -1], "m/s", mask=mask)

  direc = wind_direction(u, v)

  true_dir = array_type([270.0, 225.0, 180.0, 0.0, 315.0], "degree", mask=mask)

  assert_almost_equal(true_dir, direc, 4)
end



@testset "test_direction_with_north_and_calm" begin
  """Test how wind direction handles northerly and calm winds."""
  mask = [false, false, false, true]
  u = array_type([0.0, -0.0, 0.0, 1.0], "m/s", mask=mask)
  v = array_type([0.0, 0.0, -5.0, 1.0], "m/s", mask=mask)

  direc = wind_direction(u, v)

  true_dir = array_type([0.0, 0.0, 360.0, 225.0], "deg", mask=mask)

  assert_almost_equal(true_dir, direc, 4)
end


@testset "test_direction_dimensions" begin
  """Verify wind_direction returns degrees."""
  d = wind_direction(3.0 * units("m/s"), 4.0 * units("m/s"))
  # assert str(d.units) == "degree"
end

@testset "test_oceanographic_direction" begin
  """Test oceanographic direction (to) convention."""
  mask = [false, true, false]
  u = array_type([5.0, 5.0, 0.0], "m/s", mask=mask)
  v = array_type([-5.0, 0.0, 5.0], "m/s", mask=mask)

  direc = wind_direction(u, v, convention="to")
  true_dir = array_type([135.0, 90.0, 360.0], "deg", mask=mask)
  assert_almost_equal(direc, true_dir, 4)
end



# @testset "test_invalid_direction_convention" begin
#     """Test the error that is returned if the convention kwarg is not valid."""
#     with pytest.raises(ValueError):
#         wind_direction(1 * units("m/s"), 5 * units("m/s"), convention="test")
# end

@testset "test_speed_direction_roundtrip" begin
  """Test round-tripping between speed/direction and components."""
  # Test each quadrant of the whole circle
  wspd = numpy.array([15.0, 5.0, 2.0, 10.0]) * units.meters / units.seconds
  wdir = numpy.array([160.0, 30.0, 225.0, 350.0]) * units.degrees

  u, v = wind_components(wspd, wdir)

  wdir_out = wind_direction(u, v)
  wspd_out = wind_speed(u, v)

  assert_almost_equal(wspd, wspd_out, 4)
  assert_almost_equal(wdir, wdir_out, 4)
end

@testset "test_scalar_speed" begin
  """Test wind speed with scalars."""
  s = wind_speed(-3.0 * units("m/s"), -4.0 * units("m/s"))
  assert_almost_equal(s, 5.0 * units("m/s"), 3)
end

@testset "test_scalar_direction" begin
  """Test wind direction with scalars."""
  d = wind_direction(3.0 * units("m/s"), 4.0 * units("m/s"))
  assert_almost_equal(d, 216.870 * units.deg, 3)
end


@testset "test_windchill_invalid" begin
  """Test windchill for values that should be masked."""
  temp = numpy.array([10, 51, 49, 60, 80, 81]) * units.degF
  speed = numpy.array([4, 4, 3, 1, 10, 39]) * units.mph

  wc = windchill(temp, speed)

  # We don"t care about the masked values
  truth = units.Quantity(numpy.ma.array([2.6230789, numpy.nan, numpy.nan, numpy.nan, numpy.nan, numpy.nan],
      mask=[false, true, true, true, true, true]), units.degF)
  assert_almost_equal(truth, wc)
end

@testset "test_windchill_undefined_flag" begin
  """Test whether masking values for windchill can be disabled."""
  temp = units.Quantity(numpy.ma.array([49, 50, 49, 60, 80, 81]), units.degF)
  speed = units.Quantity(([4, 4, 3, 1, 10, 39]), units.mph)

  wc = windchill(temp, speed, mask_undefined=false)
  @test !hasproperty(wc, "mask")
  # mask = numpy.array([false] * 6)
  # assert_array_equal(wc.mask, mask)
end

@testset "test_windchill_scalar" begin
  """Test wind chill with scalars."""
  wc = windchill(-5 * units.degC, 35 * units("m/s"))
  assert_almost_equal(wc, -18.9357 * units.degC, 0)
end

@testset "test_windchill_basic" begin
  """Test the basic wind chill calculation."""
  temp = array_type([40, -10, -45, 20], "degF")
  speed = array_type([5, 55, 25, 15], "mph")

  wc = windchill(temp, speed)
  values = array_type([36, -46, -84, 6], "degF")
  assert_almost_equal(wc, values, 0)
end


@testset "test_windchill_face_level" begin
  """Test windchill using the face_level flag."""
  temp = numpy.array([20, 0, -20, -40]) * units.degF
  speed = numpy.array([15, 30, 45, 60]) * units.mph

  wc = windchill(temp, speed, face_level_winds=true)
  values = numpy.array([3, -30, -64, -98]) * units.degF
  assert_almost_equal(wc, values, 0)
end


@testset "test_heat_index_undefined_flag" begin
  """Test whether masking values can be disabled for heat index."""
  temp = units.Quantity(numpy.ma.array([80, 88, 92, 79, 30, 81]), units.degF)
  rh = units.Quantity(numpy.ma.array([40, 39, 2, 70, 50, 39]), units.percent)

  hi = heat_index(temp, rh, mask_undefined=false)
  @test !hasproperty(hi, "mask")
  # mask = numpy.array([false] * 6)
  # assert_array_equal(hi.mask, mask)
end

@testset "test_heat_index_invalid" begin
  """Test heat index for values that should be masked."""
  mask = [false, false, false, false, false, false]
  temp = array_type([80, 88, 92, 79, 30, 81], "degF", mask=mask)
  rh = array_type([40, 39, 2, 70, 50, 39], "percent", mask=mask)

  hi = heat_index(temp, rh)
  # if isinstance(hi, xr.DataArray):
  #     hi = hi.data
  true_mask = numpy.array([false, false, false, true, true, false])
  assert_array_equal(hi.mask, true_mask)
end


@testset "test_heat_index_basic" begin
  """Test the basic heat index calculation."""
  mask = [false, true, false, true, false]
  temp = array_type([80, 88, 92, 110, 86], "degF", mask=mask)
  rh = array_type([40, 100, 70, 40, 88], "percent", mask=mask)

  hi = heat_index(temp, rh)
  truth = array_type([80, 121, 112, 136, 104], "degF", mask=mask)
  assert_almost_equal(hi, truth, 0)
end

@testset "test_heat_index_scalar" begin
  """Test heat index using scalars."""
  hi = heat_index(96 * units.degF, 65 * units.percent)
  assert_almost_equal(hi, 121 * units.degF, 0)
end



@testset "test_heat_index_vs_nws" begin
  """Test heat_index against online calculated HI from NWS Website."""
  # https://www.wpc.ncep.noaa.gov/html/heatindex.shtml, visited 2019-Jul-17
  temp = units.Quantity(numpy.array([86, 111, 40, 96]), units.degF)
  rh = units.Quantity(numpy.array([45, 27, 99, 60]), units.percent)
  hi = heat_index(temp, rh)
  # Quantity mask not work
  truth = mask_array([87, 121, 40, 116], mask=[false, false, true, false], units.degF)
  assert_almost_equal(hi, truth, 0)
end

@testset "test_heat_index_kelvin" begin
  """Test heat_index when given Kelvin temperatures."""
  temp = 308.15 * units.degK
  rh = 0.7
  hi = heat_index(temp, rh)
  # NB rounded up test value here vs the above two tests
  assert_almost_equal(hi.to("degC"), 50.3406 * units.degC, 4)
end

@testset "test_height_to_geopotential" begin
  """Test conversion from height to geopotential."""
  mask = [false, true, false, true]
  height = array_type([0, 1000, 2000, 3000], "meter", mask=mask)
  geopot = height_to_geopotential(height)
  truth = array_type([0.0, 9805, 19607, 29406], "m**2 / second**2", mask=mask)
  assert_almost_equal(geopot, truth, 0)
end

# See #1075 regarding previous destructive cancellation in floating point
@testset "test_height_to_geopotential_32bit" begin
  """Test conversion to geopotential with 32-bit values."""
  heights = numpy.linspace(20597, 20598, 11, dtype=numpy.float32) * units.m
  truth = numpy.array([201336.64, 201337.62, 201338.6, 201339.58, 201340.55, 201341.53,
      201342.5, 201343.48, 201344.45, 201345.44, 201346.39],
    dtype=numpy.float32) * units("J/kg")
  assert_almost_equal(height_to_geopotential(heights), truth, 2)
end

@testset "test_geopotential_to_height" begin
  """Test conversion from geopotential to height."""
  mask = [false, true, false, true]
  geopotential = array_type(
    [0.0, 9805.11102602, 19607.14506998, 29406.10358006],
    "m**2 / second**2",
    mask=mask,
  )
  height = geopotential_to_height(geopotential)
  truth = array_type([0, 1000, 2000, 3000], "meter", mask=mask)
  assert_almost_equal(height, truth, 0)
end

# See #1075 regarding previous destructive cancellation in floating point
@testset "test_geopotential_to_height_32bit" begin
  """Test conversion from geopotential to height with 32-bit values."""
  geopot = numpy.arange(201590, 201600, dtype=numpy.float32) * units("J/kg")
  truth = numpy.array([20623.000, 20623.102, 20623.203, 20623.307, 20623.408,
      20623.512, 20623.615, 20623.717, 20623.820, 20623.924],
    dtype=numpy.float32) * units.m
  assert_almost_equal(geopotential_to_height(geopot), truth, 2)
end


@testset "test_heights_to_pressure_basic" begin
  """Test basic height to pressure calculation for standard atmosphere."""
  mask = [false, true, false, true]
  heights = array_type([321.5, 216.5, 487.6, 601.7], "meter", mask=mask)
  pressures = height_to_pressure_std(heights)
  values = array_type([975.2, 987.5, 956.0, 943.0], "mbar", mask=mask)
  assert_almost_equal(pressures, values, 1)
end

@testset "test_coriolis_force" begin
  """Test basic coriolis force calculation."""
  mask = [false, true, false, true, false]
  lat = array_type([-90.0, -30.0, 0.0, 30.0, 90.0], "degrees", mask=mask)
  cor = coriolis_parameter(lat)
  values = array_type([-1.4584232E-4, -.72921159E-4, 0, .72921159E-4,
      1.4584232E-4], "s^-1", mask=mask)
  assert_almost_equal(cor, values, 7)
end

@testset "test_add_height_to_pressure" begin
  """Test the pressure at height above pressure calculation."""
  mask = [false, true, false]
  pressure_in = array_type([1000.0, 900.0, 800.0], "hPa", mask=mask)
  height = array_type([877.17421094, 500.0, 300.0], "meter", mask=mask)
  pressure_out = add_height_to_pressure(pressure_in, height)
  truth = array_type([900.0, 846.725, 770.666], "hPa", mask=mask)
  assert_almost_equal(pressure_out, truth, 2)
end


@testset "test_coriolis_units" begin
  """Test that coriolis returns units of 1/second."""
  f = coriolis_parameter(50 * units.degrees)
  @assert f.units == units("1/second")
end


@testset "test_apparent_temperature_mask_undefined_true" begin
  """Test that apparent temperature works when mask_undefined is true."""
  temp = numpy.array([80, 55, 10]) * units.degF
  rh = numpy.array([40, 50, 25]) * units.percent
  wind = numpy.array([5, 4, 10]) * units("m/s")

  app_temperature = apparent_temperature(temp, rh, wind, mask_undefined=true)
  mask = [false, true, false]
  assert_almost_equal(app_temperature.mask, mask)
end

@testset "test_apparent_temperature_mask_undefined_false" begin
  """Test that apparent temperature works when mask_undefined is false."""
  temp = numpy.array([80, 55, 10]) * units.degF
  rh = numpy.array([40, 50, 25]) * units.percent
  wind = numpy.array([5, 4, 10]) * units("m/s")

  app_temperature = apparent_temperature(temp, rh, wind, mask_undefined=false)
  @test !hasproperty(app_temperature, "mask")
  # assert not hasattr(app_temperature, "mask")
end

@testset "test_apparent_temperature_scalar" begin
  """Test the apparent temperature calculation with a scalar."""
  temperature = 90 * units.degF
  rel_humidity = 60 * units.percent
  wind = 5 * units.mph
  truth = 99.6777178 * units.degF
  res = apparent_temperature(temperature, rel_humidity, wind)
  assert_almost_equal(res, truth, 6)
end

@testset "test_apparent_temperature_scalar_no_modification" begin
  """Test the apparent temperature calculation with a scalar that is NOOP."""
  temperature = 70 * units.degF
  rel_humidity = 60 * units.percent
  wind = 5 * units.mph
  truth = 70 * units.degF
  res = apparent_temperature(temperature, rel_humidity, wind, mask_undefined=false)
  assert_almost_equal(res, truth, 6)
end

@testset "test_apparent_temperature_windchill" begin
  """Test that apparent temperature works when a windchill is calculated."""
  temperature = -5.0 * units.degC
  rel_humidity = 50.0 * units.percent
  wind = 35.0 * units("m/s")
  truth = -18.9357 * units.degC
  res = apparent_temperature(temperature, rel_humidity, wind)
  assert_almost_equal(res, truth, 0)
end

@testset "test_windchill_kelvin" begin
  """Test wind chill when given Kelvin temperatures."""
  wc = windchill(268.15 * units.kelvin, 35 * units("m/s"))
  assert_almost_equal(wc.to("degC"), -18.9357 * units.degC, 0)
end

## 这里计算出现了bugs
@testset "test_heat_index_units" begin
  """Test units coming out of heat index."""
  temp = units.Quantity([35.0, 20.0], units.degC)
  rh = 70 * units.percent
  hi = heat_index(temp, rh)
  assert_almost_equal(hi.to("degC"), units.Quantity([50.3405, numpy.nan], units.degC), 4)
end


@testset "test_heat_index_ratio" begin
  """Test giving humidity as number [0, 1] to heat index."""
  temp = units.Quantity([35.0, 20.0], units.degC)
  rh = 0.7
  hi = heat_index(temp, rh)
  assert_almost_equal(hi.to("degC"), units.Quantity([50.3405, numpy.nan], units.degC), 4)
end


@testset "test_pressure_to_heights_basic" begin
  """Test basic pressure to height calculation for standard atmosphere."""
  mask = [false, true, false, true]
  pressures = array_type([975.2, 987.5, 956.0, 943.0], "mbar", mask=mask)
  heights = pressure_to_height_std(pressures)
  truth = array_type([321.5, 216.5, 487.6, 601.7], "meter", mask=mask)
  assert_almost_equal(heights, truth, 1)
end


@testset "test_pressure_to_heights_units" begin
  # """Test that passing non-mbar units works."""
  assert_almost_equal(pressure_to_height_std(29 * units.inHg).to("meter"), 262.8498 * units.meter, 3)
end


@testset "test_add_pressure_to_height" begin
  """Test the height at pressure above height calculation."""
  mask = [false, true, false]
  height_in = array_type([110.8286757, 250.0, 500.0], "meter", mask=mask)
  pressure = array_type([100.0, 200.0, 300.0], "hPa", mask=mask)
  height_out = add_pressure_to_height(height_in, pressure)
  truth = array_type([987.971601, 2114.957, 3534.348], "meter", mask=mask)
  assert_almost_equal(height_out, truth, 3)
end

@testset "test_sigma_to_pressure" begin
  """Test sigma_to_pressure."""
  surface_pressure = 1000.0 * units.hPa
  model_top_pressure = 0.0 * units.hPa
  sigma_values = numpy.arange(0.0, 1.1, 0.1)


  mask = falses(size(sigma_values))
  mask[1:2:end] .= true

  sigma = array_type(sigma_values, "", mask=mask)
  expected = array_type(numpy.arange(0.0, 1100.0, 100.0), "hPa", mask=mask)
  pressure = sigma_to_pressure(sigma, surface_pressure, model_top_pressure)
  assert_almost_equal(pressure, expected, 5)
end

@testset "test_apparent_temperature" begin
  """Test the apparent temperature calculation."""
  temperature = array_type([[90, 90, 70],
      [20, 20, 60]], "degF")
  rel_humidity = array_type([[60, 20, 60],
      [10, 10, 10]], "percent")
  wind = array_type([[5, 3, 3],
      [10, 1, 10]], "mph")

  truth = mask_array([[99.6777178, 86.3357671, 70], [8.8140662, 20, 60]],
    mask=[[false, false, true], [false, true, true]],
    units.degF)
  res = apparent_temperature(temperature, rel_humidity, wind)
  assert_almost_equal(res, truth, 6)
end

@testset "test_smooth_gaussian" begin
  """Test the smooth_gaussian function with a larger n."""
  m = 10
  s = zeros((m, m))
  inds = CartesianIndices(s)
  for i in inds
    s[i] = i[1] - 1 + (i[2] - 1)^2
  end
  mask = falses(size(s))
  mask[1:2:end, 1:2:end] .= 1
  scalar_grid = array_type(s, "", mask=mask)

  s_actual = smooth_gaussian(scalar_grid, 4)
  s_true = array_type([
      [0.40077472 1.59215426 4.59665817 9.59665817 16.59665817 25.59665817 36.59665817 49.59665817 64.51108392 77.87487258]
      [1.20939518 2.40077472 5.40527863 10.40527863 17.40527863 26.40527863 37.40527863 50.40527863 65.31970438 78.68349304]
      [2.20489127 3.39627081 6.40077472 11.40077472 18.40077472 27.40077472 38.40077472 51.40077472 66.31520047 79.67898913]
      [3.20489127 4.39627081 7.40077472 12.40077472 19.40077472 28.40077472 39.40077472 52.40077472 67.31520047 80.67898913]
      [4.20489127 5.39627081 8.40077472 13.40077472 20.40077472 29.40077472 40.40077472 53.40077472 68.31520047 81.67898913]
      [5.20489127 6.39627081 9.40077472 14.40077472 21.40077472 30.40077472 41.40077472 54.40077472 69.31520047 82.67898913]
      [6.20489127 7.39627081 10.40077472 15.40077472 22.40077472 31.40077472 42.40077472 55.40077472 70.31520047 83.67898913]
      [7.20489127 8.39627081 11.40077472 16.40077472 23.40077472 32.40077472 43.40077472 56.40077472 71.31520047 84.67898913]
      [8.20038736 9.3917669 12.39627081 17.39627081 24.39627081 33.39627081 44.39627081 57.39627081 72.31069656 85.67448522]
      [9.00900782 10.20038736 13.20489127 18.20489127 25.20489127 34.20489127 45.20489127 58.20489127 73.11931702 86.48310568]],
    "", mask=mask)
  assert_almost_equal(s_actual, s_true)
end

@testset "test_smooth_gaussian_small_n" begin
  """Test the smooth_gaussian function with a smaller n."""
  m = 5
  s = zeros(m, m)
  inds = CartesianIndices((5, 5))
  for i in inds
    s[i] = i[1] - 1 + (i[2] - 1)^2
  end

  s = smooth_gaussian(s, 1)
  s_true = [[0.0141798077, 1.02126971, 4.02126971, 9.02126971, 15.9574606],
    [1.00708990, 2.01417981, 5.01417981, 10.0141798, 16.9503707],
    [2.00708990, 3.01417981, 6.01417981, 11.0141798, 17.9503707],
    [3.00708990, 4.01417981, 7.01417981, 12.0141798, 18.9503707],
    [4.00000000, 5.00708990, 8.00708990, 13.0070899, 19.9432808]
  ] |> x -> hcat(x...) |> transpose
  assert_almost_equal(s.m, s_true)
end

@testset "test_smooth_gaussian_3d_units" begin
  """Test the smooth_gaussian function with units and a 3D array."""
  m = 5
  s = zeros((3, m, m))
  inds = CartesianIndices(s)
  for i in inds
    s[i] = i[2] - 1 + (i[3] - 1)^2
  end
  s[1:2:end, :, :] .= 10 * s[1:2:end, :, :]
  s

  s = s * units("m")
  s = smooth_gaussian(s, 1)
  s_true = ([[0.0141798077 1.02126971 4.02126971 9.02126971 15.9574606]
    [1.00708990 2.01417981 5.01417981 10.0141798 16.9503707]
    [2.00708990 3.01417981 6.01417981 11.0141798 17.9503707]
    [3.00708990 4.01417981 7.01417981 12.0141798 18.9503707]
    [4.00000000 5.00708990 8.00708990 13.0070899 19.9432808]]) * units("m")
  assert_almost_equal(s.m[2, :, :], s_true.m)
end

@testset "test_smooth_n_pt_5" begin
  """Test the smooth_n_pt function using 5 points."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  mask = numpy.zeros_like(hght)
  mask[1:2:end, 1:2:end] .= 1
  hght = array_type(hght, "", mask=mask)

  shght = smooth_n_point(hght, 5, 1)
  s_true = array_type([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5675.75, 5666.375, 5658.875, 5651.0],
      [5728.0, 5711.5, 5692.75, 5677.75, 5662.0],
      [5772.0, 5747.25, 5719.125, 5696.625, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]], "")
  assert_almost_equal(shght, s_true)
end

@testset "test_smooth_n_pt_5_units" begin
  """Test the smooth_n_pt function using 5 points with units."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]]) * units.meter
  shght = smooth_n_point(hght, 5, 1)
  s_true = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5675.75, 5666.375, 5658.875, 5651.0],
    [5728.0, 5711.5, 5692.75, 5677.75, 5662.0],
    [5772.0, 5747.25, 5719.125, 5696.625, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]]) * units.meter
  assert_almost_equal(shght, s_true)
end

@testset "test_smooth_n_pt_9_units" begin
  """Test the smooth_n_pt function using 9 points with units."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]]) * units.meter
  shght = smooth_n_point(hght, 9, 1)
  s_true = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5675.5, 5666.75, 5658.75, 5651.0],
    [5728.0, 5711.0, 5693.5, 5677.5, 5662.0],
    [5772.0, 5746.5, 5720.25, 5696.25, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]]) * units.meter
  assert_almost_equal(shght, s_true)
end

@testset "test_smooth_n_pt_9_repeat" begin
  """Test the smooth_n_pt function using 9 points with two passes."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  shght = smooth_n_point(hght, 9, 2)
  s_true = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5675.4375, 5666.9375, 5658.8125, 5651.0],
    [5728.0, 5710.875, 5693.875, 5677.625, 5662.0],
    [5772.0, 5746.375, 5720.625, 5696.375, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  assert_almost_equal(shght.m, s_true)
end

# @testset "test_smooth_n_pt_wrong_number" begin
#     """Test the smooth_n_pt function using wrong number of points."""
#     hght = numpy.array([[5640., 5640., 5640., 5640., 5640.],
#                      [5684., 5676., 5666., 5659., 5651.],
#                      [5728., 5712., 5692., 5678., 5662.],
#                      [5772., 5748., 5718., 5697., 5673.],
#                      [5816., 5784., 5744., 5716., 5684.]])
#     with pytest.raises(ValueError):
#         smooth_n_point(hght, 7)
# end

@testset "test_smooth_n_pt_3d_units" begin
  """Test the smooth_n_point function with a 3D array with units."""
  hght = [[[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
      [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
      [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]],
    [[6768.0, 6768.0, 6768.0, 6768.0, 6768.0],
      [6820.8, 6811.2, 6799.2, 6790.8, 6781.2],
      [6873.6, 6854.4, 6830.4, 6813.6, 6794.4],
      [6926.4, 6897.6, 6861.6, 6836.4, 6807.6],
      [6979.2, 6940.8, 6892.8, 6859.2, 6820.8]]] * units.m
  shght = smooth_n_point(hght, 9, 2)
  s_true = [[[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5675.4375, 5666.9375, 5658.8125, 5651.0],
      [5728.0, 5710.875, 5693.875, 5677.625, 5662.0],
      [5772.0, 5746.375, 5720.625, 5696.375, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]],
    [[6768.0, 6768.0, 6768.0, 6768.0, 6768.0],
      [6820.8, 6810.525, 6800.325, 6790.575, 6781.2],
      [6873.6, 6853.05, 6832.65, 6813.15, 6794.4],
      [6926.4, 6895.65, 6864.75, 6835.65, 6807.6],
      [6979.2, 6940.8, 6892.8, 6859.2, 6820.8]]] * units.m
  assert_almost_equal(shght, s_true)
end

@testset "test_smooth_n_pt_temperature" begin
  """Test the smooth_n_pt function with temperature units."""
  t = numpy.array([[2.73, 3.43, 6.53, 7.13, 4.83],
    [3.73, 4.93, 6.13, 6.63, 8.23],
    [3.03, 4.83, 6.03, 7.23, 7.63],
    [3.33, 4.63, 7.23, 6.73, 6.23],
    [3.93, 3.03, 7.43, 9.23, 9.23]]) * units.degC

  smooth_t = smooth_n_point(t, 9, 1)
  smooth_t_true = numpy.array([[2.73, 3.43, 6.53, 7.13, 4.83],
    [3.73, 4.6425, 5.96125, 6.81124, 8.23],
    [3.03, 4.81125, 6.1175, 6.92375, 7.63],
    [3.33, 4.73625, 6.43, 7.3175, 6.23],
    [3.93, 3.03, 7.43, 9.23, 9.23]]) * units.degC
  assert_almost_equal(smooth_t, smooth_t_true, 4)
end

@testset "test_smooth_gaussian_temperature" begin
  """Test the smooth_gaussian function with temperature units."""
  t = numpy.array([[2.73, 3.43, 6.53, 7.13, 4.83],
    [3.73, 4.93, 6.13, 6.63, 8.23],
    [3.03, 4.83, 6.03, 7.23, 7.63],
    [3.33, 4.63, 7.23, 6.73, 6.23],
    [3.93, 3.03, 7.43, 9.23, 9.23]]) * units.degC

  smooth_t = smooth_gaussian(t, 3)
  smooth_t_true = numpy.array([[2.8892, 3.7657, 6.2805, 6.8532, 5.3174],
    [3.6852, 4.799, 6.0844, 6.7816, 7.7617],
    [3.2762, 4.787, 6.117, 7.0792, 7.5181],
    [3.4618, 4.6384, 6.886, 6.982, 6.6653],
    [3.8115, 3.626, 7.1705, 8.8528, 8.9605]]) * units.degC
  assert_almost_equal(smooth_t, smooth_t_true, 4)
end

@testset "test_smooth_window" begin
  """Test smooth_window with default configuration."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  mask = numpy.zeros_like(hght)
  mask[1:2:end, 1:2:end] .= 1
  hght = array_type(hght, "meter", mask=mask)

  smoothed = smooth_window(hght, numpy.array([[1, 0, 1], [0, 0, 0], [1, 0, 1]]))
  truth = array_type([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5675.0, 5667.5, 5658.5, 5651.0],
      [5728.0, 5710.0, 5695.0, 5677.0, 5662.0],
      [5772.0, 5745.0, 5722.5, 5695.5, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]], "meter")
  assert_almost_equal(smoothed, truth)
end

# @testset "test_smooth_window_1d_dataarray" begin
#     """Test smooth_window on 1D DataArray."""
#     temperature = xr.DataArray(
#         [37., 32., 34., 29., 28., 24., 26., 24., 27., 30.],
#         dims=("time",),
#         coords={"time": pd.date_range("2020-01-01", periods=10, freq="H")},
#         attrs={"units": "degF"})
#     smoothed = smooth_window(temperature, window=numpy.ones(3) / 3, normalize_weights=false)
#     truth = xr.DataArray(
#         [37., 34.33333333, 31.66666667, 30.33333333, 27., 26., 24.66666667,
#          25.66666667, 27., 30.] * units.degF,
#         dims=("time",),
#         coords={"time": pd.date_range("2020-01-01", periods=10, freq="H")}
#     )
#     xr.testing.assert_allclose(smoothed, truth)
# end

@testset "test_smooth_rectangular" begin
  """Test smooth_rectangular with default configuration."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  mask = numpy.zeros_like(hght)
  mask[1:2:end, 1:2:end] .= 1
  hght = array_type(hght, "meter", mask=mask)

  smoothed = smooth_rectangular(hght, (5, 3))
  truth = array_type([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
      [5728.0, 5710.66667, 5694.0, 5677.33333, 5662.0],
      [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]], "meter")
  assert_almost_equal(smoothed, truth, 4)
end

@testset "test_smooth_circular" begin
  """Test smooth_circular with default configuration."""
  hght = numpy.array([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
    [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
    [5728.0, 5712.0, 5692.0, 5678.0, 5662.0],
    [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
    [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]])
  mask = numpy.zeros_like(hght)
  mask[1:2:end, 1:2:end] .= 1
  hght = array_type(hght, "meter", mask=mask)

  smoothed = smooth_circular(hght, 2, 2)
  truth = array_type([[5640.0, 5640.0, 5640.0, 5640.0, 5640.0],
      [5684.0, 5676.0, 5666.0, 5659.0, 5651.0],
      [5728.0, 5712.0, 5693.98817, 5678.0, 5662.0],
      [5772.0, 5748.0, 5718.0, 5697.0, 5673.0],
      [5816.0, 5784.0, 5744.0, 5716.0, 5684.0]], "meter")
  assert_almost_equal(smoothed, truth, 4)
end

# @testset "test_smooth_window_with_bad_window" begin
#     """Test smooth_window with a bad window size."""
#     temperature = [37, 32, 34, 29, 28, 24, 26, 24, 27, 30] * units.degF
#     with pytest.raises(ValueError) as exc:
#         smooth_window(temperature, numpy.ones(4))
#     assert "must be odd in all dimensions" in str(exc)
# end

@testset "test_altimeter_to_station_pressure_inhg" begin
  """Test the altimeter to station pressure function with inches of mercury."""
  altim = 29.8 * units.inHg
  elev = 500 * units.m
  res = altimeter_to_station_pressure(altim, elev)
  truth = 950.96498 * units.hectopascal
  assert_almost_equal(res, truth, 3)
end

@testset "test_altimeter_to_station_pressure_hpa" begin
  """Test the altimeter to station pressure function with hectopascals."""
  mask = [false, true, false, true]
  altim = array_type([1000.0, 1005.0, 1010.0, 1013.0], "hectopascal", mask=mask)
  elev = array_type([2000.0, 1500.0, 1000.0, 500.0], "meter", mask=mask)
  res = altimeter_to_station_pressure(altim, elev)
  truth = array_type(
    [784.262996, 838.651657, 896.037821, 954.639265], "hectopascal", mask=mask
  )
  assert_almost_equal(res, truth, 3)
end

@testset "test_altimiter_to_sea_level_pressure_inhg" begin
  """Test the altimeter to sea level pressure function with inches of mercury."""
  altim = 29.8 * units.inHg
  elev = 500 * units.m
  temp = 30 * units.degC
  res = altimeter_to_sea_level_pressure(altim, elev, temp)
  truth = 1006.089 * units.hectopascal
  assert_almost_equal(res, truth, 3)
end

@testset "test_altimeter_to_sea_level_pressure_hpa" begin
  """Test the altimeter to sea level pressure function with hectopascals."""
  mask = [false, true, false, true]
  altim = array_type([1000.0, 1005.0, 1010.0, 1013], "hectopascal", mask=mask)
  elev = array_type([2000.0, 1500.0, 1000.0, 500.0], "meter", mask=mask)
  temp = array_type([-3.0, -2.0, -1.0, 0.0], "degC")
  res = altimeter_to_sea_level_pressure(altim, elev, temp)
  truth = array_type(
    [1009.963556, 1013.119712, 1015.885392, 1016.245615], "hectopascal", mask=mask
  )
  assert_almost_equal(res, truth, 3)
end
