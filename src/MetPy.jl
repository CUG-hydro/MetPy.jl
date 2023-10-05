# Copyright (c) 2008,2015,2017,2019 MetPy Developers.
# Distributed under the terms of the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause
module MetPy

using UnPack
using PyCall
using PyCall: @py_str


include("helper.jl")
include("assert_almost_equal.jl")


const numpy = PyNULL()
const metpy = PyNULL()
const units = PyNULL()
const calc = PyNULL()
# ENV["PYTHON"] = "D:/Program Files/miniconda/envs/metpy/python.exe"


function init_metpy()
  copy!(numpy, pyimport_conda("numpy", "numpy"))
  copy!(metpy, pyimport_conda("metpy", "metpy"))
  copy!(units, pyimport_conda("metpy.units", "metpy").units)
  copy!(calc, pyimport_conda("metpy.calc", "metpy"))

  ## the issue of `numpy.ma.array`
  py"""
  import numpy
  from metpy.units import units

  def mask_array(x, u, mask=None):
    data = numpy.ma.array(x, mask=mask)
    return units.Quantity(data, u)
  """
  nothing
end


mask_array(x::AbstractArray, u=""; mask=nothing) = py"mask_array"(x, u, mask)

array_type = mask_array

# function mask_array(x::AbstractArray, u; mask=nothing)
#   data = numpy.ma.array(x, mask=mask)
#   units.Quantity(data, u)
# end

export numpy, metpy, units, calc
export init_metpy
export mask_array, array_type


end # module Metpy
