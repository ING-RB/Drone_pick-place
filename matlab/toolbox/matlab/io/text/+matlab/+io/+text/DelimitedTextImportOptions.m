classdef DelimitedTextImportOptions < matlab.io.text.TextImportOptions...
        & matlab.io.internal.shared.DelimitedTextInputs
    %DELIMITEDTEXTIMPORTOPTIONS Options for importing data from a text file
    %   DelimitedTextImportOptions can be used to import data from a text
    %   file.
    %
    %   Example, using detectImportOptions to create import options, set
    %   multiple variable types to categorical, then read the data using
    %   readtable:
    %
    %       opts = detectImportOptions('airlinesmall.csv')
    %       opts = setvartype(opts,{'UniqueCarrier','Origin','Dest'},'categorical')
    %       T = readtable('airlinesmall.csv',opts)
    %
    %   Example, setting the fill values and correct types for different
    %   Variables:
    %
    %       opts = setvaropts(opts,'Year','FillValue',1900)
    %       opts = setvartype(opts,{'TaxiIn','TaxiOut'},'double')
    %       opts = setvaropts(opts,{'TaxiIn','TaxiOut'},'FillValue',0)
    %       T = readtable('airlinesmall.csv',opts)
    %
    %   DelimitedTextImportOptions Properties:
    %
    %                     DataLines - The lines in the text file where the data is located.
    %             VariableNamesLine - Where the variable names are located
    %                RowNamesColumn - Where the row names are located
    %             VariableUnitsLine - Where the variable units are located
    %      VariableDescriptionsLine - Where the variable descriptions are located
    %                 VariableNames - Names of the variables in the file
    %         SelectedVariableNames - Names of the variables to be imported
    %                 VariableTypes - The import types of the variables
    %               VariableOptions - Advanced options for variable import
    %         PreserveVariableNames - Whether or not to convert variable names
    %                                 to valid MATLAB identifiers.
    %               ImportErrorRule - Rules for interpreting nonconvertible or bad data
    %                   MissingRule - Rules for interpreting missing or unavailable data
    %              ExtraColumnsRule - What to do with extra columns of data that appear
    %                                 after the expected variables
    %     ConsecutiveDelimitersRule - What to do with consecutive
    %                                 delimiters that appear in the file
    %         LeadingDelimitersRule - What to do with delimiters at the beginning of a
    %                                 line
    %        TrailingDelimitersRule - What to do with delimiters at the end  of a
    %                                 line
    %                 EmptyLineRule - What to do with empty lines in the file
    %                    Delimiter  - Symbol(s) indicating the end of data fields in the
    %                                 file
    %                    Whitespace - Characters to be treated as whitespace.
    %                    LineEnding - Symbol(s) indicating the end of a line in the file
    %                  CommentStyle - Symbol(s) designating text to ignore
    %                      Encoding - Text encoding of the file to be imported
    %
    %   DelimitedTextImportOptions Methods:
    %
    %       getvaropts - get the options for a variable by name or number
    %       setvaropts - set the options for a variable by name or number
    %       setvartype - set the import type of a variable by name or number
    %          preview - read 8 rows of data from the file using options
    %
    % See also matlab.io.VariableImportOptions, detectImportOptions, readtable

    %   Copyright 2016-2020 The MathWorks, Inc.


    methods
        function opts = DelimitedTextImportOptions(varargin)
            [opts,otherArgs] = opts.parseInputs(varargin,{'NumVariables', ...
                                'VariableOptions','PreserveVariableNames', 'VariableNames'});
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
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Format')), opts,{'Delimiter','Whitespace','LineEnding','CommentStyle','ConsecutiveDelimitersRule','LeadingDelimitersRule', 'TrailingDelimitersRule', 'EmptyLineRule','Encoding'});
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Replacement')),opts,{'MissingRule','ImportErrorRule','ExtraColumnsRule'});
            varStruct.VariableNames = [];
            varStruct.VariableTypes = [];
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
            if opts.Encoding == "system"
                opts.Encoding = matlab.internal.i18n.locale.default.Encoding;
            end
            if isfield(args,'ReadingLines') && args.ReadingLines
                params.ParserType = 'line';
            else
                params.ParserType = 'delimited';
            end
            params.OutputBuilderType = args.OutputType;
            params.Encoding = opts.Encoding;
            params.NumVariables = opts.fast_var_opts.numVars();
            params.Delimiter = opts.getUnescapedDelimiter();
            params.Whitespace = opts.getUnescapedWhitespace();
            params.LineEnding = opts.getUnescapedLineEnding();
            params.CommentStyle = opts.getUnescapedCommentStyle();
            params.ConsecutiveDelimitersRule = opts.ConsecutiveDelimitersRule;
            params.LeadingDelimitersRule = opts.LeadingDelimitersRule;
            params.TrailingDelimitersRule = opts.TrailingDelimitersRule;
            params.MissingRule = opts.MissingRule;
            params.ImportErrorRule = opts.ImportErrorRule;
            params.ExtraColumnsRule = opts.ExtraColumnsRule;
            params.EmptyLineRule = opts.EmptyLineRule;
            params.DateLocale = args.DateLocale;
            parser = matlab.io.text.internal.TextParser(params);
        end
    end

    methods (Sealed, Access=protected)
        function obj = updatePerVarSizes(obj,~)
        % does nothing.
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            % Loads DelimitedTextImportOptions objects from MAT files.
            obj = matlab.io.text.TextImportOptions.loadTextImportOptions(s, "delimited");
            if isstruct(s)
                obj = obj.setUnescapedDelimiter(s.delim_);
            end
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to DelimitedTextImportOptions to
            % be  set in the loadImportOptions method of ImportOptions.
            textProps = matlab.io.text.TextImportOptions.getTextPropertyList();
            props = ["ConsecutiveDelimitersRule", "LeadingDelimitersRule", "TrailingDelimitersRule"];
            props = [textProps props];
        end
    end
end


% LocalWords:  addvars
