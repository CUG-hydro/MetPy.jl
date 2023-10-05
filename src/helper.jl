using Test


function array_type(d::AbstractArray, u::String; mask=nothing)
  data = numpy.ma.array(d, mask=mask)
  units.Quantity(data, u)
end


assert_almost_equal(x, y, decimal=6) =
  @assert maximum(abs.(x .- y)) < 10.0^(-decimal)

assert_almost_equal(x::PyObject, y::PyObject, decimal=6) =
  assert_almost_equal(x.m, y.m, decimal)


function ndindex(shape)
  inds = CartesianIndices(shape)
  Tuple.(inds)
end


# s = numpy.zeros((3, m, m))
#   for i in numpy.ndindex(s.shape):
#       s[i] = i[1] + i[2]**2
function ndindex_s(shape)
  res = zeros(Int, shape...)
  inds = CartesianIndices(shape)
  for i in inds
    res[i] = i[2] - 1 + (i[3] - 1)^2
  end
  res
end


export array_type, assert_almost_equal, ndindex, ndindex_s
