function  ctype = getCtype(A) %#codegen
%GETCTYPE Get the C data type string

% Copyright 2015-2020 The MathWorks, Inc.

if(isa(A,'logical'))
    ctype = 'boolean';
elseif(isa(A,'single'))
    ctype = 'real32';
elseif(isa(A,'double'))
    ctype = 'real64';    
else
    % default
    ctype = class(A);
end

