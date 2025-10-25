function addStyle(obj, styleObject, varargin)
%ADDSTYLE Add style to table UI component
%
%   ADDSTYLE(tbl,s) adds a style created with the uistyle function to
%   the specified table UI component. The style is applied to the whole
%   table. The uitable must be parented to a figure created with the
%   uifigure function, or to one of its child containers.
%
%   ADDSTYLE(tbl,s,target,targetIndex) adds the style to
%   a specific row, column, or cell. For example,
%   addStyle(tbl,s,'column',3) adds the style to the third column of the
%   specified table UI component.
%
%   Example: Add Multiple Styles to Table
%      % Load data and create a table in a figure.
%      load patients
%      t = table(LastName,Gender,Age,Smoker, ...
%          Systolic,Diastolic,SelfAssessedHealthStatus);
%      t.SelfAssessedHealthStatus = categorical(t.SelfAssessedHealthStatus, ...
%          {'Poor','Fair','Good','Excellent'},'Ordinal',true);
%
%      fig = uifigure('Position',[100 500 730 267]);
%      tbl = uitable(fig,'Data',t);
%      tbl.Position = [20 10 650 246];
%
%      % Create a style that right-aligns cell contents and add it to a
%      % column in the table. 
%      s1 = uistyle;
%      s1.HorizontalAlignment = 'right';
%
%      addStyle(tbl,s1,'column','SelfAssessedHealthStatus')
%
%      % Then, create additional styles and add them to the table. 
%      s2 = uistyle;
%      s2.BackgroundColor = 'red';
%
%      s3 = uistyle;
%      s3.BackgroundColor = 'green';
%
%      s4 = uistyle;
%      s4.FontWeight = 'bold';
%      s4.FontAngle = 'italic';
%      s4.FontColor = 'blue';
%
%      LowSystolic = find(Systolic <= 130);
%      LowSystolic(:,2) = 5;
%      LowDiastolic = find(Diastolic <= 80);
%      LowDiastolic(:,2) = 6;
%
%      addStyle(tbl,s2,'column',4)
%      addStyle(tbl,s3,'row',9)
%      addStyle(tbl,s4,'cell',[LowSystolic;LowDiastolic])
%
%   See also MATLAB.UI.CONTROL.TABLE/REMOVESTYLE, UISTYLE, UITABLE
%

%   Copyright 2019-2021 The MathWorks, Inc.

    narginchk(2, 4);
    
    % addStyle is not supported with tables parented to a figure
    if ~matlab.ui.control.internal.model.TablePropertyHandling.isValidComponent(obj)
        error(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
            'figure'));
    end
    
    % Validate Style
    styleClass = 'matlab.ui.style.internal.ComponentStyle';
    if ~isa(styleObject, styleClass) || ~isscalar(styleObject)
        messageObject = message('MATLAB:ui:style:invalidStyleObject', ...
            'Style');
        me = MException('MATLAB:ui:Table:invalidStyleObject', ...
             messageObject.getString());
        throw(me)
    end

    switch nargin
        case 2
            % Default target is entire table if not specified.
            newTarget = "table";
            newIndex = {''};
            
        case 3
            % Incorrect number of input arguments
            messageObject = message('MATLAB:ui:style:invalidNumberOfInputs');
            me = MException('MATLAB:ui:Table:invalidNumberOfInputs', ...
                 messageObject.getString());
            throw(me)

        case 4
            [inputTarget, inputIndex] = varargin{:};

            % Convert strings and string arrays to chars and cellstrs
            if iscell(inputIndex)
                inputIndex = cellfun(@convertStringsToChars, inputIndex, ...
                    'UniformOutput', false);
            else
                inputIndex = convertStringsToChars(inputIndex);
            end
            
            % Validate Target and TargetIndex combinations
            % 'Target' can be a char or categorical
            if strcmpi(inputTarget, 'table') || ...
                    (iscategorical(inputTarget) && inputTarget == "table")
                inputTarget = "table";
                
                if ~isValidTableIndex(inputIndex)
                    messageObject = message('MATLAB:ui:style:invalidTargetIndex', ...
                        inputTarget);
                    me = MException('MATLAB:ui:Table:invalidTargetIndex', ...
                         messageObject.getString());
                    throw(me)
                else
                    % Ensure index is an empty char
                    inputIndex = '';
                end
            elseif strcmpi(inputTarget, 'column') || ...
                    (iscategorical(inputTarget) && inputTarget == "column")
                inputTarget = "column";
                
                if ~isValidColumnIndex(inputIndex)
                    messageObject = message('MATLAB:ui:style:invalidColumnTargetIndex', ...
                        inputTarget);
                    me = MException('MATLAB:ui:Table:invalidColumnTargetIndex', ...
                         messageObject.getString());
                    throw(me)
                else
                    % Ensure index is a row vector
                    inputIndex = reshape(inputIndex, 1, []);
                end
            elseif strcmpi(inputTarget, 'row') || ...
                    (iscategorical(inputTarget) && inputTarget == "row")
                inputTarget = "row";
                
                if ~isValidRowIndex(inputIndex)
                    messageObject = message('MATLAB:ui:style:invalidRowTargetIndex', ...
                        inputTarget);
                    me = MException('MATLAB:ui:Table:invalidRowTargetIndex', ...
                         messageObject.getString());
                    throw(me)
                else
                    % Ensure index is a row vector
                    inputIndex = reshape(inputIndex, 1, []);
                end
            elseif strcmpi(inputTarget, 'cell') || ...
                    (iscategorical(inputTarget) && inputTarget == "cell")
                inputTarget = "cell";
                
                if ~isValidCellIndex(inputIndex)
                    messageObject = message('MATLAB:ui:style:invalidCellTargetIndex', ...
                        inputTarget);
                    me = MException('MATLAB:ui:Table:invalidCellTargetIndex', ...
                         messageObject.getString());
                    throw(me)
                end
            else
                messageObject = message('MATLAB:ui:style:invalidStyleTarget', ...
                    'cell', 'row', 'column', 'table');
                me = MException('MATLAB:ui:Table:invalidStyleTarget', ...
                    messageObject.getString());
                throw(me)
            end
            
            newTarget = inputTarget;
            newIndex = {inputIndex};
    end
    
    % update style configuration
    updateStyleConfigurationStorage(obj, newTarget, newIndex, styleObject);
end

function validTableIndex = isValidTableIndex(idx)
    % A 'table' index is valid if it is empty
    validTableIndex = isempty(idx);
end

function validColumnIndex = isValidColumnIndex(idx)
    % A 'column' index is valid if it is a scalar or array of positive integers,
    % a scalar or array of strings, a scalar char, or a cellstr
    try 
        validateattributes(idx,{'numeric'},{'positive','integer','real','finite','vector'});
        validColumnIndex = true;
    catch ME %#ok<NASGU>
        validColumnIndex = (isvector(idx) & (ischar(idx) | iscellstr(idx)));
    end
end

function validRowIndex = isValidRowIndex(idx)
    % A 'row' index is valid if it is a scalar or array of positive integers
    try 
        validateattributes(idx,{'numeric'},{'positive','integer','real','finite','vector'});
        validRowIndex = true;
    catch ME %#ok<NASGU>
        validRowIndex = false;
    end
end

function validCellIndex = isValidCellIndex(idx)
    % A 'cell' index is valid if it is an Nx2 matrix of positive integers
    try 
        validateattributes(idx,{'numeric'},{'positive','integer','real','finite','size',[NaN,2]});
        validCellIndex = true;
    catch ME %#ok<NASGU>
        validCellIndex = false;
    end
end

function updateStyleConfigurationStorage(model, newTarget, newIndex, newStyle)
    matlab.ui.style.internal.StylesMetaData.addStyle(model, newTarget, newIndex, newStyle);
end