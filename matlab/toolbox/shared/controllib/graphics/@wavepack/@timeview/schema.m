function schema
%SCHEMA  Defines properties for @timeview class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2006 The MathWorks, Inc.

% Register class
superclass = findclass(findpackage('wrfc'), 'view');
c = schema.class(findpackage('wavepack'), 'timeview', superclass);

% Class attributes
p = schema.prop(c, 'Curves', 'MATLAB array');  % Handles of HG lines (matrix)

p = schema.prop(c, 'Style', 'string');     % Discrete time system curve style [stairs|stem]
p.FactoryValue = 'stairs';
% p.setfunction = {@LocalSetStyle};

p = schema.prop(c, 'StemLines', 'MATLAB array'); 
p.AccessFlags.PublicSet = 'off';


% function NewValue = LocalSetStyle(this,NewValue)
% Curves = this.Curves;
% if strcmpi(NewValue, 'stem')
%     for ct = 1:length(Curves)
%         this.StemLines(ct).Visible = Curves(ct).Visible;
%         set(this.Curves,'LineStyle','none','Marker','o');
%     end
% else
%     for ct = 1:length(Curves)
%         this.StemLines(ct).Visible = 'off';
%     end
% end


