function rgb = hex2rgb(hex,opts)
%

%   Copyright 2023 The MathWorks, Inc.

arguments
    hex string
    opts.OutputType {mustBeMember(opts.OutputType, {'double' 'single' 'uint8' 'uint16'})} = 'double'
end

sz = size(hex);

% Validate HEX shape and reshape MxN to a vector of hex codes.
if isequal(sz, [0 0]) ||(isvector(hex) && numel(sz) == 2)
    % 0x0 and 2D vectors produce nx3 RGB matrices
    sz = numel(hex);
end
% For a matrix of hex values, change to a vector of hex values.
hex = hex(:);

% Verify all inputs start with '#'.
if any(hex == "") || ~all(startsWith(hex,"#"))
    error(message('MATLAB:graphics:validatecolor:InvalidHEXColors'));
end

% Convert hex to rgb and adjust scale and datatype based on OutputType.
try
    rgb = validatecolor(hex, 'multiple');
catch
    error(message('MATLAB:graphics:validatecolor:InvalidHEXColors'));
end

switch opts.OutputType
    case {'uint8', 'uint16'}
        rgb = cast(rgb * double(intmax(opts.OutputType)), opts.OutputType);
    case 'single'
        rgb = cast(rgb, opts.OutputType);
end

rgb = reshape(rgb, [sz 3]);
end