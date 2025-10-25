%CLIBARRAY Create a MATLAB C++ object for C++ array
%  array = clibArray(typeName, [m,n,p,...])
%    typeName  - Fully qualified name for C++ type.
%    m,n,p,... - The number of elements in each dimension of the array.
%
%  Examples:
%
%  Example1:
%  Suppose you have a library "libname" with a class "Myclass".
%  myclassArray = clibArray('clib.libname.Myclass', 5);
%  class(myclassArray)
%  ans =
%      'clib.array.libname.Myclass'
%
%  Example2:
%  Suppose you have a library "libname".
%  myDoubleArray = clibArray('clib.libname.Double', [2,3]);
%  class(myDoubleArray)
%  ans =
%      'clib.array.libname.Double'
%
%  See also: clibConvertArray

% Copyright 2019 The MathWorks, Inc.
