classdef TicksEditorValidator < handle
    
    % This function is used in the JavaScript Ticks Editor to evaluate and validate the
    % Ticks values manually entered by the user.
    
    % Copyright 2017-2022 The MathWorks, Inc.
    
    
    methods (Static)
        % Validates datetime values.
        % Recieves a vector of strings and tries to convert each value to
        % datetime using the format of the currently inspected object.
        % Also checks if the values are in increasing order so that they
        % can be used as ticks values in the axes
        function [invalidInd] = validateTickValues(values, propName, channel, hAx)
            arguments
                values
                propName char
                channel char = ''
                hAx = [];
            end

           if isempty(hAx)
                hAx = getInspectedObject(channel);
           end
            
            origValue = hAx.(propName);
            invalidInd = [];      
            
            if isdatetime(origValue)  || isduration(origValue)
                for i = 1:numel(values)  
                    
                    if isdatetime(origValue)
                        try
                            datetime(values{i}, ...
                                'InputFormat', origValue.Format);
                        catch
                            % collect the indecies of the elements that cannot
                            % be converted to datetime
                            invalidInd = [invalidInd,i]; %#ok<AGROW>
                        end
                    else
                        iFormat = origValue.Format;
                        if isempty(origValue)
                            firstChar = propName(1);
                            limits = hAx.([firstChar,'Lim']);
                            iFormat = limits.Format;                            
                        end
                        if isempty(internal.matlab.datatoolsservices.VariableConversionUtils.getDurationFromText(char(values{i}),iFormat))
                            invalidInd = [invalidInd,i]; %#ok<AGROW>
                        end
                    end
                    
                end
                
                %check if the values are in increasing order
                if isempty(invalidInd)
                    d = [];
                    if isdatetime(origValue)
                        d =  datetime(values, ...
                            'InputFormat', origValue.Format);
                    else
                        for j = 1:numel(values)
                            d = [d internal.matlab.datatoolsservices.VariableConversionUtils.getDurationFromText(values{j},origValue.Format)]; %#ok<AGROW>
                        end
                    end
                    invalidInd = find(diff(d) > 0 == 0) ;
                end
            end            
            invalidInd = invalidInd - 1; % client side is zero based               
        end    
        
        
        % Recieives an index and returns a tick that can be positioned at that location in the current axes                      
        function [tick,label] = getNewTickAt(index, propName, channel, hAx)
            arguments
                index (1,1) double
                propName char
                channel char = ''
                hAx = [];
            end
            
            if isempty(hAx)
                hAx = getInspectedObject(channel);
            end            
            origTicks  = hAx.(propName);
            
            % get the limits
            firstChar = propName(1);
            limits = hAx.([firstChar,'Lim']);
                                       
            % if this is the first tick to be added, put it at the lowest
            % limit value
            if isempty(origTicks)
                tick = limits(1); 
                label = getLabelForTick(tick, hAx,firstChar);    
                tick = char(tick);
                return
            end            
            
            index = index + 1; % 1 based index            
            if(index > numel(origTicks)) % append a tick to the end of the array                 
                if numel(origTicks) == 1   
                    % there is only one tick, add another one, 
                    tick = origTicks(1) + diff(limits)/5;
                else
                    % there are two or more ticks
                    tick = origTicks(end) + mean(diff(origTicks));
                end
            else
                % add a tick between two existing values
                tick = mean([origTicks(index - 1),origTicks(index )]);
            end                                            
            label = getLabelForTick(tick, hAx,firstChar);         
            tick = char(tick);                      
        end
                       
        % Get the values from the clipboard for paasting into the Ticks
        % column of the Ticks table
        function [result,propName,errMsg,isClipboardEmpty] = validateClipboardData(propName, value2Paste, channel, hObj)
            arguments
                propName char
                value2Paste
                channel char = ''
                hObj = [];
            end
            result = [];errMsg = NaN;
            
            % Get the object
            if isempty(hObj)
                hObj = getInspectedObject(channel);
            end
            
            % Get the value from the clipboard
            %value2Paste = strtrim(clipboard('paste'));
            value2Paste = strtrim(value2Paste);
            
            isClipboardEmpty = isempty(value2Paste);
            if isClipboardEmpty
                return
            end
            
            % Get the ruler that we are about to set
            hRuler = local_getRuler(hObj,propName);
            % Clone the ruler for data validation, we use the cloned
            % object as an indicator if the current data can be set on the
            % original object without erroring out.
            % If setting the data resluts in an error we send that error to
            % the client
            copyhRuler = local_cloneObject(hRuler);
            
            if isa(hRuler,'matlab.graphics.axis.decorator.DatetimeRuler')
                value2Paste = cellstr(split(value2Paste));                
                try
                    % Try the convert the clipboard data to datetime
                    % and set it on the ruler
                    copyhRuler.TickValues = datetime(value2Paste,'InputFormat',hRuler.TickValues.Format);
                catch E
                    errMsg =  E.message;
                    return
                end
            else
                % In case of a numeric ruler, just convert the data to
                % numeric
                newVal = str2num(value2Paste); %#ok<ST2NM>
                if ~isempty(newVal)
                    value2Paste = newVal;
                end
                % Attempt to set the Ticks, if there is an error, send
                % it to the client
                try
                    copyhRuler.TickValues = value2Paste;
                catch E
                    errMsg =  E.message;
                    return
                end
                
            end
            result = value2Paste;
        end
        
        
        
        % Evaluates the incoming value and retuns the result if and only if the
        % result is a numeric scalar.
        function ret = ticksEditorEval(val)
            ret = [];
            try
                ret =  evalin('base',val);
                if ~isscalar(ret) || isnan(ret) || ~isnumeric(ret)
                    ret = [];
                end
            catch
            end
        end
    end
end


function label = getLabelForTick(tick,hAx,firstChar)

cTick = tick;
ruler = hAx.([firstChar,'Axis']);

% For datetime use the format that th ruler has
if isa(ruler,'matlab.graphics.axis.decorator.DatetimeRuler') || isa(ruler,'matlab.graphics.axis.decorator.DurationRuler')
    cTick.Format = ruler.TickLabelFormat;             
end

if isduration(cTick)    
    % get rid of hr... at the end
    s = string(cTick).split(' ');    
    label = char(s(1));
else
    label = char(cTick);
end

end

%Returns the currently incpected object (Axes)
function hAx = getInspectedObject(channel)
    arguments
        channel = [];
    end

    if isempty(channel)
        channel = '/PropertyInspector';
    end
    i   = internal.matlab.inspector.peer.InspectorFactory.createInspector('default', channel);
    % TODO: to handle multiple objects
    hAx = i.handleVariable;
end


function obj = local_cloneObject(hObj)
st = matlab.graphics.annotation.internal.getCopyStructureFromObject(hObj);
obj = matlab.graphics.annotation.internal.getObjectFromCopyStructure(st);
end


function hRuler = local_getRuler(obj,propName)

firstChar = propName(1);
rulerName = [firstChar,'Axis'];

if isprop(obj, rulerName)
    hRuler = obj.(rulerName);
else
    % colorbar
    hRuler = obj.OriginalObjects.Ruler;
end
end
