classdef (Abstract) CodeGenAble < matlab.mixin.SetGet
    % Internal use only

    %codegen.CodeGenAble Superclass providing codgen functionality for
    % handle objects
    %
    % The codegen.CodeGenAble class is an abstract class that add the
    % codegen functionality to your class.
    %
    % The class provides two public methods, MCODECONSTRUCTOR and 
    % mcodeIgnoreHandle.  The MCODECONSTRUCTOR method generates MATLAB code 
    % for basic properties and can be overridden to provide support for 
    % more complicated properties.  The MCODEIGNOREHANDLE method determines 
    % whether or not to support code generation.  By default, this returns
    % false, to NOT ignore this object during code generation.  This method 
    % can also be overridden.

    % Copyright 2024 The MathWorks, Inc.

    methods
        function this = CodeGenAble(varargin)
            if (nargin > 0)
                this.set(varargin{:});
            end
        end

        function mcodeConstructor(this, code) %#ok
            code.generateDefaultPropValueSyntax();
        end
        
        function out = mcodeIgnoreHandle(this, code) %#ok
            out = false;
        end
    end

    methods (Sealed)
        % HANDLE and ISHANDLE are used to mimic a UDD object to allow 
        % codegen code that works for UDD objects to also work for MCOS
        % objects.
        function out = handle(this)
            out = this;
        end

        function tf = ishandle(this)
            if ~isempty(this) 
                % THIS can be [1xn] objects.  Cannot be combine with
                % ISEMPTY.
                tf = isvalid(this); 
            else
                tf = false;
            end
        end
    end
end