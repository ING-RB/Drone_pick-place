%CLIBISREADONLY Determine if a MATLAB C++ object is read-only
%
%   CLIBISREADONLY(OBJ) returns logical 1 (true) if the MATLAB C++ library
%   object is read-only or returns logical 0 (false) otherwise.
%
%   OBJ must be a MATLAB C++ library object. If the MATLAB C++ library
%   object is read-only (const object), then logical 1 is returned.  If
%   the MATLAB C++ library object can be modified (nonconst object), then
%   logical 0 (false) is returned. 

% Copyright 2019 The MathWorks, Inc.
