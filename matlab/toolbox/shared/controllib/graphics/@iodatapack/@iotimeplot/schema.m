function schema
%SCHEMA  Definition of @iotimeplot class (time based IO data plot).

%  Copyright 2013-2015 The MathWorks, Inc.

% Register class
ppkg = findpackage('wavepack');
pkg = findpackage('iodatapack');
c = schema.class(pkg, 'iotimeplot', findclass(ppkg, 'waveplot'));
% Class attributes
p = schema.prop(c, 'InputName',    'MATLAB array');  % Input names (cell array)
p.GetFunction = @localGetInputName;
p.SetFunction = @localSetInputName;

p = schema.prop(c, 'InputVisible', 'string vector');  % Visibility of individual input channels
p.GetFunction = @localGetInputVisible;
p.SetFunction = @localSetInputVisible;

p = schema.prop(c, 'IOGrouping', 'string');       % [{none}|all]
p.GetFunction = @localGetIOGrouping;
p.SetFunction = @localSetIOGrouping;

p = schema.prop(c, 'OutputName',    'MATLAB array'); % Output names (cell array)
p.GetFunction = @localGetOutputName;
p.SetFunction = @localSetOutputName;

p = schema.prop(c, 'OutputVisible', 'string vector'); % Visibility of individual output channels
p.GetFunction = @localGetOutputVisible;
p.SetFunction = @localSetOutputVisible;

schema.prop(c, 'IOSize', 'MATLAB array'); % [ny nu]

% Global time focus (sec, default = []).
% Controls time range shown in auto-X mode
schema.prop(c, 'TimeFocus', 'MATLAB array');

p = schema.prop(c,'UnitsContainer','MATLAB array');
p.AccessFlags.PublicGet = 'on';
p.AccessFlags.PublicSet = 'off';

p = schema.prop(c,'NoOptionsLabel','MATLAB array');

%--------------------------------------------------------------------------
function Value = localGetInputVisible(this, varargin)
% GET function for the "InputVisible" property.

CV = this.ChannelVisible;
if isempty(CV)
   Value = [];
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
Value = CV(sz(1)+(1:sz(2)),1);

%--------------------------------------------------------------------------
function Value = localGetInputName(this, varargin)
% GET function for the "InputName" property.

CV = this.ChannelName;
if isempty(CV)
   Value = [];
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
Value = CV(sz(1)+(1:sz(2)),1);

%--------------------------------------------------------------------------
function Value = localGetIOGrouping(this, varargin)
% GET function for the "IOGrouping" property.

Value = this.ChannelGrouping;

%--------------------------------------------------------------------------
function Value = localSetInputVisible(this, Value)
% SET function for the "InputVisible" property.

CV = this.ChannelVisible;
if isempty(CV)
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
CV(sz(1)+(1:sz(2)),1) = Value;
this.ChannelVisible = CV;

%--------------------------------------------------------------------------
function Value = localSetInputName(this, Value)
% SET function for the "InputName" property.

CV = this.ChannelName;
if isempty(CV)
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
CV(sz(1)+(1:sz(2)),1) = Value;
this.ChannelName = CV;

%--------------------------------------------------------------------------
function Value = localSetIOGrouping(this, Value)
% SET function for the "IOGrouping" property.

this.ChannelGrouping = Value;

%--------------------------------------------------------------------------
function Value = localGetOutputVisible(this, varargin)
% GET function for the "OutputVisible" property.

CV = this.ChannelVisible;
if isempty(CV)
   Value = [];
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
Value = CV(1:sz(1),1);

%--------------------------------------------------------------------------
function Value = localGetOutputName(this, varargin)
% GET function for the "OutputName" property.

CV = this.ChannelName;
if isempty(CV)
   Value = [];
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
Value = CV(1:sz(1),1);

%--------------------------------------------------------------------------
function Value = localSetOutputVisible(this, Value)
% SET function for the "OutputVisible" property.

CV = this.ChannelVisible;
if isempty(CV)
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
CV(1:sz(1),1) = Value;
this.ChannelVisible = CV;

%--------------------------------------------------------------------------
function Value = localSetOutputName(this, Value)
% SET function for the "OutputName" property.

CV = this.ChannelName;
if isempty(CV)
   return
end
sz = this.IOSize;
if isempty(sz), sz = [0 0]; end
CV(1:sz(1),1) = Value;
this.ChannelName = CV;
