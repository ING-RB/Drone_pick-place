function hEditor = PropEditor(plot,CurrentFlag)
%PROPEDITOR  Returns instance of Property Editor for response plots.
%
%   HEDITOR = PROPEDITOR(PLOT) returns the (unique) instance of  
%   Property Editor for w/r plots, and creates it if necessary.
%
%   HEDITOR = PROPEDITOR(PLOT,'current') returns [] if no Property 
%   Editor exists.

%   Copyright 1986-2021 The MathWorks, Inc.
persistent hPropEdit
if (nargin==1 && (isempty(hPropEdit) || ~isvalid(hPropEdit)))
   % Create and target prop editor if it does not yet exist
   hPropEdit = controllib.widget.internal.cstprefs.PropertyEditorDialog(...
       {getString(message('Controllib:gui:strLabels')),...
        getString(message('Controllib:gui:strLimits')),...
        getString(message('Controllib:gui:strStyle'))});
end
hEditor = hPropEdit;