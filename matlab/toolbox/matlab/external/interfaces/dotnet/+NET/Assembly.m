%NET.Assembly represents a .NET Assembly class.
% NET.Assembly class instance is returned as a result of  NET.addAssembly
% API. NET.Assembly has following properties:
%
%   AssemblyHandle:	An instance of System.Reflection.Assembly class of the
%                   added assembly.
%   Classes:        Mx1 cell array of class names of the added assembly.
%   Enums:          Mx1 cell array of enums of the added assembly. 
%   Structures:     Mx1 cell array of structures of the added assembly. 
%   GenericTypes:   Mx1 cell array of generic types of the added assembly.
%   Interfaces:     Mx1 cell array of interface names of the added assembly. 
%   Delegates:      Mx1 cell array of delegates of the added assembly.  

%   Copyright 2021-2025 The MathWorks, Inc.
classdef Assembly < handle & matlab.mixin.CustomDisplay
    %read only properties
    properties (SetAccess = private)
        AssemblyHandle = [];
        Classes = {};
        Structures = {};
        Enums = {};
        GenericTypes = {};
        Interfaces = {};
        Delegates = {};
    end
    %hidden properties for status flags
    properties (Hidden = true, Access = private)
        Types_Read = false;
        Types = {};
        Classes_Read = false;
        Structures_Read = false;
        Enums_Read = false;
        GenericTypes_Read = false;
        Interfaces_Read = false;
        Delegates_Read = false;
        AssemblyLocation = [];
    end
    methods(Access=private)
        function types = getNetFrameworkTypes(this)
            % Returns a cell array of System.Type exported by the assembly
            exported = this.AssemblyHandle.GetExportedTypes();
            types = cell(exported.Length, 1);
            for i=1:exported.Length
                types{i, 1} = exported.Get(i-1);
            end
        end
        
        function types = getNetCoreTypes(this)
            % Returns a cell array of System.Type exported AND forwarded
            % by the assembly
            forwarded = this.AssemblyHandle.GetForwardedTypes();
            types = cell(forwarded.Length, 1);
            for i=1:forwarded.Length
                types{i, 1} = forwarded.Get(i-1);
            end
            types = [types; this.getNetFrameworkTypes()];
        end
    
        function types = getAllTypes(this)
            if ~this.Types_Read
                if dotnetenv().Runtime == 'core'
                    types = this.getNetCoreTypes();
                else
                    types = this.getNetFrameworkTypes();
                end
                % We don't want to store instances of System.Type because
                % they might prevent this assembly from unloading. Convert
                % to a struct with the necessary information.
                delType = System.Type.GetType('System.Delegate');
                this.Types = cellfun(@(c)struct(...
                    "IsClass", c.IsClass,...
                    "IsValueType", c.IsValueType,...
                    "IsInterface", c.IsInterface,...
                    "IsGenericType", c.IsGenericType,...
                    "IsDelegate", c.IsSubclassOf(delType),...
                    "IsEnum", c.IsEnum,...
                    "FullName", char(c.ToString())...
                    ), types);
                this.Types_Read = true;
            end
            types = this.Types;
        end
    end
    methods(Access=protected)
        function displayScalarObject(obj)
            % "1x1 NET.Assembly handle with properties:"
            disp(matlab.mixin.CustomDisplay.getDetailedHeader(obj));
            % Display each property on a newline.
            for prop = properties(obj)'
                disp(append("    ", prop));
            end
        end
        function displayEmptyObject(obj)
            % 0x0
            dims = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
            % unknown
            unk = message("MATLAB:NET:UnloadAssembly:UnknownAssembly").getString();
            % NET.Assembly
            cls = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            % handle
            hndl = matlab.mixin.CustomDisplay.getHandleText();
            % 0x0 unknown NET.Assembly handle
            disp(append("  ", dims, " ", unk, " ", cls, " ", hndl, newline));
        end
    end
    methods
        %constructor - sets the AsssemblyHandle property
        function ct = Assembly(asm)
            ct.AssemblyHandle = asm;
            if ~isempty(asm)
                ct.AssemblyLocation = string(asm.Location);
            end
        end
        
        %property Classes
        function value = get.Classes(this)
            if(~this.Classes_Read)
                types = this.getAllTypes();
                mask = [types.IsClass] & ~[types.IsInterface] & ~[types.IsGenericType] & ~[types.IsDelegate];
                this.Classes = {types(mask).FullName}';
                this.Classes_Read = true;
            end
            %return the result
            value = this.Classes;
        end
        
        %property Interfaces
        function value = get.Interfaces(this)
            if(~this.Interfaces_Read)
                types = this.getAllTypes();
                mask = [types.IsInterface];
                this.Interfaces = {types(mask).FullName}';
                this.Interfaces_Read = true;
            end
            %return the result
            value = this.Interfaces;
        end
        
        %property Enums
        function value = get.Enums(this)
            if(~this.Enums_Read)
                types = this.getAllTypes();
                mask = [types.IsEnum];
                this.Enums = {types(mask).FullName}';
                this.Enums_Read = true;
            end
            %return the result
            value = this.Enums;
        end
       
        %property GenericTypes
        function value = get.GenericTypes(this)
            if(~this.GenericTypes_Read)
                types = this.getAllTypes();
                mask = [types.IsGenericType];
                this.GenericTypes = {types(mask).FullName}';
                this.GenericTypes_Read = true;
            end
            %return the result
            value = this.GenericTypes;
        end
        
        %property Delegates
        function value = get.Delegates(this)
            if(~this.Delegates_Read)
                types = this.getAllTypes();
                mask = [types.IsDelegate];
                this.Delegates = {types(mask).FullName}';
                this.Delegates_Read = true;
            end
            %return the result
            value = this.Delegates;
        end
        
        %property Structures
        function value = get.Structures(this)
            if(~this.Structures_Read)
                types = this.getAllTypes();
                mask = [types.IsValueType] & ~[types.IsClass] & ~[types.IsEnum] & ~[types.IsInterface] & ~[types.IsGenericType];
                this.Structures = {types(mask).FullName}';
                this.Structures_Read = true;
            end
            %return the result
            value = this.Structures;
        end
    end
end
