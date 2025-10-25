classdef(Abstract) OptionType < handle
%

%OptionType Abstract base-class to encapsulate metadata about an option
%type. 
%
% This base-class defines the interface for which any optimization
% option "type" must conform to. 
%
% The purpose of these classes is to serve as descriptive information
% (constant or static) that can be used as ground-truth for options classes
% or GUIs.
%
% See also OPTIM.OPTIONS.SOLVEROPTIONS, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    properties(Abstract, Constant)
        % TypeKey - Name of the option type (e.g. Numeric, Logical, ...). This
        % name is for internal reference by any front-end and does not need
        % to match the MATLAB datatype name.
        % For example, a GUI client can use this as a key to map to a
        % widget type (e.g. EnumType ==> Drop-down).
        TypeKey
                
        % TabType - Type for the tab-complete system in MATLAB. This
        % property is assumed to be one that is recognized as a valid
        % "type" in the tab-complete JSON file.
        TabType
    end
    
    properties(Abstract, SetAccess = protected, GetAccess = public)
        % Category - The broad category of the option. This must be one of
        % the valid choices in the MATLAB:optimfun:options:meta:categories XML
        % resource file.
        Category     
        
        % DisplayLabel - The label for the option that will be displayed in
        % the GUI.
        DisplayLabel
        
        % Widget - The name of the default GUI widget for this option type
        Widget
        
        % WidgetData - The default GUI widget data for this option type
        WidgetData
    end
    
    methods(Abstract)
        % validate - The function that validates a given value against the
        % type information baked into the class. Must throw on an invalid
        % input.
        % Subclasses must define this method.
        [value, isOK, errid, errmsg] = validate(name,value);
    end
    
end