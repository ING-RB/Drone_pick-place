classdef TAPVersion13Formatter < matlab.unittest.internal.eventrecords.EventRecordFormatter & ...
                                 matlab.unittest.internal.diagnostics.ErrorReportingMixin
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Access=private, Constant)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:TAPVersion13YAMLDiagnostic');
    end
    
    methods
        function str = getExceptionEventReport(formatter, eventRecord)
            exceptionReport = formatter.getExceptionReport(eventRecord.Exception);
            parts = [createLineText({'ErrorIdentifierHeader'},eventRecord.Exception.identifier),...
                createFormattableSectionString({'ErrorReportHeader'}, indent(exceptionReport)),...
                getDiagResultParts(eventRecord.FormattableAdditionalDiagnosticResults,'AdditionalDiagnosticHeader')];
            str = createFormattableYAMLBlockString(parts,eventRecord);
        end
        
        function str = getLoggedDiagnosticEventReport(~, eventRecord)
            parts = getDiagResultParts(eventRecord.FormattableDiagnosticResults,'LoggedDiagnosticHeader');
            str = createFormattableYAMLBlockString(parts, eventRecord);
        end
        
        function str = getQualificationEventReport(~, eventRecord)
            parts = [getDiagResultParts(eventRecord.FormattableTestDiagnosticResults,'TestDiagnosticHeader'),...
                getDiagResultParts(eventRecord.FormattableFrameworkDiagnosticResults,'FrameworkDiagnosticHeader'),...
                getDiagResultParts(eventRecord.FormattableAdditionalDiagnosticResults,'AdditionalDiagnosticHeader')];
            str = createFormattableYAMLBlockString(parts, eventRecord);
        end
    end
end

function txt = getCatalogText(varargin)
catalog = matlab.unittest.internal.plugins.tap.TAPVersion13Formatter.Catalog;
txt = catalog.getString(varargin{:});
end

function txt = createLineText(labelMsgArgs,bodyTxt)
txt = sprintf("%s '%s'",getCatalogText(labelMsgArgs{:}),bodyTxt);
end

function str = createFormattableSectionString(labelMsgArgs,formattableBodyStr)
str = getCatalogText(labelMsgArgs{:}) + " |" + newline + formattableBodyStr;
end

function resultParts = getDiagResultParts(formattableResults, headerMsgKey)
formattableDiagStrings = formattableResults.toFormattableStrings();
resultParts = formattableDiagStrings.applyToNonempty(@formatResultParts);

    function result = formatResultParts(text, idx, numNonemptyStrs)
        import matlab.unittest.internal.diagnostics.indent;
        
        if numNonemptyStrs == 1
            headerMsgArgs = {headerMsgKey};
        else
            headerMsgArgs = {"Numbered" + headerMsgKey, idx};
        end
        
        result = createFormattableSectionString(headerMsgArgs, indent(text));
    end
end

function str = createFormattableYAMLBlockString(parts, eventRecord)
import matlab.unittest.internal.diagnostics.createStackInfo;
parts = [createLineText({'EventNameLabel'}, eventRecord.EventName),...
    createLineText({'EventLocationLabel'}, eventRecord.EventLocation),parts];
if ~isempty(eventRecord.Stack)
    parts(end+1) = createFormattableSectionString({'StackHeader'}, ...
        indent(createStackInfo(eventRecord.Stack)));
end
str = join(parts, newline);
end

% LocalWords:  YAML formatter Formattable unittest eventrecords plugins
% LocalWords:  formattable Strs
