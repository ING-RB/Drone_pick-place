function schema
% Defines properties for @eventmgr base class.
%
% This class and its subclasses define generic interfaces for managing events 
% and actions.  This includes:
%   * Mouse selection
%   * Mouse edits
%   * Event recording (history, undo, redo)
%   * Status management

%   Copyright 1986-2024 The MathWorks, Inc.

% Register class 
c = schema.class(findpackage('ctrluis'),'eventmgr');

% Public properties
schema.prop(c, 'MouseEditMode', 'on/off');        % Keeps track of dynamic mouse edits
p = schema.prop(c, 'SelectedContainer', 'MATLAB array');        % Container containing selected objects
p.SetFunction = @localConvertToHandle;
schema.prop(c, 'SelectedObjects', 'MATLAB array');   % List of mouse selected items

% Private properties
p(1) = schema.prop(c, 'Listeners', 'MATLAB array');           % Listeners
p(2) = schema.prop(c, 'SelectedListeners', 'MATLAB array');   % Listeners to selected objects

set(p,'AccessFlags.PublicGet','off','AccessFlags.PublicSet','off');

% Events
schema.event(c,'MouseEdit');   % Issued at each sample during mouse edits (move, resize,...)

