function classification = classifyArraySize(dims)
%classifyArraySize Given array dimensions, classifies it as scalar, vector
% or higher dimension array.

%   Copyright 2020-2023 The MathWorks, Inc.

   arguments
       dims (1,:) uint64 % TODO consider taking raw array dim obj instead
   end
   
   import matlab.engine.internal.codegen.DimType;
   
   n = length(dims);
   classification = DimType.Unknown;
   
   oneArray = ones(1, length(dims));
   numGtOne = sum(dims > oneArray); % number dims greater than 1

   % First determine if array is empty
   if isempty(dims)
       classification = DimType.Empty;
   elseif n<2
       classification = DimType.Empty;
   elseif sum(dims == 0) >= 1
       classification = DimType.Empty;

   % Based on non-trivial (non-1-sized) dimensions, determine type
   elseif numGtOne==0
       classification = DimType.Scalar; % for example 1x1x1 or 1x1
   elseif numGtOne==1
       classification = DimType.Vector; % for example 1x1x2
   elseif numGtOne>=2
       classification = DimType.MultiDim; % for example 2x2x1

   % If logic above is faulty somehow, return unknown type
   else
       classification = DimType.Unknown;
   end
   
end

