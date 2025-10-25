%underlyingType  Return underlying data type determining array behavior.
%
%   TYPENAME = underlyingType(OBJ) returns the name of the underlying
%   MATLAB data type that determines how the array OBJ behaves.
%
%   For fundamental data types or classes, such as single, double, and
%   string arrays, TYPENAME is the name of the data type of OBJ.
%   underlyingType(OBJ) returns the same result as class(OBJ).
%
%   For attribute classes, such as gpuArray, dlarray, and distributed
%   arrays, TYPENAME is the name of the underlying fundamental data type.
%   Attribute classes modify storage or other attributes of fundamental
%   data types, while the object retains the behavior of the fundamental
%   data type.
%
%   For array classes, such as cell arrays, tables, and timetables,
%   TYPENAME is the name of the array class. Array classes can contain data
%   of a different type but do not behave like that type. For example, a
%   cell array containing double values behaves like a cell array, so
%   TYPENAME is 'cell'.
%
%   Examples:
%   x = zeros(2,2,"single");
%   underlyingType(x)         % returns 'single'
%
%   x = gpuArray(eye(3,"uint8"));
%   underlyingType(x)         % returns 'uint8'
%
%   x = dlarray(gpuArray(rand(3)));
%   underlyingType(x)         % returns 'double'
%
%   x = {1,2,3};
%   underlyingType(x)         % returns 'cell'
%
%   x = table([1;2],[3;4]);
%   underlyingType(x)         % returns 'table'
%
%   See also: isUnderlyingType, mustBeUnderlyingType, class.

%   Copyright 2020 The MathWorks, Inc.
