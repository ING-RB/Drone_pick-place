function [out,constrClassTypes] = newconstr(this, keyword, CurrentConstr) 
% NEWCONSTR  method to present options to create a new requirement on a time
% plot
%
%   [LIST,CLASSTYPES] = NEWCONSTR(Editor) returns the list of all available
%   constraint types for this editor.
%
%   CONSTR = NEWCONSTR(Editor,TYPE) creates a constraint of the 
%   specified type.

 
% Author(s): A. Stothert 20-Sep-2005
% Copyright 2005-2011 The MathWorks, Inc.

if strcmpi(this.Tag,'step')
   ReqDB = {...
      'StepResponse', ...
            getString(message('Controllib:graphicalrequirements:lblStepResponseBound')),...
            'editconstr.StepResponse', ...
            'srorequirement.stepresponse'; 
      'UpperTimeResponse', ...
            getString(message('Controllib:graphicalrequirements:lblUpperTimeBound')), ...
            'editconstr.TimeResponse', ...
            'srorequirement.timeresponse'; 
      'LowerTimeResponse', ...
            getString(message('Controllib:graphicalrequirements:lblLowerTimeBound')),...
            'editconstr.TimeResponse', ...
            'srorequirement.timeresponse'};
else
   ReqDB = {...
      'UpperTimeResponse', ...
            getString(message('Controllib:graphicalrequirements:lblUpperTimeBound')), ...
            'editconstr.TimeResponse', ...
            'srorequirement.timeresponse'; ...
      'LowerTimeResponse', ...
            getString(message('Controllib:graphicalrequirements:lblLowerTimeBound')),...
            'editconstr.TimeResponse', ...
            'srorequirement.timeresponse'};
end

if nargin == 1
   % Return list of valid constraints
    out = ReqDB(:,[1 2]);
    if nargout == 2
       constrClassTypes = unique(ReqDB(:,3));
    end  
else
   keyword = localCheckKeyword(keyword,ReqDB);
   idx     = strcmp(keyword,ReqDB(:,1));
   Class   = ReqDB{idx,3};
   dClass  = ReqDB{idx,4};
   switch keyword
      case 'UpperTimeResponse'
         Type  = 'upper';
      case 'LowerTimeResponse'
         Type  = 'lower';
      case 'StepResponse'
         Type  = 'step';
   end
   
   % Create instance
   if nargin > 2 && isa(CurrentConstr, Class)
      % Recycle existing instance
      Constr = CurrentConstr; 
      Constr.Requirement.setData('type',Type)
   else
      % Create new instance
      reqObj = feval(dClass);
      reqObj.setData('type',Type);
      Constr = feval(Class,reqObj);
      Constr.setDisplayUnits('xunits',this.Axes.XUnits);
      Constr.setDisplayUnits('yunits','abs');
   end
   out = Constr;
end

%--------------------------------------------------------------------------
function kOut = localCheckKeyword(kIn,ReqDB)
%Helper function to check keyword is correct, mainly needed for backwards
%compatibility with old saved constraints

if any(strcmp(kIn,ReqDB(:,1)))
   %Quick return is already an identifier
   kOut = kIn;
   return
end

%Now check display strings for matching keyword, may need to translate kIn
%from an earlier saved version
strEng = {...
    'Step response bound'; ...
    'Upper time response bound'; ...
    'Lower time response bound'};
strTr = ReqDB(:,2);
idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
if any(idx)
   kOut = ReqDB{idx,1};
else
    
   kOut = [];
end