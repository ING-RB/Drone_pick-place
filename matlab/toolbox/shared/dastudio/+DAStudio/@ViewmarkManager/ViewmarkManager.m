classdef ViewmarkManager < handle

%    DAStudio.ViewmarkManager properties:
%       Path - Property is of type 'ustring'  (read only) 
%       option - Property is of type 'mxArray'  
%       viewmarker - Property is of type 'mxArray'  
%       modelname - Property is of type 'string'  
%       pos - Property is of type 'mxArray'  
%
%    DAStudio.ViewmarkManager methods:

properties (SetObservable)
    %OPTION Property is of type 'mxArray' 
    option  = '';
    %VIEWMARKER Property is of type 'mxArray' 
    viewmarker  = [  ];
    %MODELNAME Property is of type 'string' 
    modelname char = '';
    %POS Property is of type 'mxArray' 
    pos  = [  ];
end

methods
    function h = ViewmarkManager(option)  
        if nargin==0
        else
            h.modelname = option;    
        end    
    end    
end

methods (Hidden) % possibly private or hidden
    %----------------------------------------
   function dlgstruct = getDialogSchema(h, ~)
  
     v = h.viewmarker;
     dialogTag = v.getDialogTag();
  
     sysInfoModel = v.getSysInfoModel();
   
     if isempty(sysInfoModel)
         sysInfoModel.watermark_value = 0;
     end
     
     if isempty(h.option)
         error('viewmark manager should have option field.');
     end
   
     isPC = ispc;  
   
     thumbnail.Type = 'webbrowser';
     thumbnail.Name = 'thumbnail';
     %Inititate connector service:
     connector.ensureServiceOn;
     if ~connector.isRunning
         warning(message('dastudio:util:FailedToStartConnector'));
         return;
     end
     if v.getDebugMode()
           htmlFile = 'index-debug.html';
           dlgstruct.Transient = false;
           thumbnail.EnableInspectorOnLoad = true;
         else
           htmlFile = 'index.html';
     end
         
     if strcmp(h.option.mode, 'creation')
         connector.addWebAddOnsPath('ViewMarks',fileparts(h.option.vm_path));
         url = sprintf('/toolbox/shared/dastudio/web/viewmarks/%s',htmlFile);
         thumbnail.Url = connector.getUrl(url);
         h.pos(2) = h.pos(2) + h.pos(4) - 280;
         h.pos(3) = 400;
         if isPC
           h.pos(4) = 250;
         else
           h.pos(4) = 280;
         end
             
     end
     
     if strcmp(h.option.mode, 'open')
         info = v.getInfo();
         [infoModel, modelNameChanged] = v.getInfoModel();
         if modelNameChanged
           return;
         end
         if(size(info) > 0)
             connector.addWebAddOnsPath('ViewMarks',fileparts(info{1}.vm_path));
         end
         url = sprintf('/toolbox/shared/dastudio/web/viewmarksmanager/%s',htmlFile);
         thumbnail.Url = connector.getUrl(url);
         
         queryParams = matlab.net.QueryParameter(extractBetween(thumbnail.Url,strfind(thumbnail.Url,'?'),length(thumbnail.Url)));
         key = queryParams(1).Value;
         
         if(~isempty(fileparts(get_param(bdroot, 'filename'))))
           connector.addWebAddOnsPath(strcat("CurrentModel", key), fileparts(get_param(bdroot, 'filename')));
         end
         if(size(infoModel)>0)
             connector.addWebAddOnsPath(strcat("ModelViewMarks", key),fileparts(infoModel{1}.vm_path));
         end
         
         h.pos(1) = h.pos(1) + 2;
         h.pos(3) = h.pos(3) - 4;
         h.pos(4) = h.pos(4) - 2;
     end
     thumbnail.Tag = 'viewmarker_manager';
     thumbnail.DisableContextMenu = true;
     thumbnail.ClearCache = true;
   
     %%%%%%%%%%%%%%%%%%%%%%%
     % Main dialog
     %%%%%%%%%%%%%%%%%%%%%%% 
     manager.Type    = 'group';
     manager.Name    = '';
     manager.Flat    = true;
     manager.Items   = {thumbnail};  
   
     dlgstruct.DialogTitle = '';
     dlgstruct.Items = {manager};
     dlgstruct.StandaloneButtonSet = {''};
     dlgstruct.EmbeddedButtonSet = {''};
     dlgstruct.Transient = true;
     dlgstruct.DialogStyle = 'frameless';
     dlgstruct.Geometry = h.pos;
     dlgstruct.DialogTag = dialogTag;
     
     dlgstruct.CloseCallback = 'DAStudio.Viewmarker.onClose';
     dlgstruct.CloseArgs = {v, h};
   end
       
end  % possibly private or hidden 

end  % classdef

