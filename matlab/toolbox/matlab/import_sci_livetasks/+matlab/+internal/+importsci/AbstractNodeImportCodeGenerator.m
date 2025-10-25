% This class is unsupported and might change or be removed without notice in a
% future version.

classdef (Abstract) AbstractNodeImportCodeGenerator < handle
    %ABSTRACTNODEIMPORTCODEGENERATOR 
    %   Abstract/interface strategy class for generating code for importing
    %   variable/dataset and attribute nodes
    %
    % The public interface of this class is used in code generation for
    % netCDF and HDF5 live tasks. See getImportCode() method in
    % HierarchicalSciImportProvider.

    % Copyright 2022-2023 The MathWorks, Inc.


    properties (Hidden)
        Filename (1,1) string
    end

    % Abstract methods that need to be implemented in concrete subclasses

    % These methods are not part of the public interface. They are helper
    % strategy methods that perform code generation.
    methods (Abstract, Access=protected)
        % Abstract helper method to generate code for importing variable/dataset value
        % (the subclass will use this to define how the code generation works)
        importVariableValueCode = generateImportCodeForVariableStrategy(obj,...
            structPath, locationPath, ...
            subsettingOptions)

        % Abstract helper method to generate code for importing attribute value
        % (the subclass will use this to define how the code generation works)
        importAttributeValueCode = generateImportCodeForAttributeStrategy(obj,...
            structPath, parentLocationPath, attName, ...
            isVariableAttribute)
    end

    % Abstract methods that are part of the public interface
    methods (Abstract, Access=public)

        % method to generate any set up code
        code = generateSetUpCode(obj)

        % method to generate any tear down code
        code = generateTearDownCode(obj)
    end

    % Concrete template methods (using Template/Hook design pattern). These
    % concrete methods do the shared argument validation before calling the
    % abstract implementation/strategy methods. They are part of the public
    % interface.
    methods (Access=public)

        % tempate method to generate code for importing variable/dataset value
        function importVariableValueCode = generateImportCodeForVariable(obj,...
                structPath, locationPath, ...
                subsettingOptions)

            arguments (Input)
                obj matlab.internal.importsci.AbstractNodeImportCodeGenerator

                % MATLAB variable/stucture path where the variable value
                % will be stored, e.g.
                % "file1.Groups(1).Variables(2)"
                structPath (1,1) string

                % location path of this variable in the netCDF file, e.g.
                % "/aux/rad_imag_sw"
                locationPath (1,1) string

                % subsetting options for this variable in the form of a
                % struct. Should be empty (isempty returning true) if no
                % subsetting options for this variable
                subsettingOptions struct = struct([])
            end

            arguments (Output)
                % generated code for importing a variable
                importVariableValueCode (1,1) string
            end

            % Call the strategy abstract method that must be
            % implemented in the subclasses. This is where actual code
            % generation happens.
            importVariableValueCode = ...
                generateImportCodeForVariableStrategy(obj,...
                structPath, locationPath, ...
                subsettingOptions);

        end

        % template method to generate code for importing attribute value
        function importAttributeValueCode = generateImportCodeForAttribute(obj,...
                structPath, parentLocationPath, attName, ...
                parentType)

            arguments (Input)
                obj matlab.internal.importsci.AbstractNodeImportCodeGenerator

                % MATLAB variable/stucture path where the attribute value
                % will be stored, e.g.
                % "file1.Groups(1).Variables(1).Attributes(1)"
                structPath (1,1) string

                % location path of this attribute's parent (variable or
                % group) in the netCDF file, e.g.
                % "/aux/measured_laser_wlen"
                parentLocationPath (1,1) string

                % the name of this attribute, e.g.
                % "units"
                attName {mustBeTextScalar}

                % logical value, true if this is an attribute for a
                % variable, and false if it is a global or group attribute
                parentType (1,1) matlab.internal.importsci.AttributeParentType
            end

            arguments (Output)
                % generated code for importing an attribute
                importAttributeValueCode (1,1) string
            end

            % Call the strategy abstract method that must be
            % implemented in the subclasses. This is where actual code
            % generation happens.
            importAttributeValueCode = generateImportCodeForAttributeStrategy(obj,...
                structPath, parentLocationPath, attName, ...
                parentType);
        end
    end

    % Concrete helper methods that can be helpful for the children of this
    % class
    methods (Access=protected)

        % Generate code to create a separate variable to store the filename
        function code = createFilenameVariable(obj)
            code = newline + "filename = """ + obj.Filename + """;" + ...
                newline;
        end

        % Generate code to clear the separate variable to store the filename
        function code = clearFilenameVariable(obj)
            code = "clear filename" + newline;
        end
    end

end