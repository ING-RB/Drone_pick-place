function out = getHashValueForCharVec(in)
%This class is for internal use only. It may be removed in the future.

%getHashValueForCharVec - Convert cell array of single char vector OR a 1
%row char vector OR a string scalar into a unique number. NOTE: This
%function supports codegen

% Copyright 2018 The MathWorks, Inc.

%#codegen

% Handle cell array of a single character vector.
if iscell(in)
    validateattributes(in, {'cell'}, {'nonempty', 'scalar'}, 'getHashValueForCharVec', 'in');
    in = in{1};
end

% Ensure string/ char 
validateattributes(in, {'char', 'string'}, {'nonempty'}, 'getHashValueForCharVec', 'in');

% Ensure correct size
if isstring(in)
    validateattributes(in, {'string'}, {'scalar'}, 'getHashValueForCharVec', 'in');
else
    validateattributes(in, {'char'}, {'nrows', 1}, 'getHashValueForCharVec', 'in');
end

% Convert all valid string into char
in = convertStringsToChars(in);

% Convert char -> double numbers
charVal = uint64(strtrim(in));

% Another implementation: Ref: https://research.cs.vt.edu/AVresearch/hashing/strings.php
% out = 0;
% mult = 1;
% for idx = 1:length(charVal)-4
%     out = out + sum(charVal(idx:idx+4))*mult;
%     mult = mult*256;
% end

% Ref: http://www.cse.yorku.ca/~oz/hash.html
out = uint64(5381);
for idx = 1:length(charVal)
    out = (bitshift(out, 5) + out) + charVal(idx);
end

% Return double
out = double(out);

end