function tf = isHalideActive()
% For internal testing use only

% This function is used by dual-mode code generation based functions to 
% decide whether or not halide should be used for code generation.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

narginchk(0,1);

s = settings;
tf = s.images.UseHalide.ActiveValue;

end