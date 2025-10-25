classdef SetGet < matlab.mixin.SetGet
    %SETGET hides the setdisp and getdisp methods from matlab.mixin.SetGet,
    %as per the Hardware Interface Design Standards. Inherit from this
    %class, instead of matlab.mixin.SetGet, if you want to hide the setdisp
    %and getdisp methods, and not want to display all non-hidden protected
    %and private properties of your class in get(obj) or set(obj).

    %   Copyright 2020 The MathWorks, Inc.

    methods (Hidden)
        function setdisp(obj, varargin)
            setdisp@matlab.mixin.SetGet(obj, varargin{:});
        end

        function getdisp(obj, varargin)
            getdisp@matlab.mixin.SetGet(obj, varargin{:});
        end
    end
end