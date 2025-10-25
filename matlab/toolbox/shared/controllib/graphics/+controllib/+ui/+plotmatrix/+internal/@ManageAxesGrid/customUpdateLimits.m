function customUpdateLimits(this,IdxToIgnore)
%UPDATELIMS  Builtin limit picker.
%
%   UPDATELIMS(H) implements the default limit management (LimitManager='builtin').  
%   This limit manager
%     1) Finds common auto limits for axes in auto mode, in accordance
%        with the limit sharing settings defined by XLimSharing and 
%        YLimSharing
%     2) Ensures axes in manual mode comply with the LimSharing settings.
%   Only visible axes are included in the auto limit computation.

%   Copyright 2015-2020 The MathWorks, Inc.


ni = nargin;
ax = getAxes(this);
[nr,nc] = size(ax);
if ni == 1
    IdxToIgnore = true(nr,nc);
end
if isvisible(this.AxesGrid)
   % No updating if global mode is manual or custom (unless called directly)
   
   
   
   % Visible axes
   vis = reshape(strcmp(get(ax,'Visible'),'on'),[nr nc]);  % 1 for visible axes
   indrow = find(any(vis,2))';  % row with visible axes
   indcol = find(any(vis,1));   % columns with visible axes
   
   % Index of axes to not be included in limit sharing
   IgnoreIdx = ones([nr nc]);
   IgnoreIdx(IdxToIgnore) = 0;
   
   
   % Turn off backdoor listeners
   LimitMgrEnable = this.AxesGrid.LimitManager;  % can be 'off' in call with 3 inputs
   this.AxesGrid.LimitManager = 'off';
   
   % X and Y limit modes
   XLimMode = this.AxesGrid.XLimMode;  % Use current settings
   YLimMode = this.AxesGrid.YLimMode;  % Use current settings
   
   % Switch to auto mode for visible axes with XLimMode=auto
   xauto = strcmp(XLimMode,'auto');
   if length(xauto)==1
      xauto = repmat(xauto,[nr nc]);
   else
      xauto = repmat(xauto',[nr 1]);
   end
   set(ax(vis & xauto),'XlimMode','auto')
   
   % Switch to auto mode for visible axes with YLimMode=auto
   yauto = strcmp(YLimMode,'auto');
   if length(yauto)==1
      yauto = repmat(yauto,[nr nc]);
   else
      yauto = repmat(yauto,[1 nc]);
   end
   set(ax(vis & yauto),'YlimMode','auto')
   
   % Update X limits
   switch this.AxesGrid.XLimSharing
   case 'column'
      for ct=indcol,
         LocalEqualizeLims(ax(indrow,ct),'Xlim','XScale',IgnoreIdx(indrow,ct));
      end
   case 'all'
      LocalEqualizeLims(ax(vis),'Xlim','XScale',IgnoreIdx(vis));
   end
   
   % Update Y limits
   switch this.AxesGrid.YLimSharing
   case 'row'
      for ct=indrow,
         LocalEqualizeLims(ax(ct,indcol),'Ylim','YScale',IgnoreIdx(ct,indcol));
      end
   case 'all'
      LocalEqualizeLims(ax(vis),'Ylim','YScale',IgnoreIdx(ct,indcol));
   end
   
   if ~isempty(this.PeripheralAxes)
       for ct = 1:numel(this.PeripheralAxes)
%            switch this.PeripheralAxes(ct).Location
%                case 'Top'
%                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(1,:).XLim});
%                    
%                case 'Bottom'
%                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(end,:).XLim});
%                    
%                case 'Left'
%                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(:,1).YLim});
%                    
%                case 'Right'
%                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(:,end).YLim});
%            end
           switch this.PeripheralAxes(ct).Location
               case {'Top','Bottom'}
                   % Get the limit of peripheral axes from limit of first
                   % row. If any axes in the first row is ignored for
                   % limits, choose the second row for that column.
                   NewLim = cell(1,nc);
                   for ct1 = 1:nc
                       NewLim{1,ct1} = ax(1,ct1).XLim;
                       ct2 = 1;
                       while ct2<nr && IgnoreIdx(ct2,ct1)
                           ct2 = ct2+1;
                           NewLim{1,ct1} = ax(ct2,ct1).XLim;
                       end
                   end
                   customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, NewLim);
               case {'Left','Right'}
                   % Get the limit of peripheral axes from limit of first
                   % row. If any axes in the first row is ignored for
                   % limits, choose the second row for that column.
                   NewLim = cell(nr,1);
                   for ct1 = 1:nr
                       NewLim{ct1,1} = ax(ct1,1).YLim;
                       ct2 = 1;
                       while ct2<nc && IgnoreIdx(ct1,ct2)
                           ct2 = ct2+1;
                           NewLim{ct1,1} = ax(ct1,ct2).YLim;
                       end
                   end
                   customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, NewLim);
                   %                case 'Left'
                   %                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(:,1).YLim});
                   %
                   %                case 'Right'
                   %                    customUpdateLimits(this.PeripheralAxes(ct).AxesGrid, {ax(:,end).YLim});
           end
       end
   end
   if strcmpi(this.DiagonalAxesSharing,'XOnly') 
       setHistogramXLim(this);
       Ax = this.AxesGrid.getaxes;
       HistAx = getAxes(this);
       % For the first and last axes, there are no points. But force the
       % limit so that the tick marks are set properly
       if nc>1
           Ax(1,1).YLim = Ax(1,2).YLim;
           % for right rulers
           Ax(end,end).YLim = Ax(end,end-1).YLim;
       else
           % Only one axes - the histogram axes. Derive limits from the
           % histogram axes itself
           Ax(1,1).YLim = HistAx(1,1).YLim;
       end
       if nr>1
           Ax(end,end).XLim = Ax(end-1,end).XLim;
           % for top rulers
           Ax(1,1).XLim = Ax(2,1).XLim;
       else
           % Only one axes - the histogram axes. Derive limits from the
           % histogram axes itself
           Ax(end,end).XLim = HistAx(end,end).XLim;
           Ax(end,end).YLim = HistAx(end,end).YLim;
       end
   end
   % Turn backdoor listeners back on
   this.AxesGrid.LimitManager = LimitMgrEnable;
end

%------------------ Local Functions -----------------------

function LocalEqualizeLims(ax,LimProp,ScaleProp,IdxToIgnor)
% Enforce common limits for all axes in handle array AX
% All axes are assumed visible.
ax = ax(~logical(IdxToIgnor));
% Compute common limits
Lmin = NaN;
Lmax = NaN;
for ct=1:numel(ax)
   Lims = get(ax(ct),LimProp);
   Lmin = min(Lmin,Lims(1));
   Lmax = max(Lmax,Lims(2));
end

% Add buffer
Range = (Lmax-Lmin)/50;
% Enforce these limits
set(ax,LimProp,[Lmin-Range Lmax+Range])
