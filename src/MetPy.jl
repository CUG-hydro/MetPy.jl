# Copyright (c) 2008,2015,2017,2019 MetPy Developers.
# Distributed under the terms of the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause
module MetPy

using UnPack
using PyCall
import PyCall: @py_str


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
  nothing
end

include("helper.jl")


export init_metpy, numpy, metpy, units, calc


end # module Metpy
