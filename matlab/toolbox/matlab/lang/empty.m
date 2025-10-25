%EMPTY Create empty array 
%   
%   Use empty to create an empty array of any class.  An empty array is useful 
%   when you need to create an array of a given class and shape, but with
%   no data.  For example, use empty to produce an empty array in which
%   some dimensions are not zero.
%
%   A = ClassName.empty returns an empty 0-by-0 array of the given class.
%
%   A = ClassName.EMPTY(M,N,P,...) returns an empty array of the given
%   class with the specified dimensions. At least one of the dimensions
%   must be 0.
%   
%   A = ClassName.EMPTY([M,N,P,...]) using size vector [M,N,P,...] returns
%   an empty array of the given class with the specified dimensions. At 
%   least one of the dimensions must be 0.
%
%   empty is a hidden, public, static method of all non-abstract MATLAB
%   classes.  You can override the empty method in class definitons.
%   
%   Examples:
%    
%       A = double.empty                 % 0-by-0 double matrix
%       B = int16.empty(0,3)             % 0-by-3 int16 matrix
%   
%   See also ISEMPTY, SIZE, LENGTH.

%   Copyright 2012-2019 The MathWorks, Inc.