function out = openmat(filename)
%OPENMAT   Load data from file and show preview.

% Copyright 1984-2020 The MathWorks, Inc.

try
   out = load(filename);
catch exception
   throw(exception);
end
