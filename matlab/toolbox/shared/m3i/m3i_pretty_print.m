function output = m3i_pretty_print(obj, varargin)
% M3I_PRETTY_PRINT Pretty-print the composition hierarchy of a M3I Object.
%
%    M3I_PRETTY_PRINT (OBJ) has four optional parameter/value pairs.
%
%  'format' specifies the format to print the hierarchy in
%       'html' results in a HTML-formatted output
%       'text' results in a textual output (default)
%  'sort' specifies if the output should be sorted
%       true results in a sorted output (default)
%       false results in unsorted output
%  'showEmpty' specifies if empty attributes of object should be output
%       true results in all attributes being output (default)
%       false results in only non-empty attributes being output
%  'showDefaults' specifies if values unchanged from defaults should show
%       true results in all attributes being output (default)
%       false results in only non-default attributes being output
%  'showQualifiedName' show just name or fully qualified name
%       true shows fully qualified name of metaclass
%       false shows just the name of the metaclass (default)
%  'outputFile' specifies the destination output file
%       <fileName> Path to the destination file (default 'pp.html')
%
%  Example:
%
%     1. Pretty-print M3I object c as text.
%
%        disp (m3i_pretty_print(c))
%
%     2. Pretty-print M3I object c as html.
%
%        m3i_pretty_print (c, 'format', 'html')
%
%     3. Pretty-print M3I object c but don't sort properties and don't
%     show properties with empty values.
%
%        m3i_pretty_print (c, 'sort', false, 'format', 'html',...
%                          'showEmpty', false)
%
%     4. Pretty-print M3I object c into a specific html file.
%
%        m3i_pretty_print (c, 'outputFile', 'H:\Documents\MATLAB\Mypp.html')

% Copyright 2007-2008 The MathWorks, Inc.

p = inputParser;
p.FunctionName = 'M3I_PRETTY_PRINT';
if (~isM3IImmutableClassObject(obj))
    return;
end
obj = obj;
p.addRequired ('obj', @(x) isM3IImmutableClassObject(x));
p.addParamValue ('format', 'text', @(x) any(strcmpi(x, {'text', 'html'})));
p.addParamValue ('sort', true, @islogical);
p.addParamValue ('showEmpty', true, @islogical);
p.addParamValue ('showDefaults', true, @islogical);
p.addParamValue ('showQualifiedName', false, @islogical);
p.addParamValue ('outputFile', [m3i.utils.m3ipp.getObjectName(obj) '.html'], @ischar);
p.parse(obj,varargin{:});
ppFormat = p.Results.format;
ppSorted = p.Results.sort;
ppShowEmpty = p.Results.showEmpty;
ppShowDefaults = p.Results.showDefaults;
ppShowQualifiedName = p.Results.showQualifiedName;
ppOutputFile = p.Results.outputFile;
pp = m3i.utils.m3ipp(ppFormat, ppSorted, ppShowEmpty, ppShowDefaults, ppShowQualifiedName, ppOutputFile);
output = pp.pretty_print(obj);
if (strcmpi (ppFormat, 'html'))
  web(['file:///' generate_url(ppOutputFile)], '-new');
end
end

function result = isM3IImmutableClassObject (obj)
try
    obj;
    result = true;
catch
    disp('M3I:m3ipp:isM3IObject: Object passed is not an M3I ClassObject');
    result = false;
end

end

function url = generate_url (input)
    [path name ext] = fileparts(input);
    if (strcmpi (path, ''))
        path = pwd;
    end
    fileName = fullfile(path, [name ext]);
    url = regexprep (fileName, filesep, '/');
    url = regexprep (url, '\s', '%20');
end
