function varargout = instrhelp(obj, varargin)
%INSTRHELP Return instrument object function and property help.
%
%   INSTRHELP will be removed in a future release. For serialport,
%   tcpclient, tcpserver, udpport, visadev, bluetooth, aardvark/device,
%   and ni845x/device objects, use <a href="matlab:help help">help</a> instead.
%
%   INSTRHELP provides a complete listing of instrument object functions.
%
%   INSTRHELP('NAME') provides on-line help for the function or property,
%   NAME. If NAME is the class name of an instrument object or device group
%   object, for example, visa, a complete listing of functions and properties
%   for the object class is displayed. The on-line help for the object's
%   constructor is also displayed. If NAME is the class name of an instrument
%   object with a .m extension, the on-line help for the object's constructor
%   is displayed.
%
%   Object specific function information can be displayed by specifying
%   NAME to be object/function. For example to display the on-line
%   help for a serial port object's FPRINTF function, NAME would be
%   serial/fprintf.
%
%   Object specific property information can be displayed by specifying
%   NAME to be object.property. For example to display the on-line help
%   for a serial port object's Parity property, NAME would be serial.Parity.
%
%   OUT = INSTRHELP('NAME') returns the help text in string, OUT.
%
%   INSTRHELP(OBJ) displays a complete listing of functions and properties
%   for the object, OBJ, along with the on-line help for the object's
%   constructor. OBJ must be a 1-by-1 instrument object or a device
%   group object.
%
%   INSTRHELP(OBJ, 'NAME') displays the help for function or property, NAME,
%   for the object, OBJ.
%
%   OUT = INSTRHELP(OBJ, 'NAME') returns the help text in string, OUT.
%
%   Note, if NAME is a device object function or property or a device group
%   object function or property, the object, OBJ, must be specified.
%
%   When displaying property help, the names in the See also section which
%   contain all upper case letters are function names. The names which
%   contain a mixture of upper and lower case letters are property names.
%
%   When displaying function help, the See also section contains only
%   function names.
%
%   Example:
%       instrhelp('serial')
%       out = instrhelp('serial.m');
%       instrhelp set
%       instrhelp RecordMode
%
%       g = gpib('ni', 0, 2);
%       instrhelp(g)
%       instrhelp(g, 'EOSMode');
%       out = instrhelp(g, 'propinfo');
%
%   See also INSTRUMENT/PROPINFO, ICGROUP/PROPINFO.
%

%   Copyright 1999-2022 The MathWorks, Inc.

try
    instrument.internal.ICTRemoveFunctionalityHelper(mfilename, "Warn", "Function");
catch ex
    throwAsCaller(ex);
end

% convert to char in order to accept string datatype
varargin = instrument.internal.stringConversionHelpers.str2char(varargin);

% Error checking.
if nargin > 2
    error(message('instrument:instrhelp:invalidSyntaxArgv'));
end

if nargout > 1
    error(message('instrument:instrhelp:invalidSyntaxRet'))
end

if ~isa(obj, 'instrument')
    error(message('instrument:instrhelp:invalidArgFirst'));
end

if length(obj) > 1
    error(message('instrument:instrhelp:invalidOBJDim'));
end

if ~isvalid(obj)
    error(message('instrument:instrhelp:invalidOBJ'))
end

% Determine if a function or property name was specified.
name = '';
if (nargin == 2)
    name = varargin{1};
end

% Error checking.
if ~ischar(name)
    error(message('instrument:instrhelp:invalidArgSecond'));
end

% Find the directory where the toolbox is installed.
instrRoot = which('instrgate', '-all');
instrRoot = fileparts(instrRoot{1});
matlabioRoot = which('instrfind', '-all');
matlabioRoot = fileparts(matlabioRoot{1});

% Return results based on arguments passed in.
switch nargin
    case 1
        % Return the object's Contents file.
        classOfObject = class(obj);
        
        % Create output - either to command line or to output variable.
        switch nargout
            case 0
                % special case for serial
                if strcmpi (classOfObject, 'serial')
                    out1 = evalc('help([matlabioRoot filesep ''@'' classOfObject filesep classOfObject])');
                else
                    % Display constructor help.
                    out1 = evalc('help([instrRoot filesep ''@'' classOfObject filesep classOfObject])');
                end
                
             
                disp(out1);
                
                % Get driver specific information if a device object.
                if strcmp(classOfObject, 'icdevice')
                    out = localDisplayDriverInfo(obj);
                    for i = 1:length(out)
                        fprintf(out{i});
                    end
                end
            case 1
                % Construct driver specific information for a device object.
                if strcmp(classOfObject, 'icdevice')
                    out = localDisplayDriverInfo(obj);
                else
                    out = {''};
                end
                varargout{1} = ...
                    [help([instrRoot filesep classOfObject filesep classOfObject]) out{:}];
        end
        
        return;
    case 2
        % Initialize variables.
        errflag  = false;
        
        % Check to see if name is a function.
        pathName = localFindPath(name, class(obj), instrRoot);
        if isempty(pathName)
            pathName = localFindPath(name, class(obj), matlabioRoot);
        end
        
        if ~isempty(pathName)
            % Path existed. It was a function.
            switch nargout
                case 0
                    out = evalc('help(pathName)');
                case 1
                    out = help(pathName);
            end
        elseif any(strcmpi(name, {'clear', 'load', 'save'}))
            out = sprintf(instrgate('privateGetHelp', name));
        else
            % Check to see if name is a property.
            [errflag, out] = localGetPropDesc(name, class(obj), obj);
        end
        
        % If not a property or a function, error.
        if errflag
            if (~isempty(strmatch(name, methods(obj))))
                out = sprintf([' ' upper(name) '\n\n   ' upper(name) ' is an inherited MATLAB class method. It is not a valid\n   method for instrument objects.\n']);
                switch nargout
                    case 0
                        fprintf('\n');
                        disp(out)
                    case 1
                        varargout{1} = out;
                end
            else
                switch nargin
                    case 1
                        error(message('instrument:instrhelp:invalidNAME', varargin{ 1 }));
                    case 2
                        if isa(obj, 'visa')
                            error(message('instrument:instrhelp:invalidNAME', sprintf( '%s.%s', get( obj, 'Type' ), name )));
                        else
                            error(message('instrument:instrhelp:invalidNAME', sprintf( '%s.%s', class( obj ), name )));
                        end
                end
            end
        else
            % Create output - either to command line or to output variable.
            switch nargout
                case 0
                    fprintf('\n');
                    disp(out)
                case 1
                    varargout{1} = out;
            end
        end
end

% ----------------------------------------------------------------
% Find the pathname when the object directory and method are given.
function [errflag, out] = localGetPropDesc(prop, classtype, obj)

% Initialize output.
errflag = false;
out     = '';

if isa(obj, 'icinterface')
    % Get property help.
    try
        if isa(obj, 'visa')
            out = com.mathworks.toolbox.instrument.util.PropertyHelp.getHelp(get(obj, 'Type'), prop);
        else
            out = com.mathworks.toolbox.instrument.util.PropertyHelp.getHelp(classtype, prop);
        end
    catch
        errflag = true;
    end
    return;
end

% obj is a device object.
try
    out = com.mathworks.toolbox.instrument.device.util.PropertyHelp.getHelp(java(igetfield(obj, 'jobject')), prop);
catch
    errflag = true;
end

% ----------------------------------------------------------------
% For icdevice object's show the driver specific methods and properties.
function out = localDisplayDriverInfo(obj)

% If a device object return device specific methods and properties.
% Get the methods provided by the icdevice object's driver.
jobj = igetfield(obj, 'jobject');
driverMethodNames = getMethodNames(jobj);
if isempty(driverMethodNames)
    driverMethodNames = {};
    maxMethodLength   = 0;
    out1 = {['  There are no driver specific methods for class icdevice.' sprintf('\n')]};
else
    driverMethodNames = cell(driverMethodNames);
    maxMethodLength   = max(cellfun('length', driverMethodNames));
end

% Get the properties provided by the icdevice object's driver.
propertyNames = getProperties(jobj);
driverPropertyNames = cell(propertyNames.size, 1);
for i=1:length(driverPropertyNames)
    driverPropertyNames{i} = propertyNames.elementAt(i-1);
end

if isempty(driverPropertyNames)
    maxPropertyLength = 0;
    out2 = {['\n  There are no driver specific properties for class icdevice.' sprintf('\n')]};
else
    maxPropertyLength = max(cellfun('length', driverPropertyNames));
end

% Calculate the maximum length which will be used for spacing.
maxLength = max(maxMethodLength, maxPropertyLength);

% Print out the method names and property names.
if ~isempty(driverMethodNames)
    out1 = localPrettyPrint(driverMethodNames, maxLength, '  Driver specific methods for class icdevice:');
end

if ~isempty(driverPropertyNames)
    out2 = localPrettyPrint(driverPropertyNames, maxLength, '\n  Driver specific properties for class icdevice:');
end

% Construct output.
out = {out1{:} out2{:} sprintf('\n')};

% ----------------------------------------------------------------
% Pretty print the methods.
function out = localPrettyPrint(names, maxLength, heading)

% Calculate spacing information.
maxColumns = floor(80/maxLength);
maxSpacing = 2;
numOfRows = ceil(length(names)/maxColumns);

% Reshape the methods into a numOfRows-by-maxColumns matrix.
numToPad = (maxColumns * numOfRows) - length(names);
for i = 1:numToPad
    names = {names{:} ' '};
end
names = reshape(names, numOfRows, maxColumns);

% Print out the methods.
out = {sprintf([heading '\n\n'])};

% Loop through the methods and print them out.
for i = 1:numOfRows
    out = {out{:} sprintf('  ')};
    for j = 1:maxColumns
        m = names{i,j};
        out = {out{:} sprintf([m blanks(maxLength + maxSpacing - length(m))])};
    end
    out = {out{:} sprintf('\n')};
end

% ********************************************************************
% Find the pathname when the object directory and method are given.
function pathname = localFindPath(name, path, instrRoot)

% Path is not empty.  The file can be in one of four locations.
% instrRoot
% instrRoot\@instrument
% instrRoot\@serial, instrRoot\@gpib, instrRoot\@visa

serialRoot = fullfile(matlabroot,'toolbox','matlab','iofun','@serial');
instrRoot2 = fullfile(matlabroot,'toolbox','shared','instrument', '@instrument');
interfaceRoot = fullfile(matlabroot, 'toolbox', 'shared','instrument', '@icinterface');
% Initialize variables.
pathname = '';
allpaths = which(name, '-all');

if any(strcmpi(path, {'visa-serial', 'visa-gpib', 'visa-gpib-vxi', 'visa-vxi', 'visa-pxi', 'visa-tcpip', 'visa-usb', 'visa-rsib'}))
    path = 'visa';
end

% Case insensitive file/dir comparison for Windows 95/98.
if strcmp(computer,'PCWIN')
    name = lower(name);
end

% Loop through and check if one of the paths begins with the
% Instrument Control Toolbox's root directory + specified path.

% Check instrRoot
index = strmatch([instrRoot filesep name], allpaths);
if ~isempty(index)
    pathname = allpaths{index};
    return;
end

% Check instrRoot\@instrument
index = strmatch([instrRoot filesep '@instrument'], allpaths);
if ~isempty(index)
    pathname = allpaths{index};
    return;
end

% Check instrRoot\@icinterface
if any(strcmp(path, {'serial', 'i2c', 'Bluetooth', 'gpib', 'visa', 'tcpip', 'udp', ''}))
    index = strmatch([instrRoot filesep '@icinterface'], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
end


% Check instrRoot\@icdevice
if (any(strcmp(path, {'icdevice'})))
    index = strmatch([instrRoot filesep '@icdevice'], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
end


%%% Begin
% Check shared\testmeas\@instrument.


index = strmatch([instrRoot2], allpaths);
if ~isempty(index)
    pathname = allpaths{index};
    return;
end

% Check shared\@icinterface.

index = strmatch([interfaceRoot], allpaths);
if ~isempty(index)
    pathname = allpaths{index};
    return;
end

% If serial, look into the MATLAB serial directories.
if strcmp(path, 'serial') || isempty(path)
    % Check iofun\@serial
    index = strmatch([serialRoot filesep name], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
    
    % Check iofun\@instrument.
    index = strmatch([instrRoot2 filesep name], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
    
    % Check iofun\@icinterface.
    index = strmatch([interfaceRoot filesep name], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
else

end

%%% End

% Check instrRoot\@serial, instrRoot\@gpib or instrRoot\@visa
if ~isempty(path)
    index = strmatch([instrRoot filesep '@' path], allpaths);
    if ~isempty(index)
        pathname = allpaths{index};
        return;
    end
else
    objectPaths = {[instrRoot filesep '@gpib'], ...
        [instrRoot filesep '@visa'],...
        [instrRoot filesep '@tcpip'],...
        [instrRoot filesep '@udp'],...
        [instrRoot filesep '@instrument'],...
        [instrRoot filesep '@serial'],...
        [instrRoot filesep '@i2c'],...
        [instrRoot filesep '@Bluetooth'],...
        [instrRoot filesep '@icdevice'],...
        [instrRoot filesep '@icgroup'],...
        [instrRoot filesep '@gpib']};
    for i = 1:length(objectPaths)
        index = strmatch(objectPaths{i}, allpaths);
        if ~isempty(index)
            pathname = allpaths{index};
            return;
        end
    end
end

% Check instrRoot\instrumentdemos
index = strmatch([instrRoot 'demos' filesep name], allpaths);
if ~isempty(index)
    pathname = allpaths{index};
    return;
end


