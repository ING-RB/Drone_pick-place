function schema
% @plotpair class: low-level container for axes pair.
% 
% Purpose: 
%   * Support pair of axes that can be grouped in single axes with dual Y scale

%   Author(s): P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc.

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'plotpair',pk.findclass('plotarray'));

% Properties
p = schema.prop(c,'AxesGrouping','on/off');        % Grouping of axes [on|{off}]