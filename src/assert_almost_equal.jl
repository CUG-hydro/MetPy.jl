using Test

is_finite(x) = !ismissing(x) && isfinite(x)

function nan_maximum(x)
  i = findfirst(is_finite, x)
  max = x[i]
  for _x in skipmissing(x)
    if _x > max
      max = _x
    end
  end
  max
end

error_abs_max(x) = nan_maximum(abs.(x))

function assert_almost_equal(x, y, decimal=6; verbose=false)
  na_valid = all(is_finite.(x) .== is_finite.(y))
  error = error_abs_max(x .- y)
  verbose && (@show na_valid, error)
  @test na_valid && error < 10.0^(-decimal)
end

function assert_almost_equal(x::PyObject, y::PyObject, decimal=6; kw...)
  if x.u != y.u
    y = y.to(x.u)
  end
  assert_almost_equal(values(x), values(y), decimal; kw...)
end

assert_array_equal = assert_almost_equal
# ndindex(shape) = CartesianIndices(shape)

export is_finite, nan_maximum, assert_almost_equal, assert_array_equal
