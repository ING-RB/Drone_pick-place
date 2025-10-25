classdef Legend < handle
    %LEGEND A class for legend in Hardware Manager scopes.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (Transient, SetObservable) % add AbortSet after legend callback is available
        %String Text for legend labels
        %   Text for legend labels, specified as a cell array of character vectors or a string array.
        String (1, :) string
        
        %Location Location to snap to sides with respect to axes.
        %   Specified as one of "north", "south", "east", "west".
        Location (1, 1) string
        
        %Position Custom position
        %   Specified as a 1x2 array of the form [left bottom] for legend
        %   normalized position in the scope window.
        Position
        
        %Visible  State of Visibility
        %   Options: "on" and "off". The default is "on".
        Visible (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(Visible, ["on", "off"])} = 'on'
    end
    
    properties (Access = private)
        %NumChannels Number of channels
        %   Specify the number of lines to draw. The default is 1.
        NumChannels (1, 1) double {mustBePositive, mustBeInteger, mustBeFinite} = 1
        
        %AllowNone
        %   Specify whether to allow setting Location and Position to "none".
        AllowNone = false;
    end
    
    events
        ScopeLegendDeleted
    end
    
    methods
        function obj = Legend(numChannels, varargin)            
            % Update number of channels
            obj.NumChannels = numChannels;
            
            defaultLocation = 'none';
            defaultPosition = [0.8, 0.8];
            defaultVisible = "on";
            defaultString = obj.getDefaultChannnelNames();
            
            % Edge case: no inputs
            if isempty(varargin)
                obj.String = defaultString;
                obj.AllowNone = true;
                obj.Location = defaultLocation;
                obj.Position = defaultPosition;
                obj.AllowNone = false;
                return;
            end      
            
            propList = lower(properties('matlab.hwmgr.scopes.Legend'));
            p = inputParser;
            
            % We need validation function for optional input when we also
            % have parameter inputs. Otherwise, the input parser interprets
            % the optional strings or character vectors as parameter names.            
            StringValidationFcn = @(x) (iscell(x) || isstring(x) || ischar(x));            

            addParameter(p, 'String', defaultString);
            addParameter(p, 'Location', defaultLocation);
            addParameter(p, 'Position', defaultPosition);
            addParameter(p, 'Visible', defaultVisible);
            
            % We need to check if the first varargin input is a property
            % name to decide if we need the optional parameter, since
            % input parser cannot handle string/char type input well.                             
            if (ischar(varargin{1}) || isStringScalar(varargin{1})) ...
                    && ismember(lower(varargin{1}), propList)
                % The first input is a property name, the user skipped the
                % optional input, no need to add optional parameter.
            else
                addOptional(p, 'LabelText', defaultString, StringValidationFcn)
            end

            try
                parse(p, varargin{:});
            catch e
                % LabelText is an internal parameter, it should be replaced
                % by String in customer-facing error message.
                errorMsg = strrep(e.message, 'LabelText', 'String');
                error(e.identifier, errorMsg);
            end
            
            if ismember("LabelText", p.Parameters)
                % When optional LabelText is provided, check both LabelText
                % and String to decide the final value
                
                if ~ismember("String", p.UsingDefaults)
                    % As long as resulting String is not using default, it
                    % should be taken as the final sting. String parameter is
                    % after label text in constructor, thus it has higher
                    % precedence.
                    obj.String = p.Results.String;
                else
                    % When String is using default, we will take LabelText as
                    % the final string. In case LabelText is also using
                    % default, it has the same default value as String.
                    obj.String = p.Results.LabelText;
                end
            else
                obj.String = p.Results.String;
            end
            
            % We need to check if both Location and Position are set
            propInInputs = setdiff(p.Parameters, p.UsingDefaults);
            logicalInd = ismember({'Location', 'Position'}, propInInputs);
            
            if all(logicalInd)
                % both Location and Position are set in the inputs
                msgID = 'hwmanagerapp:scopes:SetLegendLocationAndPosition';
                error(message(msgID));
            elseif logicalInd(1)
                % Location is set in the input
                obj.Location = p.Results.Location;
                % Position will be set automatically to "none"
            elseif logicalInd(2)
                % Position is set in the input
                obj.Position = p.Results.Position;
                % Location will be set automatically to "none"
            else
                % Set Location and Position to default values
                obj.AllowNone = true;
                obj.Location = p.Results.Location;
                obj.Position = p.Results.Position;
                obj.AllowNone = false;
            end            
            obj.Visible = p.Results.Visible;
        end
        
        function delete(obj)
            notify(obj, "ScopeLegendDeleted");
        end
        
        function set.String(obj, value)
            % Property class validation ensures valus is already converted
            % to string.
            validateattributes(value, {'string'}, {'size', [1, obj.NumChannels]});
            obj.String = value;
        end
        
        function set.Location(obj, value)
            if obj.AllowNone
                obj.Location = value;
            else
                validStrings = ["north", "south", "east", "west"];
                value = validatestring(value, validStrings);
                obj.Location = value;
                if ~strcmp(obj.Position, "none")
                    obj.AllowNone = true;
                    obj.Position = "none";
                end
                obj.AllowNone = false;
            end
        end
        
        function set.Position(obj, value)
            if obj.AllowNone
                obj.Position = value;
            else
                validateattributes(value, {'double'}, {'size', [1, 2], '>=', 0, '<=', 1});
                obj.Position = value;
                if ~strcmp(obj.Location, "none")
                    obj.AllowNone = true;
                    obj.Location = "none";
                end
                obj.AllowNone = false;
            end
        end
    end
    
    methods (Access = private)
        function names = getDefaultChannnelNames(obj)
            % Get default numbered channel names
            names = {};
            for i = 1:obj.NumChannels
                names = [names, strcat("Channel", num2str(i))];
            end
        end
        
    end
end