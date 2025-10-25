function valueStored = localSetFunction(this, ProposedValue, Prop)
% Setfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case 'XLimMode'
        valueStored = LocalXLimModeFilter(this,ProposedValue);
    case 'XScale'
        valueStored = LocalXScaleFilter(this,ProposedValue);
    case 'XUnits'
        valueStored = LocalXUnitFilter(this,ProposedValue);
    case 'YLimMode'
        valueStored = LocalYLimModeFilter(this,ProposedValue);
    case 'YScale'
        valueStored = LocalYScaleFilter(this,ProposedValue);
    case 'YUnits'
        valueStored = LocalYUnitFilter(this,ProposedValue);
    case 'UIContextMenu'
        valueStored = LocalSetUIContextMenu(this,ProposedValue);
        
        
end

function Value = LocalXLimModeFilter(this,Value)
% Correctly formats XlimMode settings
Size = this.Size;
if ~all(strcmpi(Value,'auto') | strcmpi(Value,'manual'))
    ctrlMsgUtils.error('Controllib:plots:LimModeProperty1','XLimMode')
else
   [Value,BadInputFlag] = LocalFormat(Value,Size([2 4]));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','XLimMode')
   end
   % Check compatibility with XLimSharing
   if (strcmp(this.XLimSharing,'all') & Size(2)*Size(4)>1 & ~isequal(Value{:})) | ...
         (strcmp(this.XLimSharing,'peer') & Size(2)>1 & ...
         ~isequal(Value,repmat(Value(1:Size(4)),[Size(2) 1])))
     ctrlMsgUtils.error('Controllib:plots:axesgroupProperties2','XlimMode','XLimSharing')
   end
end


function Value = LocalYLimModeFilter(this,Value)
% Correctly formats YlimMode settings
Size = this.Size;
if ~all(strcmpi(Value,'auto') | strcmpi(Value,'manual'))
    ctrlMsgUtils.error('Controllib:plots:LimModeProperty1','YLimMode')
else
   [Value,BadInputFlag] = LocalFormat(Value,Size([1 3]));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','YLimMode')
   end
   % Check compatibility with YLimSharing
   if (strcmp(this.YLimSharing,'all') & Size(1)*Size(3)>1 & ~isequal(Value{:})) | ...
         (strcmp(this.YLimSharing,'peer') & Size(1)>1 & ...
         ~isequal(Value,repmat(Value(1:Size(3)),[Size(1) 1])))
     ctrlMsgUtils.error('Controllib:plots:axesgroupProperties2','YlimMode','YLimSharing')
   end
end


function Value = LocalXScaleFilter(this,Value)
% Correctly formats XScale value
if ~all(strcmpi(Value,'linear') | strcmpi(Value,'log'))
    ctrlMsgUtils.error('Controllib:plots:ScaleProperty2','XScale')
else
   [Value,BadInputFlag] = LocalFormat(Value,this.Size(2:2:end));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','XScale')
   end
end


function Value = LocalYScaleFilter(this,Value)
% Correctly formats YScale value
if ~all(strcmpi(Value,'linear') | strcmpi(Value,'log'))
    ctrlMsgUtils.error('Controllib:plots:ScaleProperty2','YScale')
else
   [Value,BadInputFlag] = LocalFormat(Value,this.Size(1:2:end));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','YScale')
   end
end


function Value = LocalXUnitFilter(this,Value)
% Correctly formats XUnit settings (must be cell array of same length as subgrid col size)
Size = this.Size;
if Size(4)==1
   % No subgrid along column -> XUnit is a string
   if iscellstr(Value) & isequal(size(Value),[1 1])
      Value = Value{1};
   elseif ~ischar(Value)
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties1','XUnit')
   end
else
   % Multi-column subgrid: XUnit is a cell
   [Value,BadInputFlag] = LocalFormat(Value,Size(4));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','XUnit')
   end
end


function Value = LocalYUnitFilter(this,Value)
% Correctly formats YUnit settings (must be cell array of same length as subgrid row size)
Size = this.Size;
if Size(3)==1 
   % No subgrid along column -> YUnit is a string
   if iscellstr(Value) & isequal(size(Value),[1 1])
      Value = Value{1};
   elseif ~ischar(Value) & ~isequal(Size,[2 1 1 1])
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties1','YUnit')
   end
else
   [Value,BadInputFlag] = LocalFormat(Value,Size(3));
   if BadInputFlag
       ctrlMsgUtils.error('Controllib:plots:axesgroupProperties3','YUnit')
   end
end


function [Value,BadInput] = LocalFormat(Value,Sizes)
% Format string input
BadInput = false;
Sizes = [Sizes 1];
if ischar(Value), 
   Value = {Value}; 
end
switch length(Value)
case 1
   Value = Value(ones(1,prod(Sizes)),1);
case Sizes(2)
   % Specified for subgrid
   Value = repmat(Value(:),[Sizes(1) 1]);
case prod(Sizes)
   % Fully specified
   Value = Value(:);
otherwise
   BadInput = true;
end


function Value = LocalSetUIContextMenu(this,Value)
% Converts to handle
Value = handle(Value);
set(Value,'Serializable','off');
