function [numericData, textData, rawData, customOutput] = xlsread(file, sheet, range, mode, customFun)

rawData = {};
Sheet1 = 1;
if nargin < 2
    sheet = Sheet1;
    range = '';
elseif nargin < 3
    range = '';
end

% handle input values
if nargin < 1 || isempty(file)
    error(message('MATLAB:xlsread:FileName'));
end

[file, sheet, range] = convertStringsToChars(file, sheet, range);

if ~ischar(file)
    error(message('MATLAB:xlsread:InvalidFileName'));
end

% Resolve filename
try
    file = validpath(file);
catch exception
    error(message('MATLAB:xlsread:FileNotFound', file, exception.message));
end
[~,~,ext] = fileparts(file);
openXMLmode = any(strcmp(ext, matlab.io.internal.xlsreadSupportedExtensions('SupportedOfficeOpenXMLOnly')));

if nargin > 1
    % Verify class of sheet parameter
    if ~ischar(sheet) && ...
            ~(isnumeric(sheet) && length(sheet)==1 && ...
            floor(sheet)==sheet && sheet >= -1)
        error(message('MATLAB:xlsread:InvalidSheet'));
    end

    if isequal(sheet,-1)
        range = ''; % user requests interactive range selection.
    elseif ischar(sheet)
        if ~isempty(sheet)
            % Parse sheet and range strings
            if contains(sheet,':')
                % Range was specified in the 2nd input argument named sheet
                % Swap them and ignore the third argument.
                if nargin == 3 || ~isempty(range)
                    warning(message('MATLAB:xlsread:thirdArgument'));
                end
                range = sheet;
                sheet = Sheet1;% Use default sheet.
            end
        else
            sheet = Sheet1; % set sheet to default sheet.
        end
    end
end
if nargin > 2
    % verify class of range parameter
    if ~ischar(range)
        error(message('MATLAB:xlsread:InvalidRange'));
    end
end
if nargin >= 4
    % verify class of mode parameter
    if ~isempty(mode) && ~(strcmpi(mode,'basic'))
        warning(message('MATLAB:xlsread:InvalidMode'));
        mode = '';
    end
else
    mode = '';
end

mode = convertStringsToChars(mode);

%Decide mode
basicMode = ~ispc;
if strcmpi(mode, 'basic')
    basicMode = true;
end
if ispc && ~basicMode
    try
        Excel = matlab.io.internal.getExcelInstance;
    catch exc   %#ok<NASGU>
        warning(message('MATLAB:xlsread:ActiveX'));
        basicMode = true;
    end
end

if basicMode
    if openXMLmode
        if isequal(sheet, -1)
            sheet = 1;
            warning(message('MATLAB:xlsread:InteractiveIncompatible'));
        end
    else
        if ~isempty(range)
            warning(message('MATLAB:xlsread:RangeIncompatible'));
        end
        if isequal(sheet,1)
            sheet = '';
        elseif isequal(sheet, -1)
            sheet = '';
            warning(message('MATLAB:xlsread:InteractiveIncompatible'));
        elseif ~ischar(sheet)
            error(message('MATLAB:xlsread:InvalidSheetBasicMode'));
        end
    end
end

if nargin >= 5
    if basicMode
        warning(message('MATLAB:xlsread:Incompatible'))
    elseif ~isa(customFun,'function_handle')
        warning(message('MATLAB:xlsread:NotHandle'));
        customFun = {};
    end
else
    customFun = {};
    if nargout > 3
        error(message('MATLAB:xlsread:NoHandleForCustom' ) )
    end
end

customFun = convertStringsToChars(customFun);

% Read the spreadsheet with the appropriate mode reader.
customOutput = {};
try
    if ~basicMode
        [numericData, textData, rawData, customOutput] = xlsreadCOM(file, sheet, range, Excel, customFun);
    else
        if openXMLmode
            [numericData, textData, rawData] = xlsreadXLSX(file, sheet, range);
        else
            if nargout > 2
                [numericData, textData, rawData] = xlsreadBasic(file,sheet);
            else
                [numericData, textData] = xlsreadBasic(file,sheet);
            end
        end
    end
catch exception
    if isempty(exception.identifier)
        exception = MException('MATLAB:xlsreadold:FormatError','%s', exception.message);
    end
    throw(exception);
end

end

%   Copyright 1984-2024 The MathWorks, Inc.
