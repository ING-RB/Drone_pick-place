classdef PropertyEditingCodeGenerator < handle
    % This class generates code for property editing actions

    % Copyright 2023 The MathWorks, Inc.
    
    properties (Access = private)
       ActionRegistrator 
    end

    events
        PropertyChanged
    end

      methods (Static, Hidden)
        function h = getInstance()
            mlock
            persistent hCodeGenerator;
            if isempty(hCodeGenerator)
                hCodeGenerator = matlab.graphics.internal.propertyinspector.PropertyEditingCodeGenerator();
                hCodeGenerator.ActionRegistrator = dictionary(string([]),matlab.internal.editor.figure.Registrator);
            end
            h = hCodeGenerator;
        end
      end
    
    methods

        % Property changed event registration
        function propertyChanged(this,~,ed)
            ws=warning('off','backtrace'); % Turning off warning stack trace during CodeGen 
            c=onCleanup(@()warning(ws));
            
            hObj = ed.Object;
            hFig = ancestor(hObj(1),'figure');
            channelID = getFigureChannelID(hFig);

            %Filter out non graphics objects objects such as Datatiptemplate 
            hObj = hObj(isgraphics(hObj));

            if isempty(hFig) || isempty(channelID) || isempty(hObj)
                return
            end

            %Create registrator for the figure if does not exist
            if ~this.ActionRegistrator.isKey(channelID)
                this.ActionRegistrator(channelID) = matlab.internal.editor.figure.Registrator();
            end
            
            %For multiple objects - register each object with the property
            for i = 1:numel(hObj)
                if ~isprop(hObj(i),ed.Property)
                    % some property change events are fired not for actual
                    % properties e.g. AD_ColormapString' for figure
                    continue;
                end
                % no code generation for matricies, will be added in a future release
                if ~this.isMultiDimValue(hObj(i).(ed.Property)) 
                    this.ActionRegistrator(channelID).put(hObj(i),ed.Property);
                end
            end
            % Notify the code generation infratructure about the new event
            matlab.graphics.interaction.generateLiveCode(hObj(1), matlab.internal.editor.figure.ActionID.PROPERTY_EDITED);
        end

        % Generates code for the given figure
        function code = generateCode(this, hFig)
            ws = warning('off', 'backtrace'); % Turning off warning stack trace during CodeGen 
            c = onCleanup(@()warning(ws));
        
            code = {};
        
            if ~this.isvalidFigure(hFig)
                return
            end
        
            channelID = getFigureChannelID(hFig);
            
            % Get the objects for the specified figure
            objects = this.ActionRegistrator(channelID).getKeys();
            
            % Sort the objects by type
            % Order is: Figure, Axes, then others
            sortedObjects = filterAndSortObjects(objects);
            for i = 1:length(sortedObjects)
                hObj = sortedObjects(i);
        
                % Get the edited properties for the given object
                propertiesEdited = this.ActionRegistrator(channelID).get(hObj);
        
                % ChildOrder, type, and findobj(...) string
                [childIndex, type, findObjectLine] = this.getObjectSpecificInfo(hObj, propertiesEdited, hFig);
        
                if ~any(contains(code, findObjectLine))
                    code{end+1} = findObjectLine; %#ok<AGROW>
                end
        
                code = [code this.getPropertyEditCode(hObj, propertiesEdited, childIndex, type)]; %#ok<AGROW>
            end
        end

        function info = getFigureInfo(this,figID)
            info = [];
            if this.ActionRegistrator.isKey(figID)
                info = this.ActionRegistrator(figID);
            end

        end

        function removeFigureInfo(this,figID)
            if this.ActionRegistrator.isKey(figID)
                this.ActionRegistrator(figID)=[];
            end
        end
    
    end


    methods (Access = private)

        function ret = isvalidFigure(this,hFig)
            ret =  ~(isempty(hFig) || ~this.ActionRegistrator.isKey(getFigureChannelID(hFig)));
        end

        function propChangedStr = getPropertyEditCode(this,hObj,propertiesEdited,index,type)
            propChangedStr = {};
            % Adds property set code lines
            for j = 1:numel(propertiesEdited)
                property = propertiesEdited{j};
                value = hObj.(property);

                % Scalar/Arrays are direct property sets
                value = this.getFormattedValue(property,value);
                varName = this.getVarName(type,hObj,propertiesEdited);
                if isempty(index)
                    propChangedStr{end+1} = sprintf('%s.%s = %s',varName,property,value); %#ok<AGROW>
                else
                    propChangedStr{end+1} = sprintf('%s(%d).%s = %s',varName,index,property,value); %#ok<AGROW>
                end
            end
        end

        % Stringifies the given value
        function str = getFormattedValue(this,property,val) %#ok<INUSD>
            if isa(val,'matlab.lang.OnOffSwitchState')
                % can't be converted to a string as is using the
                % datatoolsservices, convert to string first
                val = string(val);
            end
            if iscell(val)
                % for cell arrays this utility returns a string with
                % formatted qoutes, cab be used as is in the generated code - e.g  {"1";"2"}
                 str = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(val);
            elseif endsWith(property,'fcn','IgnoreCase',true) && ~isa(val,'function_handle')
                % For function callbacks e.g. hAxes.ButtonDownFcn =
                % disp("hello")  replace single quotes with double quotes - g3279309
                 if  startsWith(val,"""") || startsWith(val,"'")
                     str = val;
                 else
                    str = escapeQoutes(val);
                    str = strcat("""",str,"""");
                 end
             else
                %Stringify the rest of the values using the variable editor
                %utils 
                fdu = internal.matlab.datatoolsservices.FormatDataUtils;
                str = fdu.formatSingleDataForMixedView(val);                              
                str = str{1};    
            end
        end


        function [childIndex,type,findObjectsLine] = getObjectSpecificInfo(this,hObj,propertiesEdited,hFig) %#ok<INUSD>

            % Use type be defualt 
            type = '';
            if isprop(hObj,'Type')
                type = hObj.Type;
            end

            % There is a fundamental problem with using DispalyNAme in findobj. 
            % When DisplayName is edited using the Inspector we dont know if this was an actual edit or an initial set of DispalyName.
            % If this was an edit of a pre - existing DispalyName then we can use it in findobj e.g.:
            % data1 = findobj(gcf,"DisplayName","data1"), 
            % Otherwise, if this value was set let's say from an empty to 'foo', then we can't use it in findobj and need to generate:
            % hLine = findobj(gcf,"Type","line")
            % hLine.DispalyName = 'foo';
            % Therefore the assumption made in the code : if dispalyname was not modified using the Inspector but exists - use it, otherwise dont use it. 
           
            wasDisplayNameEdited = any(contains(propertiesEdited,'DisplayName'));
            displayName = '';
            if ~wasDisplayNameEdited && isprop(hObj,'DisplayName') && ~isempty(hObj.DisplayName)
                displayName = hObj.DisplayName;
            end
            allObjs = [];
            % Use type if exists - objects such as NumericRuler dont have
            % the type property
            if ~isempty(type)
                varName = this.getVarName(type);
                % Annotations don't work with findobj
                if hObj.HandleVisibility == "on" && ~isAnnotation(hObj)
                    if type == "figure"
                        findObjectsLine =  sprintf('%s = gcf',varName);
                    else
                        if isempty(displayName)
                            findObjectsLine = sprintf('%s = findobj(gcf,''Type'',''%s'')',varName,type);
                            allObjs = findobj(hFig,'type',type);
                        else
                            varName = this.getVarName(displayName,hObj,propertiesEdited);
                            findObjectsLine = sprintf('%s = findobj(gcf,''DisplayName'',''%s'')',varName,displayName);
                            allObjs = findobj(hFig,'DisplayName',displayName);
                            type = displayName;
                        end
                    end
                else
                    findObjectsLine = sprintf('%s = findall(gcf,''Type'',''%s'')',varName,type);
                    allObjs = findall(hFig,'type',type);
                end
            else
                className = split(class(hObj),'.');
                className = className{end};
                varName = this.getVarName(className);
                if hObj.Internal
                    findObjectsLine = sprintf('%s = findobjinternal(gcf,''-isa'',''%s'')',varName,class(hObj));
                    allObjs = findobjinternal(hFig,'-isa',class(hObj));
                elseif hObj.HandleVisibility == "on"
                    findObjectsLine = sprintf('%s = findobj(gcf,''-isa'',''%s'')',varName,class(hObj));
                    allObjs = findobj(hFig,'-isa',class(hObj));
                else
                    findObjectsLine = sprintf('%s = findall(gcf,''-isa'',''%s'')',varName,class(hObj));
                    allObjs = findall(hFig,'-isa',class(hObj));
                end
                type = className;
            end

            childIndex = [];
            if ~isscalar(allObjs)
                childIndex = find(allObjs == hObj);
            end
        end

        % Returns the variable name based on the current objext/value
        function varName = getVarName(~,rawName,hObj,propertiesEdited) 
            varName = ''; %#ok<NASGU>
            % Use DispalyName as a variable name if possible
            if nargin > 2
                wasDisplayNameEdited = any(contains(propertiesEdited,'DisplayName'));
                if ~wasDisplayNameEdited &&...
                        isprop(hObj,'DisplayName')&&...
                        ~isempty(hObj.DisplayName)
                    %get rid of special characters
                    varName = regexprep(hObj.DisplayName, '[^a-zA-Z0-9]', '');
                    return
                end
            end
            % e.g. axes --> hAxes
            rawName = lower(rawName);
            rawName(1) = upper(rawName(1));
            varName = ['h' rawName];
        end

        function ret = isMultiDimValue(~,val)
            [n,m] = size(val);
            ret = n > 1 && m > 1;
        end
    end
end

function channel = getFigureChannelID(f)
if isprop(f, 'FigureChannelId')
    channel = get(f, 'FigureChannelId');
else
    channel = matlab.ui.internal.FigureServices.getUniqueChannelId(f);
end
end

% Helper function that tells if an object is an annotation
function bool = isAnnotation(object)
bool = isa(object,'matlab.graphics.shape.internal.OneDimensional') ||  isa(object,'matlab.graphics.shape.internal.TwoDimensional');

end

% Helper function that sorts objects based on what type they are (fig, ax, etc.)
function sortedObjects = filterAndSortObjects(keys)
    % Determine if the handles are valid before sorting them
    isValid = arrayfun(@(h) isgraphics(h), [keys{:}]);

    % Extract only valid keys
    validKeys = keys(isValid);

    % Convert to array
    validHandles = [validKeys{:}];

    % Filter objects by type
    figObjects = findobj(validHandles, 'flat', '-isa', 'matlab.ui.Figure');
    axObjects = findobj(validHandles, 'flat', '-isa', 'matlab.graphics.axis.AbstractAxes');
    otherObjects = setdiff(validHandles, [figObjects; axObjects], 'stable');

    % Combine the objects back and ensure they are column vectors
    sortedObjects = [figObjects(:); axObjects(:); otherObjects(:)];
end



function strOut = escapeQoutes(strIn)

% get rid of single qoutes inside the string
strIn = string(strIn);
%singleQuote = '''';
strOut = strrep(strIn, "'", """");

% get rid of single qoutes inside the string
singleQ = """";
strOut = strrep(strOut, singleQ, singleQ.append(singleQ));
end