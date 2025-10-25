function updateGroupInfo(this,varargin)
% UPDATEGROUPINFO Updates waveform groups legend info

%  Author(s): C. Buhr
%  Copyright 1986-2015 The MathWorks, Inc.

if ~isempty(this.GroupInfoUpdateFcn)
   feval(this.GroupInfoUpdateFcn{:},varargin{:});
   return
end

this.DoUpdateName = false;
if isempty(varargin)
    dispname = this.name;
else
    dispname = varargin{1};
end

if ~this.LegendSubsriptsEnabled
    dispname = strrep(dispname,'_','\_');
end

grp = this.Group;

ax = getaxes(this);
%[nu,ny] = size(getaxes(this));

for gct = 1:length(grp);
    if ~strcmp(get(grp(gct),'DisplayName'),dispname)
        set(grp(gct),'DisplayName',dispname)
    end

   GroupLegendInfo = this.Style.GroupLegendInfo;
   if strcmpi(GroupLegendInfo.type, 'text')
       Fsize = get(ax(gct),'FontSize');
       Funits = get(ax(gct),'FontUnits');
       GroupLegendInfo.props = cat(2,GroupLegendInfo.props,{'FontUnits', Funits, ...
           'FontSize', Fsize});
   end
   legendinfo(grp(gct),GroupLegendInfo);  
   hA = get(grp(gct),'Annotation');
   if (isobject(hA) && isvalid(hA))
       hL = hA.LegendInformation;
       if (isobject(hL) && isvalid(hL))
           hL.IconDisplayStyle = 'on';
       end
   end
 
end
this.Group = grp;
this.DoUpdateName = true;
