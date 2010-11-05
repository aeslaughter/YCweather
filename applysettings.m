function applysettings(action,gui)
% APPLYSETTINGS captures, inserts, or apply the program settings based on
% the values in preferences window
%__________________________________________________________________________
% USAGE:    Applysettings(action,gui)
%
% INPUT:    action = 'apply' collects the position settings from the
%                   preference window and applies them to the main gui
%                   settings
%                  = 'insert' collects all of the settings values from the
%                  main guidata and displays them in the preferences window
%           gui = handle for the main program (i.e. Program Control)
%
% OUTPUT: none
%
% PROGRAM OUTLINE:
%   1 - EXTRACT SETTINGS AND OBJECT HANDLES AND IMPLEMENT SWITCH
%   2 - APPLY ACTION
%   3 - CAPTURE OPTION
%   4 - INSERT OPTION
%   5 - UPDATE GUI INFORMATION
%
% FUNCTIONS CALLED: none
%__________________________________________________________________________
 
% 1 - EXTRACT SETTINGS AND OBJECT HANDLES AND IMPLEMENT SWITCH
GUI = guidata(gui);

switch action
% 2 - APPLY ACTION (Applies the values in preferences and window positions)
case 'apply'      
    h = guihandles(GUI.preferences);
    hh = guihandles(gui);

    % 2.1 - Apply preference settings and extract sidebar settings
       name = fieldnames(GUI.settings.pref);
       k = 1;
       for i = 1:size(name);
           nm = name{i};
            if isfield(h,nm);
                if strcmpi(get(h.(nm),'Style'),'Edit');
                   GUI.settings.pref.(nm)=str2double(get(h.(nm),'String'));
                else
                   GUI.settings.pref.(nm) = get(h.(nm),'Value');
                end
            end
            if length(nm) > 7 && strcmpi('sidebar',nm(1:7))
                sidebar{k} = nm(8:length(nm));
                k = k + 1;
            end
       end

    % 2.2 - Apply Path settings
       name = fieldnames(GUI.settings.paths);
       for i = 1:size(name);
           STR = get(h.(name{i}),'String');
           GUI.settings.paths.(name{i}) = STR;
       end
       
    % 2.3 - Apply window positions
       name = fieldnames(GUI.settings.position);
       for i = 1:size(name);
           try
               P = get(h.(name{i}),'position');
               loc = [P(1),P(2)];
               GUI.settings.position.(name{i}) = loc;
           catch; continue
           end
       end
       
% 3 - INSERT OPTION (places current main gui setting into preferences)
case 'insert'   
    h = guihandles(GUI.preferences);

    % 3.1 - Insert the plot settings
    name = fieldnames(GUI.settings.pref);
    for i = 1:size(name)
        nm  = name{i};
        sel = GUI.settings.pref.(nm);
        if isfield(h,nm);
            if strcmpi('Edit',get(h.(nm),'Style'))
                set(h.(nm),'String',num2str(sel));
            else
                set(h.(nm),'Value',sel);    
            end
        end
    end

    % 3.2 - Insert the path settings
    name = fieldnames(GUI.settings.paths);
    for i = 1:length(name);
       STR = GUI.settings.paths.(name{i});
       set(h.(name{i}),'String',STR);
    end
    
end % Ends the switch

% 4 - UPDATE GUI INFORMATION    
    guidata(gui,GUI);
