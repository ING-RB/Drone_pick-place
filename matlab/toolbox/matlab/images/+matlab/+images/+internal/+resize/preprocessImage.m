function A = preprocessImage(params)
% Convert indexed image to RGB.  Convert binary image to uint8.

% Copyright 2020 The MathWorks, Inc.

 if matlab.images.internal.resize.isInputIndexed(params)
    A = matlab.images.internal.ind2rgb8(params.A, params.map);
elseif islogical(params.A)
    A = uint8(255) .* uint8(params.A);
elseif iscategorical(params.A)
    A = categorical2numeric(params.A); 
else
    A = params.A;
end
%---------------------------------------------------------------------

function [out, categoriesIn] = categorical2numeric(in)
% CATEGORICAL2NUMERIC converts categorical array to a numeric array with
% datatype dependent on number of categories.
%
% in            - categorical input to be converted
% out           - converted numeric array
% categoriesIn  - categories of the input array

categoriesIn = categories(in);
numCategories = numel(categoriesIn);

if(numCategories <= 2^8)
    out = uint8(in); 
elseif(numCategories > 2^8) && (numCategories <= 2^16)
    out = uint16(in); 
elseif(numCategories > 2^16) && (numCategories <= 2^32)
    out = uint32(in); 
else
    out = uint64(in); 
end