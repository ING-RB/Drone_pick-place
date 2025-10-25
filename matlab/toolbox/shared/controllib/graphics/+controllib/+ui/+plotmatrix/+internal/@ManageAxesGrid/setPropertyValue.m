function NewValue = setPropertyValue(this, PropertyName, PropertyValue, SetFcnHandle, SharingProperty)
% setPropertyValue - Validate the given value according to a Sharing Property and set the appropriate property
%     Input: PropertyName    - Name of property to be set
%                              (XLim, YLim, XScale, YScale,
%                              XLabel, YLabel)
%            PropertyValue   - Value of property to be set
%            SetFcnHandle    - Handle to a function that sets the
%                              value
%            SharingProperty - Property that decides how to
%                              validate 'PropertyValue'
%                              (XAxesSharing, YAxesSharing,
%                              LabelSharing)

%   Copyright 2015-2020 The MathWorks, Inc.

% Get the size and current value
[nRows, nCols] = size(this);

CurrentValue = this.(PropertyName);

% If the size of axes grid is 1-by-1, the property can be specified as a
% string/ double, rather than as a cell-array. Convert to cell-array in
% these cases

if nRows == 1 && nCols == 1 && ~iscell(PropertyValue)
    PropertyValue = {PropertyValue};
end

% Validate NewValue to be the right size
if ~all(size(PropertyValue) == size(CurrentValue))
    error(message('Controllib:general:UnexpectedError', ...
        sprintf('Incompatible value specified for %s', PropertyName)));
end

% Compare strings or doubles?
if ischar(PropertyValue{1})
    ValidateFcn = @strcmpi;
else
    ValidateFcn = @isequal;
end


% Branch according to sharing
if strcmpi(this.(SharingProperty), 'all')
    % Sharing is set to all
    
    % Validate value according to the validate function
    try
        NewValue = controllib.ui.plotmatrix.internal.ManageAxesGrid.localValidateValue(CurrentValue, PropertyValue, ValidateFcn);
        NewValue = {NewValue};
    catch
        error(message('Controllib:general:UnexpectedError', ...
            sprintf('Incompatible value specified for %s', PropertyName)));
    end
        
else
    % Sharing is set to default - Validate each column/ row according to the validate function
    if any(strcmpi(PropertyName, {'XLim', 'XScale', 'XLabel'}))
        NewValue = cell(1,nCols);
        for ct = 1:nCols
            CurrentColumn = CurrentValue(:,ct);
            NewColumn = PropertyValue(:,ct);
            % Return validation result, and the value that is
            % different in each column/ row
            try
                NewValue{ct} = controllib.ui.plotmatrix.internal.ManageAxesGrid.localValidateValue(CurrentColumn, NewColumn, ValidateFcn);
            catch
                error(message('Controllib:general:UnexpectedError', ...
                    sprintf('Incompatible value specified for %s', PropertyName)));
            end
        end
    else
        NewValue = cell(nRows,1);
        for ct = 1:nRows
            CurrentRow = CurrentValue(ct,:);
            NewRow = PropertyValue(ct,:);
            % Return validation result, and the value that is
            % different in each column/ row
            NewValue{ct} = controllib.ui.plotmatrix.internal.ManageAxesGrid.localValidateValue(CurrentRow, NewRow, ValidateFcn);
        end
    end
end
% Evaluate Set function handle with new value as input
try
    SetFcnHandle(this, NewValue);
catch
    error(message('Controllib:general:UnexpectedError', ...
        sprintf('Incompatible value specified for %s', PropertyName)))
end
end
