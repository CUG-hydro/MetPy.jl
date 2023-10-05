# get values of the Quantity Object
function Base.values(x::PyObject; miss=NaN)
  values = x.m

  if hasproperty(x, :mask)
    T = nonmissingtype(eltype(values))

    if miss === nothing || T <: Integer
      values = Array{Union{Missing,T}}(values)
      missval = missing
    else
      missval = T(miss)
    end

    mask = x.mask
    any(mask) && (values[mask] .= missval)
  end
  values
end


export values
