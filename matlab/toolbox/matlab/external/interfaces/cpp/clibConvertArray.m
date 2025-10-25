%CLIBCONVERTARRAY Convert a MATLAB fundamental array or MATLAB struct array to a MATLAB C++ object for C++ array
%  array = clibConvertArray(typeName, V)
%    typeName - Fully qualified name for C++ fundamental type or C++ structure type.
%    V        - MATLAB array to be converted.
%
%  Examples:
%
%  Example1:
%  Suppose you have a library "libname".
%  a = [1 2 3 4];
%  arr = clibConvertArray('clib.libname.Double', a);
%  class(arr)
%  ans =
%      'clib.array.libname.Double'
%
%  Example2:
%  Suppose you have a library "libname".
%  a = [1 2 3; 4 5 6];
%  arr = clibConvertArray('clib.libname.Int', a);
%  class(arr)
%  ans =
%      'clib.array.libname.Int'
%
%  Example3:
%  Suppose you have a library "libname" with a C++ structure "MyStruct" and
%  wanted to create clib.array from MATLAB struct array "mArray"
%  struct MyStruct
%  {
%     double a;
%  };
%  mArray(1).a = 5;
%  mArray(2).a = 10;
%  myStructArray = clibConvertArray('clib.libname.MyStruct',mArray);
%  class(myStructArray)
%  ans =
%      'clib.array.libname.MyStruct'
%
%  See also: clibArray

% Copyright 2019-2024 The MathWorks, Inc.
