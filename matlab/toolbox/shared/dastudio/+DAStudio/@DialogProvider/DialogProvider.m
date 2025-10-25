classdef DialogProvider < handle % DAStudio.Object
%DAStudio.DialogProvider class
%   DAStudio.DialogProvider extends DAStudio.Object.
%

%    DAStudio.DialogProvider properties:
%       Path - Property is of type 'ustring'  (read only) 
%       pDialogData - Property is of type 'MATLAB array'  (read only) 
%       DisplayIcon - Property is of type 'string'  
%       DialogImage - Property is of type 'string'  
%
%    DAStudio.DialogProvider methods:
%       errordlg - - Shows a DDG error dialog
%       inputdlg - - Shows a DDG input dialog
%       inputdlg_multiline - - Shows a multiline DDG input dialog
%       listdlg - - Shows a DDG list dialog
%       msgbox - - Shows a DDG message box
%       pControlCallback - - Dispatcher method for callbacks from dialog controls
%       pDialogCallback - - Dispatcher method for dialog callbacks
%       questdlg - - Shows a DDG question dialog
%       warndlg - errordlg - Shows a DDG warning dialog


properties (SetAccess=protected, SetObservable)
    %PDIALOGDATA Property is of type 'MATLAB array'  (read only)
    pDialogData 
end

properties (SetObservable)
    %DISPLAYICON Property is of type 'string' 
    DisplayIcon char = '';
    %DIALOGIMAGE Property is of type 'string' 
    DialogImage char = '';
end

methods  % public methods
    %----------------------------------------
   function d = errordlg(obj,message,title,nonblocking)
   %errordlg - Shows a DDG error dialog
   %
   % There are two modes of operation.  The first is blocking: the function
   % does not return until the dialog is dismissed by the user.
   %    obj.errordlg(message,title);
   %
   % The second mode is non-blocking.  The function returns immediately, with
   % the dialog still visible.  The dialog handle is returned.
   %   d = obj.errordlg(message,title,true);
   %
   % e.g. obj.errordlg('An error occurred','Error');
   %      obj.errordlg('An error occurred','Error',true);
   %
   % See also: errordlg
        
        
        if nargin > 1
           message = convertStringsToChars(message);
        end
        
        if nargin > 2
           title = convertStringsToChars(title);
        end
        
        s.Title = title;
        s.Message = message;
        obj.pDialogData = s;
        d = DAStudio.Dialog(obj,'ErrorDialog','DLG_STANDALONE');
        d.setFocus('OK');
        if nargin<4 || ~nonblocking
           % This will wait until the dialog is destroyed.
           waitfor(d,'dialogTag','');
           d = [];
        end
   end  % errordlg
   
    %----------------------------------------
   function answer = inputdlg(obj,prompt,title,defaultanswer,callback)
   %inputdlg - Shows a DDG input dialog
   %
   % There are two modes of operation.  This first is blocking, and is similar
   % to the MATLAB inputdlg function:
   %   answer = obj.inputdlg(prompt,title,defaultanswer);
   % If the dialog is cancelled, the return value is -1.  Otherwise it is a
   % string.
   %
   % The second mode is non-blocking, and executes a callback when the dialog
   % is closed.
   %   d = obj.inputdlg(prompt,title,defaultanswer,callback);
   % The supplied callback is called with one additional argument, which is
   % the string entered by the user.  If the dialog is cancelled, the callback
   % is NOT called.
   %
   % e.g.  answer = obj.inputdlg('Please enter your name:','Enter Name','');
   %       disp(answer);
   %
   %       obj.inputdlg('Please enter your name:','Enter Name','',@disp);
   %
   % See also: inputdlg


       if nargin > 1
           prompt = convertStringsToChars(prompt);
       end
       
       if nargin > 2
           title = convertStringsToChars(title);
       end
       
       if nargin > 3
           defaultanswer = convertStringsToChars(defaultanswer);
       end
       
       s.Title = title;
       s.Prompt = prompt;
       s.DefaultAnswer = defaultanswer;
       if nargin<5
           s.Callback = {};
       else
           s.Callback = callback;
       end
       s.InputDlgAnswer = -1;
       s.InputDlgMultiline = false;
       obj.pDialogData = s;
       d = DAStudio.Dialog(obj,'InputDialog','DLG_STANDALONE');
       if nargin<5
           waitfor(d,'dialogTag','');
           answer = obj.pDialogData.InputDlgAnswer;
       else
           answer = d;
       end
   end  % inputdlg
   
    %----------------------------------------
   function answer = inputdlg_multiline(obj,prompt,title,defaultanswer,callback)
   %inputdlg_multiline - Shows a multiline DDG input dialog
   %
   % Usage is identical to that of the "inputdlg" method, but the text area in
   % the dialog accepts multiple lines of text.
   %
   %   answer = obj.inputdlg_multiline(prompt,title,defaultanswer);
   %   d = obj.inputdlg_multiline(prompt,title,defaultanswer,callback);
   %
   % See also: inputdlg


       s.Title = title;
       s.Prompt = prompt;
       s.DefaultAnswer = defaultanswer;
       if nargin<5
           s.Callback = {};
       else
           s.Callback = callback;
       end
       s.InputDlgAnswer = -1;
       s.InputDlgMultiline = true;
       obj.pDialogData = s;
       d = DAStudio.Dialog(obj,'InputDialog','DLG_STANDALONE');
       if nargin<5
           waitfor(d,'dialogTag','');
           answer = obj.pDialogData.InputDlgAnswer;
       else
           answer = d;
       end
   end  % inputdlg_multiline
   
    %----------------------------------------
   function answer = listdlg(obj,prompt,title,liststring,iteminfo,callback)
   %listdlg - Shows a DDG list dialog
   %
   % There are two modes of operation.  This first is blocking, and is similar
   % to the MATLAB listdlg function.
   %
   %    answer = obj.listdlg(prompt,title,liststring,iteminfo);
   %
   % prompt is the first line of text in the dialog.
   % title is the dialog title.
   % liststring is a cell array of strings to be shown in the list
   % iteminfo is optional and is a cell array of strings giving further
   %    information about each item in the list.  The information is shown
   %    below the list when that item is selected.  If not required, this
   %    input can be empty.
   % 
   % answer is a string, or -1 if the dialog is dismissed without a selection
   %   being made.
   %
   % The second mode is non-blocking, and executes a callback when the user
   % chooses a string.
   %    d = obj.inputdlg(prompt,title,liststring,iteminfo,callback);
   %
   % The supplied callback is called with one additional argument, which is
   % the string selected by the user.  If the dialog is cancelled, the callback
   % is NOT called.
   %
   % e.g.  answer = obj.listdlg('Choose a color:','Color Chooser',{'Red','Blue','Green'},[]);
   %       disp(answer);
   % 
   %       answer = obj.listdlg('Choose a color:','Color Chooser',{'Red','Blue','Green'},...
   %                                {'Makes everything red','Makes everything blue',...
   %                                 'Makes everything green'});
   %       disp(answer);
   %
   %       obj.listdlg('Choose a color:','Color Chooser',{'Red','Blue','Green'},[],@disp);
   %
   % See also: listdlg


        s.Title = title;
        s.Prompt = prompt;
        s.ListString = liststring;
        % Basic argument checking on the input that's easiest to get wrong
        if ~isempty(iteminfo)
           assert(iscellstr(iteminfo),'DAStudio:DialogProvider:BadInput','iteminfo must be a cellstr');
           assert(numel(iteminfo)==numel(liststring),'DAStudio:DialogProvider:BadInput',...
               'iteminfo and liststring must be the same size');
        end
        s.ItemInfo = iteminfo;
        if nargin<6
           s.Callback = {};
        else
           s.Callback = callback;
        end
        s.ListDlgAnswer = -1;
        obj.pDialogData = s;
        d = DAStudio.Dialog(obj,'ListDialog','DLG_STANDALONE');
        if nargin<6
           waitfor(d,'dialogTag','');
           answer = obj.pDialogData.ListDlgAnswer;
        else
           answer = d;
        end  
   end  % listdlg
   
    %----------------------------------------
   function d = msgbox(obj,message,title,nonblocking)
   %msgbox - Shows a DDG message box
   %
   % There are two modes of operation.  The first is blocking: the function
   % does not return until the dialog is dismissed by the user.
   %    obj.msgbox(message,title);
   %
   % The second mode is non-blocking.  The function returns immediately, with
   % the dialog still visible.  The dialog handle is returned.
   %   d = obj.msgbox(message,title,true);
   %
   % e.g. obj.msgbox('Something just happened','Message');
   %      obj.msgbox('Something just happened','Message',true);
   %
   % See also: msgbox
   
   
       if nargin > 1
           message = convertStringsToChars(message);
       end
       
       if nargin > 2
           title = convertStringsToChars(title);
       end
       
       s.Title = title;
       s.Message = message;
       obj.pDialogData = s;
       d = DAStudio.Dialog(obj,'MessageBox','DLG_STANDALONE');
       d.setFocus('OK');
       if nargin<4 || ~nonblocking
           % This will wait until the dialog is destroyed.
           waitfor(d,'dialogTag','');
           d = [];
       end
   end  % msgbox
   
    %----------------------------------------
   function pControlCallback(obj,action,dlg)
   %PCONTROLCALLBACK - Dispatcher method for callbacks from dialog controls
   
   
       if strcmp(action,'MsgBox')
           % Just delete the dialog.  This will cause the "waitfor" in "msgbox"
           % to return.
           delete(dlg);
       elseif strncmp(action,'QuestDlg_',9)
           val = action(10:end);
           obj.pDialogData.QuestDlgValue = val;
           % This will cause the "waitfor" in "errordlg" to return.
           delete(dlg);
           % Execute the callback if there is one.
           cb = obj.pDialogData.Callback;
           if ~isempty(cb)
               if iscell(cb)
                   feval(cb{:},val);
               else
                   feval(cb,val);
               end
           end
       elseif strcmp(action,'list')
           ind = dlg.getWidgetValue('list');
           iteminfo = obj.pDialogData.ItemInfo{ind+1};
           dlg.setWidgetValue('info',iteminfo);
       else
           assert(false,'DAStudio:DialogProvider:BadInput',...
                  sprintf('Unexpected action: %s',action));
       end
   end % pControlCallback

    %----------------------------------------
   function [success,msg] = pDialogCallback(obj,action,dlg)
   %PDIALOGCALLBACK - Dispatcher method for dialog callbacks
       
       
       try
           [success,msg] = i_callback(obj,action,dlg);
       catch E
           success = false;
           msg = E.message;
       end
   end  % pDialogCallback
   
    %----------------------------------------
   function answer = questdlg(obj,prompt,title,buttons,defaultanswer,callback)
   %questdlg - Shows a DDG question dialog
   %
   % There are two modes of operation.  The first is blocking: the functions
   % waits until the user has selected a value, and then return it.
   %   answer = obj.questdlg(prompt,title,buttons,defaultanswer);
   % buttons is a cell array of strings giving the labels for the buttons.
   % defaultanswer is one of these labels, and identifies the button to be
   %   given the focus initially.
   % answer is a string, and is the label of the button clicked by the user.
   %   If the user closes the dialog without clicking any button, answer is
   %   empty.
   %
   % In the second mode of operation, the function returns immediately and a
   % callback is executed when the user clicks a button.
   %  d = obj.questdlg(prompt,title,buttons,defaultanswer,callback);
   % The dialog handle is returned.  The supplied callback is called with one
   % additional argument, which is the label of the button clicked by the
   % user.  If the user closes the dialog without clicking any button, the
   % callback is NOT called.
   %
   % e.g.  answer = obj.questdlg('Choose a color:','Color Selection',...
   %                             {'Red','Blue','Green'},'Blue');
   %       disp(answer);
   %
   %       obj.questdlg('Choose a color:','Color Selection',...
   %                    {'Red','Blue','Green'},'Blue',@disp);
   %
   % See also: questdlg
   
   
       if nargin > 1
           prompt = convertStringsToChars(prompt);
       end
       
       if nargin > 2
           title = convertStringsToChars(title);
       end
       
       if nargin > 3
           if isstring(buttons)
               buttons = cellstr(buttons);
           end
       end
       
       if nargin > 4
           defaultanswer = convertStringsToChars(defaultanswer);
       end
       
       s.Title = title;
       s.Prompt = prompt;
       s.Buttons = buttons;
       if nargin>5
           s.Callback = callback;
       else
           s.Callback = [];
       end
       % Supply a default response, for the case where the user closes the dialog
       % without clicking any button.
       if isempty(defaultanswer)
           defaultanswer = buttons{1};
       elseif ~ismember(defaultanswer,buttons)
           assert(false,'DAStudio:DialogProvider:BadInput',...
                  'Default answer must be one of the supplied names');
       end
       s.QuestDlgValue = '';
       obj.pDialogData = s;
       d = DAStudio.Dialog(obj,'QuestionDialog','DLG_STANDALONE');
       d.setFocus(['QuestDlg_' defaultanswer]);
       if nargin<6
           waitfor(d,'dialogTag','');
           answer = obj.pDialogData.QuestDlgValue;
       else
           answer = d;
       end  
   end  % questdlg
   
    %----------------------------------------
   function d = warndlg(obj,message,title,nonblocking)
   %errordlg - Shows a DDG warning dialog
   %
   % There are two modes of operation.  The first is blocking: the function
   % does not return until the dialog is dismissed by the user.
   %    obj.warndlg(message,title);
   %
   % The second mode is non-blocking.  The function returns immediately, with
   % the dialog still visible.  The dialog handle is returned.
   %   d = obj.warndlg(message,title,true);
   %
   % e.g. obj.warndlg('An error occurred','Error');
   %      obj.warndlg('An error occurred','Error',true);
   %
   % See also: warndlg
   
   
       s.Title = title;
       s.Message = message;
       obj.pDialogData = s;
       d = DAStudio.Dialog(obj,'WarnDialog','DLG_STANDALONE');
       d.setFocus('OK');
       if nargin<4 || ~nonblocking
           % This will wait until the dialog is destroyed.
           waitfor(d,'dialogTag','');
           d = [];
       end
   end  % warndlg     
end  % public methods 


methods (Hidden) % possibly private or hidden
    %----------------------------------------
   function dlgstruct = getDialogSchema(this, name)
   %
   
   
       switch (name)
           case 'MessageBox'
               dlgstruct = i_message_box(this,'msgbox');
           case 'InputDialog'
               dlgstruct = i_input_dialog(this);
           case 'ErrorDialog'
               dlgstruct = i_message_box(this,'errordlg');
           case 'WarnDialog'
               dlgstruct = i_message_box(this,'warndlg');
           case 'QuestionDialog'
               dlgstruct = i_question_dialog(this);
           case 'ListDialog'
               dlgstruct = i_list_dialog(this);
           otherwise
               assert(false,'DAStudio:DialogProvider:BadInput',...
                   sprintf('Unexpected dialog schema name: %s',name));
       end
       
       if ~isempty(this.DisplayIcon)
           dlgstruct.DisplayIcon = this.DisplayIcon;
       end
   end % getDialogSchema 
       
       %----------------------------------------------------

end  % possibly private or hidden

end  % classdef

function dlgstruct = i_input_dialog(this)

    data = this.pDialogData;
    dlgstruct.DialogTitle = data.Title;
    
    prompt.Type = 'text';
    prompt.Name = data.Prompt;
    prompt.Tag = 'prompt';
    prompt.ColSpan = [1 1];
    prompt.RowSpan = [1 1];
    
    if data.InputDlgMultiline
        input.Type = 'editarea';
    else
        input.Type = 'edit';
    end
    input.Value = data.DefaultAnswer;
    input.Tag = 'input';
    input.ColSpan = [1 1];
    input.RowSpan = [2 2];
    
    dlgstruct.LayoutGrid = [2 1];
    dlgstruct.StandaloneButtonSet = {'OK','Cancel'};
    dlgstruct.Sticky = true; % modal
    dlgstruct.DialogTag = 'inputdlg';
    dlgstruct = i_dialog_callback(dlgstruct,'inputdlg');
    dlgstruct.Source = this;
    dlgstruct.Items = {prompt, input};

end % i_input_dialog

%----------------------------------------------------
function dlgstruct = i_message_box(this,type)

    if strcmp(type,'msgbox')
        cols = 1;
        need_image = false;
    else
        % warning or error
        cols = 2;
        need_image = true;
    end
    
    
    data = this.pDialogData;
    dlgstruct.DialogTitle = data.Title;
    
    message.Type = 'text';
    message.Name = data.Message;
    message.Alignment = 5; % centre left
    message.Tag = 'message';
    message.WordWrap = true; % too narrow if we do this.
    message.ColSpan = [cols cols];
    message.RowSpan = [1 1];
    
    % Adjust the size of the text field depending on the length of the longest
    % line of text in the message. The exact size doesn't matter - the message
    % will wrap if it turns out to be too wide.
    
    exp = '<p><ul\sstyle="padding-left:15px"><li(?:\sstyle="list-style-type:none")?>(\s*(.*)\s*)</li></ul></p>';
    inner = regexp(message.Name, exp, 'tokens');
    
    if isempty(inner)
        inner = message.Name;
    else
        inner = char(inner{:});
    end
    
    m = max(cellfun('length',strsplit(inner,"<br/>")));
    n = max(cellfun('length',strsplit(inner, newline)));
    o = min(m, n);
    width = o*7+10;
    width = min(width,800);
    width = max(width,200);
    message.MinimumSize = [width, 50];
    
    if need_image
        image.Type = 'image';
        image.Tag = 'image';
        image.Alignment = 5; % centre left
        image.RowSpan = [1 1];
        image.ColSpan = [1 1];
        if ~isempty(this.DialogImage)
            image.FilePath = this.DialogImage;
        elseif strcmp(type,'errordlg')
            image.FilePath = fullfile(matlabroot,'toolbox','shared','dastudio','resources','error.png');
        else
            assert(strcmp(type,'warndlg'));
            image.FilePath = fullfile(matlabroot,'toolbox','shared','dastudio','resources','warning.png');
        end
    end
    
    % Create our own "OK" button so that we can centre it.
    button.Type = 'pushbutton';
    button.Name = 'OK';
    button.Tag = 'OK';
    button = i_control_callback(button,'MsgBox');
    
    buttonGroup.Type = 'panel';
    buttonGroup.LayoutGrid = [1 1];
    buttonGroup.Items = {button};
    buttonGroup.RowSpan = [2 2];
    buttonGroup.ColSpan = [1 cols];
    buttonGroup.Alignment = 6; % button uses its own size; centred in both directions
    
    dlgstruct.LayoutGrid = [2 cols];
    dlgstruct.StandaloneButtonSet = {''}; % no button bar
    dlgstruct.Sticky = true; % modal
    dlgstruct.DialogTag = type;
    
    if need_image
        dlgstruct.ColStretch = [0 1];
        dlgstruct.RowStretch = [1 0];
        dlgstruct.Items = {image, message, buttonGroup};
    else
        dlgstruct.Items = {message, buttonGroup};
    end
end %i_message_box

%----------------------------------------------------
function dlgstruct = i_question_dialog(this)

    data = this.pDialogData;
    dlgstruct.DialogTitle = data.Title;
    
    prompt.Type = 'text';
    prompt.Name = data.Prompt;
    prompt.Alignment = 5; % centre left
    prompt.Tag = 'message';
    prompt.ColSpan = [2 2];
    prompt.RowSpan = [1 1];
    prompt.WordWrap = true;
    prompt.MinimumSize = [300, 50];
    
    image.Type = 'image';
    image.Tag = 'image';
    image.RowSpan = [1 1];
    image.ColSpan = [1 1];
    if ~isempty(this.DialogImage)
        image.FilePath = this.DialogImage;
    else    
        image.FilePath = fullfile(matlabroot,'toolbox','shared','dastudio','resources','question.png');
    end
    
    items = cell(1,numel(data.Buttons));
    for i=1:numel(items)
        button.Type = 'pushbutton';
        button.Name = data.Buttons{i};
        tag = ['QuestDlg_',data.Buttons{i}];
        button.Tag = tag;
        button = i_control_callback(button,tag);    
        button.RowSpan = [1 1];
        button.ColSpan = [i i];
        items{i} = button;
    end
    
    buttonGroup.Type = 'panel';
    buttonGroup.LayoutGrid = [1 1];
    buttonGroup.Items = items;
    buttonGroup.RowSpan = [2 2];
    buttonGroup.ColSpan = [1 2];
    buttonGroup.Alignment = 6; % centred in both directions
    
    dlgstruct.LayoutGrid = [2 2];
    dlgstruct.StandaloneButtonSet = {''}; % no button bar
    dlgstruct.Sticky = true; % modal
    dlgstruct.RowStretch = [1 0];
    dlgstruct.ColStretch = [0 1];
    dlgstruct.DialogTag = 'questdlg';
    dlgstruct.Items = {image, prompt, buttonGroup};

end % i_question_dialog

%----------------------------------------------------
function dlgstruct = i_list_dialog(this)

    data = this.pDialogData;
    hasinfo = ~isempty(data.ItemInfo);
    
    prompt.Type = 'text';
    prompt.Name = data.Prompt;
    prompt.Alignment = 5; % centre left
    prompt.Tag = 'message';
    prompt.ColSpan = [1 1];
    prompt.RowSpan = [1 1];
    
    list.Type = 'listbox';
    list.ColSpan = [1 1];
    list.RowSpan = [2 2];
    list.Tag = 'list';
    list.ListDoubleClickCallback = @i_doubleclick;
    list.MultiSelect = false;
    list.Entries = data.ListString;
    if hasinfo
        list = i_control_callback(list,'list');
    end
    
    info.Type = 'text';
    info.Name = sprintf(' \n \n%s\n \n',... % leave some space
        DAStudio.message('modelexplorer:message:ClickForDescription'));
    info.Tag = 'info';
    info.WordWrap = true;
    info.ColSpan = [1 1];
    info.RowSpan = [3 3];
    
    if hasinfo
        dlgstruct.LayoutGrid = [3 1];
        dlgstruct.Items = {prompt, list, info};
    else
        dlgstruct.LayoutGrid = [2 1];
        dlgstruct.Items = {prompt, list};
    end
    dlgstruct.StandaloneButtonSet = {'OK','Cancel'};
    dlgstruct.Sticky = true; % modal
    dlgstruct.DialogTag = 'listdlg';
    dlgstruct.DialogTitle = data.Title;
    dlgstruct = i_dialog_callback(dlgstruct,'listdlg');

end % i_list_dialog

%--------------------------
function i_doubleclick(dlg,tag,index) %#ok<INUSD>
    obj = dlg.getSource;
    obj.pDialogCallback('listdlg',dlg);
    delete(dlg);
end % i_doubleclick

%--------------------------
function item = i_control_callback(item,key)
    item.ObjectMethod = 'pControlCallback';
    item.MethodArgs = {key,'%dialog'};
    item.ArgDataTypes = {'string','handle'};
end % i_control_callback


%--------------------------
function s = i_dialog_callback(s,key)
    s.PreApplyMethod = 'pDialogCallback';
    s.PreApplyArgs = {key,'%dialog'};
    s.PreApplyArgsDT = {'string','handle'};
end % i_dialog_callback

function [success,msg] = i_callback(obj,action,dlg)
    success = true;
    msg = '';
    switch action
        case 'inputdlg'
            val = dlg.getWidgetValue('input');
            obj.pDialogData.InputDlgAnswer = val;
            cb = obj.pDialogData.Callback;
            if ~isempty(cb)
                if iscell(cb)
                    feval(cb{:},val);
                else
                    feval(cb,val);
                end
            end
        case 'listdlg'
            ind = dlg.getWidgetValue('list');
            if numel(ind)~=1
                DAStudio.error('modelexplorer:message:SelectionRequired');
            end
            val = obj.pDialogData.ListString{ind+1};
            obj.pDialogData.ListDlgAnswer = val;
            cb = obj.pDialogData.Callback;
            if ~isempty(cb)
                if iscell(cb)
                    feval(cb{:},val);
                else
                    feval(cb,val);
                end
            end
        otherwise
            assert(false,'DAStudio:DialogProvider:BadInput',...
                   sprintf('Unexpected action: %s',action));
    end
end  % i_callback
