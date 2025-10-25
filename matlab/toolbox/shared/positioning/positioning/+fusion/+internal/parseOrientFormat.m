function tf = parseOrientFormat(format, funcname)
%   This class is for internal use only. It may be removed in the future. 
%PARSEORIENTFORMAT Create a quaternion or rotation matrix output
%   FORMAT is a char array or scalar string : either 'quaternion' or
%   'rotmat'. Partial matching is allowed.
%   FUNCNAME is the name of the function to throw in an error message if a
%   match is not found.

%   Copyright 2018-2019 The MathWorks, Inc.    

%#codegen

opts = {'quaternion', 'rotmat'};
fmt = validatestring(format, opts, funcname, 'FORMAT', 3);
tf = strcmpi(fmt, 'quaternion');
