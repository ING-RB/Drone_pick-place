function str = createStackInfo(stackFrames,options)
% This function is undocumented and may change in a future release.

% Copyright 2022-2024 The MathWorks, Inc.

arguments
    stackFrames
    options.ExcludeInText (1,1) logical = false;
    options.ExcludeFileText (1,1) logical = false;
    options.MaxHeight {mustBeInfOrNonnegativeInteger} = Inf;
end

import matlab.automation.internal.diagnostics.PlainString;

if options.MaxHeight == 0
    str = PlainString("");
    return;
end

catalog = matlab.internal.Catalog('MATLAB:automation:StackInfo');
origNumFrames = numel(stackFrames);

if origNumFrames  > options.MaxHeight
    if options.MaxHeight == 1
        stackFrames(2:end) = [];
    else
        stackFrames(options.MaxHeight:end-1) = [];
    end
end

strList = arrayfun(@(frame)createStackFrameString(frame,catalog,options),...
    stackFrames,'UniformOutput',false);

if origNumFrames > options.MaxHeight && options.MaxHeight > 2
    strList{end-1} = PlainString("...");
end

str = join([PlainString.empty(1,0), strList{:}], newline);
end


function str = createStackFrameString(frame,catalog,options)
import matlab.automation.internal.diagnostics.MessageString;
import matlab.automation.internal.diagnostics.CommandHyperlinkableString;

% Handle the empty case
if isempty(frame.file)
    str = frame.name;
    if ~options.ExcludeInText
        str = catalog.getString('In',sprintf('(%s)',str));
    end
    return;
end

if frame.line == 0
    % P-coded files report line = 0. Don't show line number or hyperlink.
    str = createStackFrameWithoutLineNumber(frame, options);
else
    % Include line number and make the stack frame hyperlinkable
    str = createStackFrameWithLineNumber(frame, catalog, options);
    file = strrep(frame.file, '''', '''''');
    str = CommandHyperlinkableString(str, ...
        sprintf('opentoline(''%s'',%d,1)', file, frame.line));
end

if ~options.ExcludeInText
    str = MessageString('MATLAB:automation:StackInfo:In',str);
end
end

function str = createStackFrameWithLineNumber(frame, catalog, options)
if options.ExcludeFileText
    str = catalog.getString("StackLineExcludingFile", frame.name, frame.line);
else
    str = catalog.getString("StackLine", frame.file, frame.name, frame.line);
end
end

function str = createStackFrameWithoutLineNumber(frame, options)
if options.ExcludeFileText
    str = frame.name;
else
    str = frame.file + " (" + frame.name + ")";
end
end

function mustBeInfOrNonnegativeInteger(value)
if ~isequal(value,Inf)
    validateattributes(value,{'double'},{'scalar','integer','nonnegative'});
end
end

% LocalWords:  Hyperlinkable hyperlinkable
