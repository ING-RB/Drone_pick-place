function out = openmldatx(filename)
%OPENMLDATX   Open a MATLAB Data Export File.  
%   Helper function for OPEN.
%
%   See OPEN.

%   Copyright 2014 MathWorks, Inc. 

if nargout, out = []; end
matlabshared.mldatx.internal.open(filename);