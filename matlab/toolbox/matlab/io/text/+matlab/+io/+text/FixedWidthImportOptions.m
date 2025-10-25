classdef FixedWidthImportOptions < matlab.io.text.TextImportOptions...
        & matlab.io.internal.shared.FixedWidthInputs
    %FIXEDWIDTHIMPORTOPTIONS Options for importing data from a text file
    %   FixedWidthImportOptions can be used to import data from a text
    %   file.
    %
    %   FixedWidthImportOptions Properties:
    %
    %                     DataLines - The lines in the text file where the data is located.
    %             VariableNamesLine - Where the variable names are located
    %                RowNamesColumn - Where the row names are located
    %             VariableUnitsLine - Where the variable units are located
    %      VariableDescriptionsLine - Where the variable descriptions are located
    %                 VariableNames - Names of the variables in the file
    %         SelectedVariableNames - Names of the variables to be imported
    %                 VariableTypes - The import types of the variables
    %                VariableWidths - Number of characters in each field to be imported
    %               VariableOptions - Advanced options for variable import
    %         PreserveVariableNames - Whether or not to convert variable names
    %                                 to valid MATLAB identifiers.
    %               ImportErrorRule - Rules for interpreting nonconvertible or bad data
    %                   MissingRule - Rules for interpreting missing or unavailable data
    %              ExtraColumnsRule - What to do with extra columns of data that appear
    %                                 after the expected variables
    %              PartialFieldRule - What to do with fields that end before matching the
    %                                 requested width
    %                 EmptyLineRule - What to do with empty lines in the file
    %                    Whitespace - Characters to be treated as whitespace.
    %                    LineEnding - Symbol(s) indicating the end of a line in the file
    %                  CommentStyle - Symbol(s) designating text to ignore
    %                      Encoding - Text encoding of the file to be imported
    %
    %   FixedWidthImportOptions Methods:
    %
    %       getvaropts - get the options for a variable by name or number
    %       setvaropts - set the options for a variable by name or number
    %       setvartype - set the import type of a variable by name or number
    %          preview - read 8 rows of data from the file using options
    %
    % See also matlab.io.VariableImportOptions, detectImportOptions, readtable

    %   Copyright 2016-2020 The MathWorks, Inc.



    methods
        function opts = FixedWidthImportOptions(varargin)
            [opts,otherArgs] = opts.parseInputs(varargin,{'NumVariables',...
                                'VariableOptions','PreserveVariableNames','VariableNames'});
            % DataLine is a hidden property so parseInputs doesn't find it.
            if isfield(otherArgs, 'DataLine')
                opts.DataLine = otherArgs.DataLine;
                otherArgs = rmfield(otherArgs, 'DataLine');
            end
            opts.assertNoAdditionalParameters(fields(otherArgs),class(opts));
        end
    end

    methods (Access = protected)
        function addCustomPropertyGroups(opts,h)
        % added strings for the property types to the message catalog
        % for translation purposes
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Format')),opts,{'Whitespace','LineEnding','CommentStyle','EmptyLineRule','Encoding'});
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Replacement')),opts,{'MissingRule','ImportErrorRule','ExtraColumnsRule','PartialFieldRule'});
            varStruct.VariableNames = [];
            varStruct.VariableTypes = [];
            varStruct.VariableWidths = opts.VariableWidths;
            varStruct.SelectedVariableNames = [];
            varStruct.VariableOptions = [];
            varStruct.VariableNamingRule = opts.VariableNamingRule;
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:VariableImport')),varStruct);
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Location')),opts,{'DataLines','VariableNamesLine','RowNamesColumn','VariableUnitsLine','VariableDescriptionsLine'});
        end

        function modifyCustomGroups(~,~)
        end
    end

    methods (Hidden,Access = {?matlab.io.text.internal.TabularTextReader})

        function parser = getParser(opts,args)
            import matlab.io.internal.utility.validateAndEscapeCellStrings;
            import matlab.io.internal.utility.validateAndEscapeStrings;
            params.ParserType = 'fixedwidth';
            params.OutputBuilderType = args.OutputType;

            params.Encoding = opts.Encoding;
            params.NumVariables = opts.fast_var_opts.numVars();
            params.Whitespace = validateAndEscapeStrings(opts.Whitespace);
            params.LineEnding = validateAndEscapeCellStrings(opts.LineEnding);
            params.CommentStyle = validateAndEscapeCellStrings(opts.CommentStyle);
            params.MissingRule = opts.MissingRule;
            params.ImportErrorRule = opts.ImportErrorRule;
            params.ExtraColumnsRule = opts.ExtraColumnsRule;
            params.EmptyLineRule = opts.EmptyLineRule;
            params.DateLocale = args.DateLocale;

            params.VariableWidths = cast(opts.VariableWidths,'uint64');
            params.PartialFieldRule = opts.PartialFieldRule;

            parser = matlab.io.text.internal.TextParser(params);
        end
    end

    methods (Sealed, Access=protected)
        function obj = updatePerVarSizes(obj,nNew)
            w = obj.widths_;
            nOld = numel(w);
            if nOld < nNew
                obj.widths_(nOld+1:nNew) = 1;
            elseif nOld > nNew
                obj.widths_(nNew+1:nOld) = [];
            end
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            % Loads FixedWidthImportOptions objecs from MAT files.
            if isstruct(s)
                s.VariableWidths = s.widths_;
                s = rmfield(s, "widths_");
            end
            obj = matlab.io.text.TextImportOptions.loadTextImportOptions(s, "fixed");
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to FixedWidthImportOptions to
            % be  set in the loadImportOptions method of ImportOptions.
            textProps = matlab.io.text.TextImportOptions.getTextPropertyList();
            props = ["VariableWidths", "PartialFieldRule"];
            props = [textProps props];
        end
    end
end

% LocalWords:  addvars
