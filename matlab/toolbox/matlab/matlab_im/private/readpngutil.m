function [X, map, alpha] = readpngutil(filename, bg, byteOffset)
%READPNGUTIL Utility function that allows reading a PNG stream located at
%any location in a file.

% Copyright 2016-2020 MathWorks

alpha = [];
try
    [X,map,oneRow3d,transparency] = matlab.internal.imagesci.pngreadc(filename, bg, false, byteOffset);
catch me
    if strcmp(me.identifier,'MATLAB:imagesci:png:libraryFailure')
        [X,map,oneRow3d,transparency] = matlab.internal.imagesci.pngreadc(filename, bg,true);
        warning(message('MATLAB:imagesci:png:tooManyIDATsData'));
    else
        rethrow(me);
    end
end
X = permute(X, ndims(X):-1:1);

if oneRow3d
    X = reshape(X,[1 size(X)]);
end

if (ismember(size(X,3), [2 4]))
    alpha = X(:,:,end);
    % Strip the alpha channel off of X.
    X = X(:,:,1:end-1);
end

% See g1702814: Check that alpha is empty  and transparency is not empty.
% For palette based images files, alpha is always empty
if ~isempty(transparency) && isempty(alpha)
   alpha = transparency;
   [rowMap,~] = size(map);
   [rowAlpha,~] = size(alpha);
   last = rowMap - rowAlpha;
   
   % For palette based images, the number of transparency
   % entries is always less or equal to the entries in the
   % the palette. In that case the remaining transparency
   % values is assumed to be 255 or opaque.
   if last ~=0
       alpha(end+1:end+last) = 1;
   end
   % Store the transparency value for every pixel in the image.
   % Since X can contain index value 0, so adding 1 to each 
   % in order to index into alpha which uses MATLAB indexing.
   alpha = alpha(X + 1);
end

