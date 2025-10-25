function cleanMATLABState

rng(0);
close all hidden;
fclose all;
evalin('base','builtin(''clear'',''clear'')');
evalin('base','clear');
dbclear all;