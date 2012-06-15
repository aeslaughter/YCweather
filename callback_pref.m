function callback_pref(hObject,~)
% CALLBACK_PREF
%__________________________________________________________________________
% USAGE: callback_pref(hObject,eventdata)
%
% INPUT: hObject - calling objects handle (uimenu item)
%        eventdata - reserved for future version of MATLAB
%
% OUTPUT: none
% 
% PROGRAM OUTLINE:
% 1 - OPEN THE PREFERENCES WINDOW AND SET VALUES
% 2 - SET CALLBACKS
% 3 - CALLBACK: CHANGE - sets the main gui settings to match those in the
%       preferences window
% 4 - CALLBACK: callback_setpref - save or loads the default preferencs
% 5 - CALLBACK: button - gets a directory when browser button is pressed
% 6 - CALLBACK: EXIT - closes the preferences window
%__________________________________________________________________________
try
% 1 - OPEN THE PREFERENCES WINDOW AND SET VALUES
    % 1.1 - Opens the window and extract program settings
        GUI  = guidata(hObject);     % Extracts main program information
        ph   = prefGUI;              % Opens the preferences window
        h    = guihandles(ph);       % Handles for the preferences window
        GUI.preferences = ph;        % Sets handle for main guidata 
        guidata(hObject,GUI);        % Returns the main guidata
    
    % 1.2 - Set the window location as defined in the settings
        set(ph,'Units','Normalized');               % Set units
        P = get(ph,'Position');                     % Current position
        P(1:2) = GUI.settings.position.preferences(1:2);% Position settings
        set(ph,'Position',P);                       % Set position
        set(ph,'Name','Preferences');               % Set window name
        
    % 1.3 - Apply the curent settings  
        gui = ancestor(hObject,'figure','toplevel');
        applysettings('insert',gui);

% 2 - SET CALLBACKS
    % 2.1 - Exit option
        set([h.exit,h.closebutton],'Callback',{@exit,ph});
        
    % 2.2 - Apply changes
        set([h.change,h.applybutton],'Callback',{@change,'apply',gui});
        
    % 2.3 - Set and load default
        set(h.setdefault,'Callback',{@callback_setpref,'save',gui});
        set(h.loaddefault,'Callback',{@callback_setpref,'load',gui});
        
    % 2.4 - Set broswer buttons for directories
        set(h.save_btn,'Callback',{@button});
        set(h.database_btn,'Callback',{@button});

catch
    mes = ['Error opening preferences window (callback_pref.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end
    
%--------------------------------------------------------------------------     
% CALLBACK: CHANGE - sets the main gui settings to match those in the
%       preferences window
function change(~,~,action,gui)
    applysettings(action,gui);

%--------------------------------------------------------------------------   
% CALLBACK: callback_setpref - save or loads the default preferencs
function callback_setpref(hObject,~,action,gui)
% 1 - Collect the data from the default *.sla file
    GUI = guidata(gui);
    loc = getpref('YCweather','default');
    GUIdef = load(loc,'-mat');

% 2 - Save the new default values option 
if strcmpi(action,'save'); 
    applysettings('apply',gui);
    callback_saveWS(hObject,[],loc);

% 3 - Load the information from the default file option
else
    GUI = guidata(gui);
    GUIdef = load(loc,'-mat');
    GUI.settings = GUIdef.settings;
    applysettings('insert',gui);
    applysettings('apply',gui);           
end


%--------------------------------------------------------------------------
% CALLBACK: button - gets a directory when browser button is pressed
function button(hObject,~)  

% 1 - Determine the button pressed    
    h = guihandles(hObject);
    tag = get(hObject,'tag');
    tag = tag(1:length(tag)-4);

% 2 - Prompt user to enter a new path
    strt = get(h.(tag),'String'); 
    loc  = uigetdir(strt,['Chose a new ',tag,' directory']);
    if loc == 0; return; end

% 3 - Insert path into preferences
    set(h.(tag),'String',[loc,'\']);
 
%--------------------------------------------------------------------------
% CALLBACK: EXIT - closes the preferences window
function exit(~,~,gui)
    close(gui);
