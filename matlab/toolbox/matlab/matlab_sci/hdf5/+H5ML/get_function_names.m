function names = get_function_names()
%H5ML.get_function_names Get the functions provided by the HDF5 library.
%   This function will return a list of supported library functions.
%
%   Function parameters:
%     names: an alphabetized cell array of function names.
%
%   Example:
%     names = H5ML.get_function_names();
%

%   Copyright 2006-2024 The MathWorks, Inc.

% Functions provided by the builtin
names = matlab.internal.sci.hdf5lib2('H5MLget_function_names');

% Functions provided in MATLAB programs.
names = [names' 'H5MLhoffset' 'H5MLsizeof'];

names = sort(names);
