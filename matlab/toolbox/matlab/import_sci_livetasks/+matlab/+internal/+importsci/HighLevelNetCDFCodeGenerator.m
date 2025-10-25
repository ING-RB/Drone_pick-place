% This class is unsupported and might change or be removed without notice in a
% future version.


classdef HighLevelNetCDFCodeGenerator < matlab.internal.importsci.AbstractNodeImportCodeGenerator
    %HIGHLEVELNETCDFCODEGENERATOR
    %   Strategy class for generating high-level code for importing
    %   netCDF variables and attributes

    % Copyright 2022 The MathWorks, Inc.


    methods (Access=public)

        % Create an instance of a HighLevelNetCDFCodeGenerator
        function this = HighLevelNetCDFCodeGenerator(filename)
            arguments
                filename (1,1) string
            end

            this.Filename = filename;
        end

        % Method to generate any set up code
        % (implementation for the abstract method of parent class)
        function code = generateSetUpCode(obj)
            arguments
                obj matlab.internal.importsci.HighLevelNetCDFCodeGenerator
            end
            % For high-level code, create a separate filename variable to
            % use in all ncread and ncreadatt calls
            code = obj.createFilenameVariable();
        end

        % Method to generate any tear down code
        % (implementation for the abstract method of parent class)
        function code = generateTearDownCode(obj)
            arguments
                obj matlab.internal.importsci.HighLevelNetCDFCodeGenerator
            end
            % clear the filename variable
            code = obj.clearFilenameVariable();
        end
    end

    % Implementation of the abstract helper strategy methods which are not
    % part of the public interface. They are called by the abstract
    % superclass' public template method.
    methods (Access=protected)

        % Method to generate code for importing variable value
        % (implementation for the abstract method of parent class)
        function importCode = generateImportCodeForVariableStrategy(obj,...
                structPath, locationPath, subsettingOptions)

            % start of variable import line of code
            importCode = structPath + ".Value = ncread(filename, """ + ....
                locationPath + """";

            % Does this variable have any subsetting options?
            % If it does, add Start, Stride, Count options to the
            % generated code. The ncread syntax is
            %     vardata = ncread(source,varname,start,count,stride)
            if ~isempty(subsettingOptions)
                startString = "[" + join(string(subsettingOptions.Start)) + "]";
                countString = "[" + join(string(subsettingOptions.Count)) + "]";
                strideString = "[" + join(string(subsettingOptions.Stride)) + "]";
                % add subsetting options to the line of code
                importCode = importCode + ", " + ...
                    startString + ", " + ...
                    countString + ", " + ...
                    strideString;
            end

            % end of variable import line of code
            importCode = importCode + ");" + newline;

        end

        % Method to generate code for importing attribute value
        % (implementation for the abstract method of parent class)
        function importCode = generateImportCodeForAttributeStrategy(obj,...
                structPath, parentLocationPath, attName, ~)

            if parentLocationPath == ""
                % it is a global attribute, set the location path
                % appropriately
                parentLocationPath = "/";
            end

            % ncreadatt syntax is:
            %    attvalue = ncreadatt(source, location, attname)
            importCode = structPath + ".Value = ncreadatt(filename, """ + ...
                parentLocationPath + """, """ + ...
                attName + """);" + newline;
        end


    end

end