function [theMessage, description, format] = xlsfinfo(filename)

if nargin < 1
    error(message('MATLAB:xlsfinfo:Nargin'));
end

% accept string filenames
filename = convertStringsToChars(filename);

if ~ischar(filename)
    error(message('MATLAB:xlsfinfo:InputClass'));
end

% Validate filename is not empty
if isempty(filename)
    error(message('MATLAB:xlsfinfo:FileName'));
end

% handle requested Excel workbook filename
filename = validpath(filename);

try
    % Don't even attempt to open an excel server if it isn't pc.
    if ~ispc
        format = '';
        [theMessage, description] = callNonComXLSFINFO(filename);
    else
        % Attempt to start Excel as ActiveX server process on local host
        % try to start ActiveX server
        try
            Excel = matlab.io.internal.getExcelInstance;
        catch exception
            warning(message('MATLAB:xlsfinfo:ActiveX'))
            format = '';
            [theMessage, description] = callNonComXLSFINFO(filename);
            return;
        end
        [theMessage, description, format] = xlsfinfoCOM(Excel, filename);
    end
catch exception
    theMessage = '';
    description =  [getString(message('MATLAB:xlsfinfo:UnreadableExcelFile')),' ', exception.message];
    if strcmp(exception.identifier, 'MATLAB:xlsread:FileFormat') || strcmp(exception.identifier,'MATLAB:xlsread:WorksheetNotActivated')
        format = 'xlCurrentPlatformText';
    end
end
end
function [m, descr] = xlsfinfoBinary(filename)

biffvector = biffread(filename);
m = 'Microsoft Excel Spreadsheet';
[~,descr] = matlab.iofun.internal.excel.biffparse(biffvector);
descr = descr';
end

function [theMessage, description] = xlsfinfoXLSX(filename)

% Unzip the XLSX file (a ZIP file) to a temporary location
baseDir = tempname;
mkdir(baseDir);
cleanupBaseDir = onCleanup(@()rmdir(baseDir,'s'));
unzip(filename, baseDir);

docProps = fileread(fullfile(baseDir,'docProps','app.xml'));
theMessage = '';
matchMessage = regexp(docProps,'<Application>(?<message>Microsoft\s+(\w+\s+)?Excel)</Application>','names');
if ~isempty(matchMessage)
    theMessage = [matchMessage.message ' Spreadsheet'];
end

workbook_xml_rels  = fileread(fullfile(baseDir, 'xl', '_rels', 'workbook.xml.rels'));
workbook_xml  = fileread(fullfile(baseDir, 'xl', 'workbook.xml'));
description = getSheetNames(workbook_xml_rels, workbook_xml);
end

function [theMessage, description] = callNonComXLSFINFO(filename)
[~, ~, ext] = fileparts(filename);
if any(strcmp(ext, matlab.io.internal.xlsreadSupportedExtensions('SupportedOfficeOpenXMLOnly')))
    [theMessage, description] = xlsfinfoXLSX(filename);
else
    [theMessage, description] = xlsfinfoBinary(filename);
end
end

% Copyright 1984-2024 The MathWorks, Inc.
