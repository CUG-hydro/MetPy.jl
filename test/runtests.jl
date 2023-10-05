# using Conda
# using PyCall
# import PyCall: @py_str
using Test
using MetPy
using UnPack

init_metpy()
# @unpack metpy.calc
@unpack add_height_to_pressure, add_pressure_to_height,
altimeter_to_sea_level_pressure, altimeter_to_station_pressure,
apparent_temperature, coriolis_parameter, geopotential_to_height,
heat_index, height_to_geopotential, height_to_pressure_std,
pressure_to_height_std, sigma_to_pressure, smooth_circular,
smooth_gaussian, smooth_n_point, smooth_rectangular, smooth_window,
wind_components, wind_direction, wind_speed, windchill, zoom_xarray = calc
# pyimport_conda("metpy", "metpy")
# Conda.add("metpy")

include("test_basic.jl")
