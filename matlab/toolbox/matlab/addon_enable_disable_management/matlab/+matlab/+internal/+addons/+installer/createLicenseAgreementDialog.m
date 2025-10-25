function agreed = createLicenseAgreementDialog(Title, licenseText, agreeButtonText, cancelButtonText)
% CREATE LICENSE AGREEMENT DIALOG
%
% This function creates a dialog with a license agreement text and
% two buttons: "I Agree" and "Cancel"
%
% INPUTS:
%   Title          - (char) The title of the dialog window.
%   licenseText    - (char) The text of the license agreement to display.
%   agreeButtonText- (char) The text to display on the "Agree" button.
%   cancelButtonText- (char) The text to display on the "Cancel" button.
%
% OUTPUTS:
%   agreed         - (logical) Returns true if the user clicks "Agree",
%                    false if the user clicks "Cancel" or closes the dialog.
%
% EXAMPLE:
%   agreed = createResponsiveLicenseDialog('License Agreement', ...
%       'Please read the following license agreement...', 'Agree', 'Cancel');
%
%
% See also: matlab.addons.install

% Copyright 2025 The MathWorks Inc.

% Get the screen size
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);

% Define the minimum size for the dialog
minWidth = 400;
minHeight = 300;

% Define the size of the dialog
dialogWidth = 400;
dialogHeight = 300;

% Calculate the position to center the dialog
xPos = (screenWidth - dialogWidth) / 2;
yPos = (screenHeight - dialogHeight) / 2;

% Create a figure for the dialog, centered on the screen
fig = uifigure('Name', Title, ...
    'Position', [xPos yPos dialogWidth dialogHeight], ...
    'Visible', 'off', ...
    'AutoResizeChildren', 'off', ...
    'Tag', 'addOnLicenseAgreementDialog', ...
    'SizeChangedFcn', @(src, event) enforceMinSize(src, minWidth, minHeight));
% Store the agreement status
setappdata(fig, 'UserAgreed', false);

% Create a grid layout for the figure
grid = uigridlayout(fig, [3, 1]); % Three rows, one column
grid.RowHeight = {'1x', 'fit', 'fit'}; % Proportional heights for rows
grid.ColumnWidth = {'1x'}; % Single column


% Create a text area for the license text with a scrollable area
licenseTextArea = uitextarea(grid, ...
    'Value', licenseText, ...
    'Editable', 'off', ...
    'HorizontalAlignment', 'left');

% Create a horizontal box layout for the buttons
buttonLayout = uigridlayout(grid, [1, 3]); % One row, two columns
buttonLayout.ColumnWidth = {'1x', 'fit', 'fit'}; % Equal width for buttons

% Define button size
buttonWidth = 80;
buttonHeight = 25;
buttonSpacing = 10;

% Create the "Agree" button
agreeButton = uibutton(buttonLayout, ...
    'Text', agreeButtonText, ...
    'Position', [dialogWidth - 2*buttonWidth - 2*buttonSpacing, 20, buttonWidth, buttonHeight], ...
    'ButtonPushedFcn', @(btn, event) agreeCallback(fig));
agreeButton.Layout.Column = 2;

% Create the "Cancel" button
cancelButton = uibutton(buttonLayout, ...
    'Text', cancelButtonText, ...
    'Position', [dialogWidth - buttonWidth - buttonSpacing, 20, buttonWidth, buttonHeight], ...
    'ButtonPushedFcn', @(btn, event) cancelCallback(fig));
cancelButton.Layout.Column = 3;

% Set the default button to the "Agree" button
fig.KeyPressFcn = @(~, event) keyPressCallback(event, agreeButton);

% Make the figure visible after setting up the components
fig.Visible = 'on';

% Wait for user response
uiwait(fig);

% Check if the figure is still valid
if isvalid(fig)
    % Return the agreement status
    agreed = getappdata(fig, 'UserAgreed');
    close(fig); % Close the figure
else
    agreed = false;
end
end

function agreeCallback(fig)
% Callback function for the "Agree" button
if isvalid(fig)
    setappdata(fig, 'UserAgreed', true);
    uiresume(fig); % Resume the UI
end
end

function cancelCallback(fig)
% Callback function for the "Cancel" button
if isvalid(fig)
    setappdata(fig, 'UserAgreed', false);
    uiresume(fig); % Resume the UI
end
end

function keyPressCallback(event, agreeButton)
% Callback function for key press events
if strcmp(event.Key, 'return')
    % Simulate button press for the "Agree" button
    agreeButton.ButtonPushedFcn();
end
end

function enforceMinSize(fig, minWidth, minHeight)
% Enforce minimum size constraints
currentPosition = fig.Position;
newWidth = max(currentPosition(3), minWidth);
newHeight = max(currentPosition(4), minHeight);
fig.Position(3:4) = [newWidth, newHeight];
end