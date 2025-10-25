function initsysresp(r,RespType,Opts,RespStyle)
%INITSYSRESP  Generic initialization of system responses.
% 
%   INITSYSRESP(R,PlotType,PlotOpts,RespStyle)

%   Author(s): P. Gahinet, B. Eryilmaz
%   Revised  : Kamesh Subbarao
%   Copyright 1986-2016 The MathWorks, Inc. 

% RE: * invoked by LTI methods and LTI Viewer
%     * r is a @waveform instance

% Plot-type-specific settings
TimeResp = any(strcmp(RespType,{'step','impulse','initial','lsim','idsim'}));
% idsim is proxy for ident plots: compare/predict/forecast where we do not
% use stairs for DT systems 

% Insert logic here for stem or stair plots for discrete time
% responses
if TimeResp
    if strcmp(RespType,'impulse') && ~isempty(r.DataSrc) ...
            && isa(r.DataSrc.Model,'idlti') && isdt(r.DataSrc.Model)
        Type = 'stem';
    elseif ~strcmp(RespType,'idsim')
        Type = 'stairs';
    else
       Type = 'line';
    end
    rView = r.View;
    for ct = 1:length(rView)
        rView(ct).Style = Type;
    end
end

% Built-in characteristics
if TimeResp && ~any(strcmp(RespType,{'lsim','idsim'})) 
   % Show steady-state line
   r.addchar('FinalValue','resppack.TimeFinalValueData', 'resppack.TimeFinalValueView');
end

% User-defined plot style
if nargin>3
   r.setstyle(RespStyle)
end
