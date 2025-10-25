function shapes = computeDynamicWordShapes(words,fsize,fontName,updateState)
% This internal helper function may be removed in a future release.

% Shape is M-by-N where each column encodes bounds info about the corresponding
% word shape. The format is the same as the output from wordshape.m
% Each word is a rectangle based on the string bounds returned by updateState.
% The input fsize is assumed to be in pixels.

% Copyright 2021-2024 The MathWorks, Inc.

num_words = length(words);
shapes = zeros(4,num_words);
font = matlab.graphics.general.Font;
font.Name = fontName;
for i = 1:num_words
  font.Size = fsize(i);
  word = words(i);
  box = getStringBounds(updateState, word, font, 'none');
  w = ceil(box(1)/2);
  h = ceil(box(2)/2);
  shapes(1:2,i) = w;
  shapes(3:4,i) = h;
  shapes(4+(1:4*w),i) = h;
end

end
