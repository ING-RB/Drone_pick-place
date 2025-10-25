function [dvName, suppressionsName] = getDVWindowNames()
dvName = DAStudio.message('Simulink:SLMsgViewer:SLMsgViewer_Dialog_Title');
suppressionsName = DAStudio.message('sl_diagnostic:SLMsgVieweri18N:SuppressionManager_Dialog_Title');
end 