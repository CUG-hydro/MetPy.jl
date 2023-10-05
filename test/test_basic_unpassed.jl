# @testset "test_zoom_xarray" begin
#     """Test zoom_xarray on 2D DataArray."""
#     data = xr.open_dataset(get_test_data("GFS_test.nc", false))
#     data = data.metpy.parse_cf()
#     hght = data.Geopotential_height_isobaric[0, 15, ::25, ::50]
#     zoomed = zoom_xarray(hght, 3)
#     truth = xr.DataArray(
#         [[3977.05, 3973.2676, 3965.3857, 3958.6035, 3958.12, 3967.2178, 3981.5144, 3994.7114,
#           4000.51],
#          [4014.1333, 4005.9824, 3988.5469, 3972.3525, 3967.9253, 3982.075, 4006.7507, 4030.185,
#           4040.6113],
#          [4102.5625, 4083.995, 4043.7776, 4005.1387, 3991.3066, 4017.5037, 4066.9292, 4114.776,
#           4136.238],
#          [4208.1074, 4177.107, 4109.698, 4044.2705, 4019.2134, 4059.7896, 4138.7554, 4215.7397,
#           4250.3726],
#          [4296.5366, 4255.1196, 4164.9287, 4077.0566, 4042.5947, 4095.2183, 4198.9336,
#           4300.3306, 4345.9985],
#          [4333.62, 4287.8345, 4188.09, 4090.8057, 4052.4, 4110.0757, 4224.17, 4335.804,
#           4386.1]],
#         dims=("lat", "lon"),
#         coords={"lat": [65., 62.4, 56.2, 48.8, 42.6, 40.],
#                 "lon": [210., 214.29688, 225.625, 241.64062, 260., 278.35938, 294.375,
#                         305.70312, 310.],
#                 "metpy_crs": hght.metpy_crs},
#         attrs=hght.attrs
#     )
#     xr.testing.assert_allclose(zoomed, truth)


# @testset "test_warning_dir" begin
#     """Test that warning is raised wind direction > 2Pi."""
#     with pytest.warns(UserWarning):
#         wind_components(3. * units("m/s"), 270)
# end

# @testset "test_coriolis_warning" begin
#     """Test that warning is raise when latitude larger than pi radians."""
#     with pytest.warns(UserWarning):
#         coriolis_parameter(50)
#     with pytest.warns(UserWarning):
#         coriolis_parameter(-50)
# end
