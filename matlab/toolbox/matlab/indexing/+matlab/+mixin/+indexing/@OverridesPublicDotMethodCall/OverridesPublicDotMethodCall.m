%OverridesPublicDotMethodCall  Override calls to public methods using dot notation
%   matlab.mixin.indexing.OverridesPublicDotMethodCall enables a class that
%   overloads dot indexing to specify that calling public methods using
%   dot notation should invoke overloaded dot indexing outside of the
%   class.
%   When a class overloads dot indexing, inherits from
%   OverridesPublicDotMethodCall, and defines a public method 'myMethod',
%   then method calls outside of the class have the following behavior:
%
%    (1)   myMethod(obj)                     calls the method
%    (2)   obj.myMethod                      calls dotReference
%    (3)   label="myMethod"; obj.(label)     calls dotReference
%
%   When the class does not inherit from OverridesPublicDotMethodCall, then
%   cases (2) and (3) call the method myMethod.
%
%   Inside methods of the class, method calls using dot notation are not 
%   overridden. When executed inside a method of the class, cases (2) and 
%   (3) always call the method instead of calling dotReference. 
%
%   Inheriting from this mixin does not change the behavior of public
%   property access.
%
%   This mixin must be used with a class that inherits from RedefinesDot.
%   It cannot be combined with ForbidsPublicDotMethodCall.
%       
%   See also ForbidsPublicDotMethodCall, RedefinesDot, RedefinesBrace,
%            RedefinesParen

%   Copyright 2020-2021 The MathWorks, Inc.

classdef (Abstract, HandleCompatible) OverridesPublicDotMethodCall
    methods
        function obj = OverridesPublicDotMethodCall()
            if isa(obj, 'matlab.mixin.indexing.ForbidsPublicDotMethodCall')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"matlab.mixin.indexing.OverridesPublicDotMethodCall", "matlab.mixin.indexing.ForbidsPublicDotMethodCall"));
            end

            if ~isa(obj, 'matlab.mixin.indexing.RedefinesDot')
                errID = 'MATLAB:index:must_inherit_from_class';
                error(message(errID,"matlab.mixin.indexing.OverridesPublicDotMethodCall", "matlab.mixin.indexing.RedefinesDot"));
            end
        end
    end
end
