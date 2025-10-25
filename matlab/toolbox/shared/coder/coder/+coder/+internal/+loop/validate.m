function [scheduleString, codeInsightToReport] = validate(schedule, loopIds)
%
% This is an internal function for code generation.
%
% This validates the chain of transforms in schedule and returns
% a char array representation.

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
  coder.internal.prefer_const(schedule);
  coder.internal.assert(coder.internal.isConst(schedule), ...
          'Coder:loopControl:NotConstantLoopSchedule');  
  coder.internal.prefer_const(loopIds);
  coder.internal.assert(coder.internal.isConst(loopIds), ...
          'Coder:loopControl:NotConstantLoopIds');
  if isempty(schedule)
      scheduleString = ''; 
      codeInsightToReport = '';
  else
      % the loopIds should not be empty. The call to this function
      % is to be inserted during code genration, and hence the loop IDs
      % should not be empty by design.
      coder.internal.assert(~isempty(loopIds), ...
          'Coder:builtins:Explicit', 'Empty loopIds passed to validate.');
      [scheduleString, codeInsightToReport] = schedule.validate(loopIds);
      scheduleString = coder.const(scheduleString);
      codeInsightToReport = coder.const(codeInsightToReport);
  end
end
