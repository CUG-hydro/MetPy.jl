
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



@testset "test_windchill_kelvin" begin
    """Test wind chill when given Kelvin temperatures."""
    wc = windchill(268.15 * units.kelvin, 35 * units("m/s"))
    assert_almost_equal(wc, -18.9357 * units.degC, 0)
end

@testset "test_windchill_undefined_flag" begin
  """Test whether masking values for windchill can be disabled."""
  temp = units.Quantity(numpy.ma.array([49, 50, 49, 60, 80, 81]), units.degF)
  speed = units.Quantity(([4, 4, 3, 1, 10, 39]), units.mph)

  wc = windchill(temp, speed, mask_undefined=false)
  mask = numpy.array([false] * 6)
  assert_array_equal(wc.mask, mask)
end





@testset "test_heat_index_invalid" begin
    """Test heat index for values that should be masked."""
    mask = [false, false, false, false, false, false]
    temp = array_type([80, 88, 92, 79, 30, 81], "degF", mask=mask)
    rh = array_type([40, 39, 2, 70, 50, 39], "percent", mask=mask)

    hi = heat_index(temp, rh)
    if isinstance(hi, xr.DataArray):
        hi = hi.data
    true_mask = numpy.array([false, false, false, true, true, false])
    assert_array_equal(hi.mask, true_mask)
end

@testset "test_heat_index_undefined_flag" begin
    """Test whether masking values can be disabled for heat index."""
    temp = units.Quantity(numpy.ma.array([80, 88, 92, 79, 30, 81]), units.degF)
    rh = units.Quantity(numpy.ma.array([40, 39, 2, 70, 50, 39]), units.percent)

    hi = heat_index(temp, rh, mask_undefined=false)
    mask = numpy.array([false] * 6)
    assert_array_equal(hi.mask, mask)
end


@testset "test_heat_index_units" begin
    """Test units coming out of heat index."""
    temp = units.Quantity([35., 20.], units.degC)
    rh = 70 * units.percent
    hi = heat_index(temp, rh)
    assert_almost_equal(hi.to("degC"), units.Quantity([50.3405, numpy.nan], units.degC), 4)
end


@testset "test_heat_index_ratio" begin
    """Test giving humidity as number [0, 1] to heat index."""
    temp = units.Quantity([35., 20.], units.degC)
    rh = 0.7
    hi = heat_index(temp, rh)
    assert_almost_equal(hi.to("degC"), units.Quantity([50.3405, numpy.nan], units.degC), 4)
end


@testset "test_pressure_to_heights_basic" begin
    """Test basic pressure to height calculation for standard atmosphere."""
    mask = [false, true, false, true]
    pressures = array_type([975.2, 987.5, 956., 943.], "mbar", mask=mask)
    heights = pressure_to_height_std(pressures)
    values = array_type([321.5, 216.5, 487.6, 601.7], "meter", mask=mask)
    assert_almost_equal(heights, values, 1)
end


@testset "test_pressure_to_heights_units" begin
    """Test that passing non-mbar units works."""
    assert_almost_equal(pressure_to_height_std(29 * units.inHg), 262.8498 * units.meter, 3)
end


@testset "test_add_pressure_to_height" begin
    """Test the height at pressure above height calculation."""
    mask = [false, true, false]
    height_in = array_type([110.8286757, 250., 500.], "meter", mask=mask)
    pressure = array_type([100., 200., 300.], "hPa", mask=mask)
    height_out = add_pressure_to_height(height_in, pressure)
    truth = array_type([987.971601, 2114.957, 3534.348], "meter", mask=mask)
    assert_almost_equal(height_out, truth, 3)
end



@testset "test_sigma_to_pressure" begin
    """Test sigma_to_pressure."""
    surface_pressure = 1000. * units.hPa
    model_top_pressure = 0. * units.hPa
    sigma_values = numpy.arange(0., 1.1, 0.1)
    mask = numpy.zeros_like(sigma_values)[::2] = 1
    sigma = array_type(sigma_values, "", mask=mask)
    expected = array_type(numpy.arange(0., 1100., 100.), "hPa", mask=mask)
    pressure = sigma_to_pressure(sigma, surface_pressure, model_top_pressure)
    assert_almost_equal(pressure, expected, 5)
end

@testset "test_warning_dir" begin
    """Test that warning is raised wind direction > 2Pi."""
    with pytest.warns(UserWarning):
        wind_components(3. * units("m/s"), 270)
end



@testset "test_coriolis_warning" begin
    """Test that warning is raise when latitude larger than pi radians."""
    with pytest.warns(UserWarning):
        coriolis_parameter(50)
    with pytest.warns(UserWarning):
        coriolis_parameter(-50)
end


@testset "test_apparent_temperature" begin
    """Test the apparent temperature calculation."""
    temperature = array_type([[90, 90, 70],
                              [20, 20, 60]], "degF")
    rel_humidity = array_type([[60, 20, 60],
                               [10, 10, 10]], "percent")
    wind = array_type([[5, 3, 3],
                       [10, 1, 10]], "mph")

    truth = units.Quantity(numpy.ma.array([[99.6777178, 86.3357671, 70], [8.8140662, 20, 60]],
                                       mask=[[false, false, true], [false, true, true]]),
                           units.degF)
    res = apparent_temperature(temperature, rel_humidity, wind)
    assert_almost_equal(res, truth, 6)
end

@testset "test_zoom_xarray" begin
    """Test zoom_xarray on 2D DataArray."""
    data = xr.open_dataset(get_test_data("GFS_test.nc", false))
    data = data.metpy.parse_cf()
    hght = data.Geopotential_height_isobaric[0, 15, ::25, ::50]
    zoomed = zoom_xarray(hght, 3)
    truth = xr.DataArray(
        [[3977.05, 3973.2676, 3965.3857, 3958.6035, 3958.12, 3967.2178, 3981.5144, 3994.7114,
          4000.51],
         [4014.1333, 4005.9824, 3988.5469, 3972.3525, 3967.9253, 3982.075, 4006.7507, 4030.185,
          4040.6113],
         [4102.5625, 4083.995, 4043.7776, 4005.1387, 3991.3066, 4017.5037, 4066.9292, 4114.776,
          4136.238],
         [4208.1074, 4177.107, 4109.698, 4044.2705, 4019.2134, 4059.7896, 4138.7554, 4215.7397,
          4250.3726],
         [4296.5366, 4255.1196, 4164.9287, 4077.0566, 4042.5947, 4095.2183, 4198.9336,
          4300.3306, 4345.9985],
         [4333.62, 4287.8345, 4188.09, 4090.8057, 4052.4, 4110.0757, 4224.17, 4335.804,
          4386.1]],
        dims=("lat", "lon"),
        coords={"lat": [65., 62.4, 56.2, 48.8, 42.6, 40.],
                "lon": [210., 214.29688, 225.625, 241.64062, 260., 278.35938, 294.375,
                        305.70312, 310.],
                "metpy_crs": hght.metpy_crs},
        attrs=hght.attrs
    )
    xr.testing.assert_allclose(zoomed, truth)

@testset "test_apparent_temperature_mask_undefined_false" begin
    """Test that apparent temperature works when mask_undefined is false."""
    temp = numpy.array([80, 55, 10]) * units.degF
    rh = numpy.array([40, 50, 25]) * units.percent
    wind = numpy.array([5, 4, 10]) * units("m/s")

    app_temperature = apparent_temperature(temp, rh, wind, mask_undefined=false)
    assert not hasattr(app_temperature, "mask")
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
