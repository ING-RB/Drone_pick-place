function hfig = imageview(varargin)
%IMAGEVIEW Show an image preview in a figure window
% IMAGEVIEW has been removed. Use IMSHOW instead.

% Copyright 1984-2023 The MathWorks, Inc.

me = MException(message("MATLAB:imageview:DeprecationMessage"));
me = me.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection('imageview','imshow'));
throw(me);