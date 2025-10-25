classdef (AllowedSubclasses = {?matlab.io.text.DelimitedTextImportOptions,?matlab.io.text.FixedWidthImportOptions}) TextImportOptions < matlab.io.ImportOptions ...
        & matlab.io.internal.shared.TextInputs
    %

    % Copyright 2016-2022 The MathWorks, Inc.

    properties (Access = {?matlab.io.internal.builders.CellBuilder, ...
            ?matlab.io.internal.functions.ReadCellWithImportOptions, ...
            ?matlab.io.internal.functions.ReadMatrixWithImportOptions})
        % When a TextImportOptions object that does not contain any 
        % variables is provided to readcell or readmatrix, an extra
        % variable is added. This variable keeps track of whether this has
        % occured. 
        AddedExtraVar = false;
    end

    methods (Sealed, Access = protected)
        function verifyMaxVarSize(~,~)
        end
    end

    methods (Hidden)
        function rhs = setRowNamesColumn(opts,rhs)
            if rhs > numel(opts.VariableNames)
                error(message('MATLAB:textio:io:RowNamesColNumVars'))
            end
        end
    end

    methods(Static, Access = protected)
        function obj = loadTextImportOptions(s, type)
            % Helper method used when loading Text Import Options objects
            % from a MAT file. This method sets the properties common to
            % all Text Import Options object.
            if isstruct(s)
                if isfield(s, "DataLine") % convert DataLine into DataLines
                    s.DataLines = s.DataLine;
                    s = rmfield(s, "DataLine");
                end
            end
            obj = matlab.io.ImportOptions.loadImportOptions(s, type);
            
            % handles Whitespace, LineEnding, CommentStyle
            if isstruct(s)
                obj = obj.setUnescapedWhitespace(s.whtspc_);
                obj = obj.setUnescapedLineEnding(s.eol_);
                obj = obj.setUnescapedCommentStyle(s.comments_);
            end
        end
    end
    
    methods(Static, Access = protected)
        function props = getTextPropertyList()
            % List of properties specific to TextImportOptions to
            % be  set in the loadImportOptions method of ImportOptions.
            % Does not include whtspc_, eol_, and comments_ because their
            % set methods are private.
            props = ["VariableNamesLine", "RowNamesColumn", "DataLines",...
                "VariableUnitsLine", "VariableDescriptionsLine",...
                "ExtraColumnsRule", "EmptyLineRule", "Encoding"];
        end
    end
end
