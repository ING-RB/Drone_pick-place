classdef (Hidden, HandleCompatible) UnitDisplayer < matlab.mixin.CustomDisplay
    %   This class is for internal use only. It may be removed in the future.
     
    %   This class is used to display units.
    %   To add a unit to a property, add a Hidden property with the same
    %   name and suffix "Units" with the unit value specified as a 
    %   character vector. 
    %
    %     classdef UnitDisplayExample < fusion.internal.UnitDisplayer
    %         properties
    %             Threshold = 2;
    %         end
    %
    %         properties (Hidden)
    %             ThresholdUnits = 'm';
    %         end
    %     end
    %
    %   NOTE: There is an additional method required for System Objects.
    %   The matlab.System class and fusion.internal.UnitDisplayer both 
    %   define displayScalarObject. To resolve this, add the following code
    %   block:
    %
    %     methods (Access = protected)
    %         function displayScalarObject(obj)
    %             displayScalarObjectWithUnits(obj);
    %         end
    %     end
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    methods (Access = protected)
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj)
        end
        
        function displayScalarObjectWithUnits(obj)
            % Print the header
            hdr = getHeader(obj);
            fprintf('%s\n',hdr);   
            
            % For the body, get the groups, formatting and loop through
            % each group:
            
            groups = getPropertyGroups(obj);
            % groups.PropertyList can be a struct or cell array. Reformat:
            propGroups = parseGroups(groups);
            
            isLoose = strcmp(matlab.internal.display.formatSpacing, 'loose');
            
            % Loop through the groups and display each.
            for n = 1:numel(groups)
                printGroup(obj, propGroups(n));
                
                % If format is "LOOSE", add a return after each group
                if isLoose
                     fprintf('\n');
                end
            end
        end
    end

    methods (Access = private)
        function printGroup(obj, propGroup)
            % PRINTGROUP print a single property group propGroup
            %
            % propGroup is a struct with fields:
            %   Title  - the property group title
            %   Names  - a cell array of property names in this group.
           
            propNames = propGroup.Names;
            numProps = numel(propNames);
            
            namesToDisp = cell(numProps,1);
            valsToDisp  = cell(numProps,1);
            [unitsToDisp{1:numProps,1}] = deal('');
           
            % Loop through each property in this propGroup and gather
            % name, value and units.
            for propIdx = 1:numProps
                
                thisprop = propNames{propIdx};
                namesToDisp{propIdx,:} = thisprop;
                
                valueOfProp = obj.(thisprop);
                if ~ (isa(valueOfProp, 'char') || isa(valueOfProp, 'string'))
                    valsToDisp{propIdx,:} = numericVal2Str(valueOfProp);
                    unitsToDisp{propIdx,:} = propunits(obj, thisprop);
                else  % a character or string
                    if isa(valueOfProp, 'char')
                        quote = '''';
                    else % isa(valueOfProp, 'string')
                        quote = '"';
                    end
                    valsToDisp{propIdx,:} = [quote char(valueOfProp) quote];
                end
            end
            
            % Convert cell arrays to justified display strings and concatenate.
            propInfo = formatPropGroup(namesToDisp, valsToDisp, unitsToDisp);
            
            % Print the section title, if it's not empty
            if ~isempty(propGroup.Title)
                fprintf('   %s\n',propGroup.Title);
            end
            
            % Print the properties, values and bodies for this group
            fprintf('    %s\n',string(propInfo));

        end
        
        function str = propunits(obj, propName)
            % PROPUNITS - get this units char array for property propName
            if isprop(obj,[propName 'Units'])
                str = obj.([propName 'Units']);
            else
                str = '';   % no units supplied
            end
        end        
    end
    
    methods (Static, Hidden)
        function s = squaredSym()
            s = char(178);
        end
        
        function s = uTSym()
            s = [char(181) 'T'];
        end
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.UnitDisplayerCG';
        end
    end
    
end

function str = numericVal2Str(val)
%NUMERICVAL2STR convert val to a string, properly formatted.

fmt = getFloatFormat(class(val));

if isscalar(val) && (isnumeric(val) || islogical(val))
    if isa(val, 'double') || isa(val, 'single')
        str = num2str(val, fmt);
    else
        str = strtrim(evalc('disp(val)'));
    end
elseif isnumeric(val) && isrow(val) && size(val,2) < 5 %special case 1x4, 1x3, and 1x2
    propStr = num2str(val, fmt);
    str = [ '[' strjoin(strsplit(propStr),' ') ']' ];
else  %too big to display. Just show size and type like a struct
    sz = size(val);
    szStr = "[" + sz(1) + join(compose("%c%d",char(10799),sz(2:end)),"");
    str = char(compose("%s %s]",szStr, class(val)));  
end
end % numericVal2Str

function propInfo = formatPropGroup(propNamesCellStr, propValsCellStr, propUnitsCellStr)
%FORMATPROPGROUP - format the body of a property group
propNames = strjust(char(propNamesCellStr(:)));
propVals = char(propValsCellStr(:));
propUnits = char(propUnitsCellStr(:));
propInfo = [propNames, repmat(': ',size(propNames,1),1), propVals, ...
    repmat('    ',size(propNames,1),1), propUnits];
end

function propGroup = parseGroups(groups)
% PARSEGROUPS - Convert groups to a struct array (1 element per group)
%   'Title' - title of section
%   'Names' - cell array of names of properties in this group

numGroups = numel(groups);
titles = cell(1,numGroups);
names = cell(1, numGroups);
for ii=1:numGroups
    titles{ii} = groups(ii).Title;
    pl = groups(ii).PropertyList;
    if isstruct(pl)
        names{ii} = fieldnames(pl);
    else % cell array
        names{ii} = pl;
    end
end
propGroup = struct('Title', titles, 'Names', names);

end % formatPropGroup

function fmt = getFloatFormat(cls)
% Display for double/single will follow 'format long/short g/e' or 'format bank'
% from the command window. 'format long/short' (no 'g/e') is not supported
% because it often needs to print a leading scale factor.

%Taken from table code
%
switch lower(matlab.internal.display.format)
    case {'short' 'shortg' 'shorteng'}
        dblFmt  = '%.5g    ';
        snglFmt = '%.5g    ';
    case {'long' 'longg' 'longeng'}
        dblFmt  = '%.15g    ';
        snglFmt = '%.7g    ';
    case 'shorte'
        dblFmt  = '%.4e    ';
        snglFmt = '%.4e    ';
    case 'longe'
        dblFmt  = '%.14e    ';
        snglFmt = '%.6e    ';
    case 'bank'
        dblFmt  = '%.2f    ';
        snglFmt = '%.2f    ';
    otherwise % rat, hex, + fall back to shortg
        dblFmt  = '%.5g    ';
        snglFmt = '%.5g    ';
end

if strcmpi(cls, 'double')
    fmt = dblFmt;
else
    fmt = snglFmt;
end

end
