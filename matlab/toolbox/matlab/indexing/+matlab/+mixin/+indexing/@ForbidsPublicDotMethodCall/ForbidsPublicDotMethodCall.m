%ForbidsPublicDotMethodCall  Disallow calls to public methods using dot notation
%   matlab.mixin.indexing.ForbidsPublicDotMethodCall enables a class that
%   overloads parentheses or brace indexing to disallow calling methods
%   using dot notation. Given an instance obj of a class that
%   overloads parentheses indexing, inherits from 
%   ForbidsPublicDotMethodCall, and defines a public method 'myMethod', 
%   then outside the class
%
%    (1)   myMethod(obj)                     calls the method
%    (2)   obj.myMethod                      issues an error
%    (3)   label="myMethod"; obj.(label)     issues an error
%    (4)   obj(1).myMethod                   calls parenReference
%    (5)   label="myMethod";obj(1).(label)   calls parenReference
%
%   Inside methods of the class, invoking methods with dot notation is
%   allowed. When executed inside a method of the class, cases (2) and (3)
%   call the method instead of issuing an error.
%
%   Inheriting from this class does not change the behavior of public
%   property access.
%
%   This mixin must be used with a class that inherits from either
%   RedefinesBrace or RedefinesParen. It cannot be combined with
%   OverridesPublicDotMethodCall or RedefinesDot.
%       
%   See also OverridesPublicDotMethodCall, RedefinesDot, RedefinesBrace,
%            RedefinesParen

% Copyright 2020-2023 The MathWorks, Inc.

classdef (Abstract, HandleCompatible) ForbidsPublicDotMethodCall < ...
        matlab.mixin.internal.indexing.DisallowCompletionOfDotMethodNames
    methods
        function obj = ForbidsPublicDotMethodCall()
            if isa(obj, 'matlab.mixin.indexing.OverridesPublicDotMethodCall')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"matlab.mixin.indexing.ForbidsPublicDotMethodCall", "matlab.mixin.indexing.OverridesPublicDotMethodCall"));
            end

            if isa(obj, 'matlab.mixin.indexing.RedefinesDot')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"matlab.mixin.indexing.ForbidsPublicDotMethodCall", "matlab.mixin.indexing.RedefinesDot"));
            end

            if ~(isa(obj, 'matlab.mixin.indexing.RedefinesParen') ...
                    ||isa(obj, 'matlab.mixin.indexing.RedefinesBrace')...
                    ||isa(obj,"matlab.mixin.internal.indexing.RedefinesDotProperties"))
                errID = 'MATLAB:index:must_inherit_from_class';
                error(message(errID,"matlab.mixin.indexing.ForbidsPublicDotMethodCall", '''matlab.mixin.indexing.RedefinesParen'' or ''matlab.mixin.indexing.RedefinesBrace'''));
            end
        end
    end
end
