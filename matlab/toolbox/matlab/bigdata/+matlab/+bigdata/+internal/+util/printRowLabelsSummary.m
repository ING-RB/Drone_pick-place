function printRowLabelsSummary(dimName,rowLabelsStruct,detailIsLow)
% PRINTROWLABELSSUMMARY is called by tabular/summary to print a row labels summary.

%   Copyright 2024 The MathWorks, Inc.

if matlab.internal.display.isDesktopInUse
    varnameFmt = '<strong>%s</strong>';
else
    varnameFmt = '%s';
end

if isfield(rowLabelsStruct,'Size')
    fprintf('Row Times:\n');
    fprintf(matlab.internal.display.lineSpacingCharacter);
    % Print type only
    fprintf(['    ' varnameFmt ': %s\n'], dimName, rowLabelsStruct.Type);
end

if ~detailIsLow && isfield(rowLabelsStruct,'TimeStep')
    sp8 = '        ';
    if ~ismissing(rowLabelsStruct.StartTime)
        fprintf([sp8 'StartTime:  %s\n'],rowLabelsStruct.StartTime);
    end
    if ~isnan(rowLabelsStruct.TimeStep)
        fprintf([sp8 'TimeStep:  %s\n'],rowLabelsStruct.TimeStep);
    end
    if ~isnan(rowLabelsStruct.SampleRate)
        fprintf([sp8 'SampleRate:  %d\n'],rowLabelsStruct.SampleRate);
    end
    if isfield(rowLabelsStruct,'TimeZone') && ~isempty(rowLabelsStruct.TimeZone)
        fprintf([sp8 'TimeZone:  %s\n'],rowLabelsStruct.TimeZone);
    end
end
fprintf('\n');
end