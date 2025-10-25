classdef TableDiagnostic < matlab.unittest.diagnostics.Diagnostic
    % This class is undocumented and may change in a future release.

    % TableDiagnostic - Diagnostic containing a table.

    % Copyright 2016-2021 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Table table;
        Header;
    end

    methods (Static)
        function bool = supports(value)
            bool = isText(value) || isPrimitiveNumeric(value) || isOtherSupportedType(value);
        end
    end

    methods
        function diag = TableDiagnostic(aTable, aHeader)
            arguments
                aTable table;
                aHeader (1,1) matlab.unittest.internal.diagnostics.FormattableString = "";
            end
            diag.Table = aTable;
            diag.Header = aHeader;
        end

        function diagnose(diag)
            import matlab.unittest.internal.diagnostics.PlainString;
            import matlab.unittest.internal.diagnostics.BoldableString;

            t = diag.Table;
            variableNames = t.Properties.VariableNames;
            contents = strings(3+height(t), width(t)); % 3 extra rows for header, underline, blank line
            for idx = 1:width(t)
                header = variableNames{idx};
                values = t.(header);
                contents(:,idx) = formatColumn(header, values);
            end

            columnHeaders = [BoldableString.empty, arrayfun(@BoldableString, contents(1,:))];
            columnSpacing = "    ";
            body = contents(2:end,:).join(columnSpacing, 2).join(newline);
            completeTable = columnHeaders.join(columnSpacing).appendNewlineIfNonempty.concatenateIfNonempty(body);
            diag.DiagnosticText = diag.Header.appendNewlineIfNonempty + completeTable.indentIfNonempty;
        end
    end
end

function bool = isText(value)
bool = builtin("iscellstr",value) || builtin("isstring",value);
end

function bool = isPrimitiveNumeric(value)
bool = builtin("isnumeric",value);
end

function bool = isOtherSupportedType(value)
bool = builtin("isa",value,"categorical") || builtin("isa",value,"duration") || builtin("isa",value,"datetime");
end

function strs = formatColumn(header, values)
import matlab.unittest.internal.diagnostics.TableDiagnostic;

assert(TableDiagnostic.supports(values));

if isText(values)
    strs = splitlines(string(values)); % Use text as-is
elseif isPrimitiveNumeric(values)
    strs = splitlines(formattedDisplayText(full(values), NumericFormat="longg"));
    strs(end) = []; % Remove trailing newline
    strs = strs.replace(" ", "");  % Display numbers as compactly as possible
else
    strs = splitlines(formattedDisplayText(values));
    strs(end) = []; % Remove trailing newline
end

strs = [header; ""; ""; strs.strip.pad]; % Header, underline, blank line, rows
strs = strs.pad("both");
strs(2) = strs(2).replace(" ", "_");
end

% LocalWords:  Boldable strs isstring iscategorical isduration splitlines longg isdatetime
