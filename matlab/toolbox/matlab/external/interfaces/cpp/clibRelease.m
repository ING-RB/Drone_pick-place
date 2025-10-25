%CLIBRELEASE Release C++ object from MATLAB
%
%   CLIBRELEASE(OBJ) releases C++ object from MATLAB, making it inaccessible.
%
%   OBJ must be a C++ library object. Once released, the underlying C++ 
%   object is no longer accessible in MATLAB, and the MATLAB handle OBJ 
%   becomes invalid. If the object is returned again from the library, a 
%   new MATLAB handle will be created. 

% Copyright 2018 The MathWorks, Inc.
