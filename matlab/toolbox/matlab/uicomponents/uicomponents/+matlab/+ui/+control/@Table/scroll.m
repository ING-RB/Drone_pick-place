function scroll(obj,varargin)
%SCROLL - Scroll to a certain section of a table
%
%   SCROLL(obj, direction) - scrolls to the specified location within
%   a component.  Scroll location is specified as 'top', 'bottom', 'left'
%   or 'right'.
%
%   SCROLL(obj, target, targetIndex) - scrolls to a specified row
%   or column depending on whether Row and Column are specified
%   Ex: SCROLL(obj, "row", 5)
%
%   SCROLL(obj, target, positions) - scrolls to a specific cell
%   location specified by positions, which is an array of indices where
%   the row index is specified first, then the column index
%   Ex: SCROLL(obj, "cell", [2 3])
%   See also matlab.ui.Figure/scroll

%   Copyright 2020 The MathWorks, Inc.

narginchk(2,3)

% Scroll is not supported with tables parented to a figure
if ~matlab.ui.control.internal.model.TablePropertyHandling.isValidComponent(obj)
    error(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
        'figure'));
end
sRow = 0;
sCol = 0;
switch nargin  
    case 2
        %Case for scroll call scroll(obj, direction)
        try
            newScrollLocation = convertStringsToChars(varargin{1});
            newScrollLocation = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                obj, ...
                newScrollLocation, ...
                {'top', 'bottom', 'left', 'right'});
        catch ME %#ok<NASGU>
            messageObj = message('MATLAB:hg:uitable:invalidScrollLocation', ...
                'top', 'bottom', 'left', 'right');
            
            % Use string from object
            messageText = getString(messageObj);
            
            % Create and throw exception
            exceptionObject = MException('MATLAB:ui:Table:invalidScrollLocation', messageText);
            throwAsCaller(exceptionObject);
            
        end
        
        if strcmpi("top",newScrollLocation)
            sRow = struct("Row", 1);
        elseif strcmpi("bottom",newScrollLocation)
            sRow = struct("Row", size(obj.Data, 1));
        elseif strcmpi("left",newScrollLocation)
            sCol = struct("Column", 1);
        elseif strcmpi("right",newScrollLocation)
            sCol = struct("Column", size(obj.Data, 2));
        end
    
    case 3
        %Case for scroll call scroll(obj, "row" or "column", row or column number)
        % Validate target is 'row', 'column' or 'cell'
        try
            newScrollTarget = convertStringsToChars(varargin{1});
            newScrollTarget = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                obj, ...
                newScrollTarget, ...
                {'row', 'column', 'cell'});
        catch ME %#ok<NASGU>
            messageObj = message('MATLAB:hg:uitable:invalidScrollTarget', ...
                'row', 'column', 'cell');
            
            % Use string from object
            messageText = getString(messageObj);
            
            % Create and throw exception
            exceptionObject = MException('MATLAB:ui:Table:invalidScrollTarget', messageText);
            throwAsCaller(exceptionObject);
            
        end
        % Validate targetIndex
        targetIndex = convertStringsToChars(varargin{2});
        
        
        switch(newScrollTarget)
            case 'column'
                maximum = size(obj.Data,2);
                isValidIndex = isValidNumericIndex(targetIndex, maximum);
                if ~isValidIndex && istable(obj.Data)
                    columnNames = obj.Data.Properties.VariableNames;
                    if istable(obj.Data) && ...
                            matlab.ui.control.internal.model.PropertyHandling.isString(targetIndex) && ...
                            any(strcmp(targetIndex, columnNames))
                        targetIndex = find(strcmp(targetIndex, columnNames), 1, 'first');
                        isValidIndex = true;
                    end
                end
                if ~isValidIndex
                    if istable(obj.Data)
                        
                        if matlab.ui.control.internal.model.PropertyHandling.isString(targetIndex) && ...
                                any(strcmp(targetIndex, columnNames))
                            targetIndex = find(strcmp(targetIndex, columnNames), 'first');
                        end
                        
                        messageObj = message('MATLAB:hg:uitable:invalidColumnTargetIndex', ...
                            newScrollTarget);
                    else
                        messageObj = message('MATLAB:hg:uitable:invalidNumericTargetIndex', ...
                            newScrollTarget);
                    end
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Throw exception
                    exceptionObject = MException('MATLAB:ui:Table:invalidColumnTargetIndex', messageText);
                    throwAsCaller(exceptionObject);
                end
            case 'row'
                maximum = size(obj.Data,1);
                isValidIndex = isValidNumericIndex(targetIndex, maximum);
                if ~isValidIndex
                    messageObj = message('MATLAB:hg:uitable:invalidNumericTargetIndex', ...
                        newScrollTarget);
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Throw exception
                    exceptionObject = MException('MATLAB:ui:Table:invalidRowTargetIndex', messageText);
                    throwAsCaller(exceptionObject);
                end
            case 'cell'
                
                if ~isValidCellIndex(targetIndex, size(obj.Data))
                    messageObj = message('MATLAB:hg:uitable:invalidCellTargetIndex', ...
                        newScrollTarget);
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Throw exception
                    exceptionObject = MException('MATLAB:ui:Table:invalidCellTargetIndex', messageText);
                    throwAsCaller(exceptionObject);
                end
        end
        
        if strcmpi('row' , newScrollTarget)
            sRow = struct('Row', targetIndex);
        elseif strcmpi('column', newScrollTarget)
            sCol = struct('Column', targetIndex);
        elseif strcmpi('cell', newScrollTarget)
            sRow = struct('Row',targetIndex(1));
            sCol = struct('Column', targetIndex(2));
        end
end
%Adds an identifier to ensure that duplicate calls are executed

if isa(sRow,'struct')
    sRow.Identifier = matlab.lang.internal.uuid();
    obj.RowScrollData =  sRow;
end

if isa(sCol,'struct')
    sCol.Identifier = matlab.lang.internal.uuid();
    obj.ColumnScrollData =  sCol;
end
end

function validColumnIndex = isValidNumericIndex(idx, maximum)
% A 'column' index is valid if it is a scalar or array of positive integers,
% a scalar or array of strings, a scalar char, or a cellstr
try
    validateattributes(idx,{'numeric'},{'positive','integer','real','finite','scalar','<=', maximum});
    validColumnIndex = true;
catch ME %#ok<NASGU>
    validColumnIndex = false;
end
end

function validCellIndex = isValidCellIndex(idx, dataSize)
% A 'cell' index is valid if it is an 1x2 matrix of positive integers that
% are each smaller than the size of the data
try
    validateattributes(idx,{'numeric'},{'positive','integer','real','finite','size',[1,2]});
    if any(idx > dataSize)
        validCellIndex = false;
    else
        validCellIndex = true;
    end
catch ME %#ok<NASGU>
    validCellIndex = false;
end
end