%#codegen
    
% Copyright 2016-2020 The MathWorks, Inc.

function val = expandScalarValue(value, dims)
  if dims(2) == 1
    if isscalar(value)
      val = value(1,1) * ones(dims);
    else
      val = value(:);
    end
  else
    if isscalar(value)
      val = value(1,1) * eye(dims);
    else
      val = value;
    end
  end
end
