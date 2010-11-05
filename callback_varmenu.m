function callback_varmenu(hObject,eventdata)
% CALLBACK_VARMENU is the callback function for the MAIN program that opens
% the primary/secondary windows
%__________________________________________________________________________
% USAGE: callback_plot(hObject,eventdata,gui) 
% 
% INPUT:
%   hObject   - current object (not used)
%   eventdata - reserved for future use (MATLAB required)
%
% OUTPUT: 
%   opens a figure with the a plot of the selected items between the
%   selected dates
%
% PROGRAM OUTLINE:
%   1 - DETERMINE THE NAMES OF THE STATIONS FOR THE CURRENT SEASON
%   2 - CHECK IF AN AXIS WINDOW IS OPEN
%   3 - BUILD VARIABLE MENUS
%   CALLBACK: EXIT - closes the variable list
%   CALLBACK: CHECK - toggle the mark for the unit override options
%
% FUNCTIONS CALLED:
%   [h,hax] = Plotmenus(use,gui,fig,2);
%   callback_press(btn,eventdata);
%__________________________________________________________________________
try
% 1 - DETERMINE THE NAMES OF THE STATIONS FOR THE CURRENT SEASON
    % 1.1 - Gather information from GUI
        GUI = guidata(hObject);
        gui = ancestor(hObject,'figure','toplevel');
        use = getselected(gui);

    % 1.2 - Check that a station is selected
        if isempty(use);
            errordlg('No weather stations were selected.',...
                'USER ERROR (callback_varmenu.m)'); 
            return;
        end

    % 1.3 - Check if an axis window is open
        try close(GUI.varwindow); end

% 2 - CONVERT UNITS OF DATA
        convert_units(use,gui);

% 3 - BUILD VARIABLE MENUS
    % 3.1 - The main window and menu
    fig = dialog('WindowStyle','normal','Units','centimeters',...
            'Resize','on','Position',[10,3,15,15],...
            'Name','Data List','Tag','variables');  
    fmenu = uimenu(fig,'Label','File');
        uimenu(fmenu,'Label','Allow Mixed Units','Checked','off',...
            'tag','override','callback',{@check});
        uimenu(fmenu,'Label','Close list','Accelerator','Q',...
            'callback',{@exit,fig},'Separator','on');   
    pmenu = uimenu(fig,'Label','Plot');
        uimenu(pmenu,'Label','Weather Data','Callback',...
            {'callback_plotdata',GUI.main},'Accelerator','W');
     
    % 3.2 - Build toolbar
        tbar = uitoolbar(fig);
        icon = load('icons.ico','-mat');
        uipushtool(tbar,'Cdata',icon.plot,'TooltipString',...
            'plot weather data','ClickedCallback',...
             {'callback_plotdata',GUI.main});
        uipushtool(tbar,'Cdata',icon.clrbtn,'TooltipString',...
            'Clear all selections','ClickedCallback',...
            {@callback_clearbuttons});
    
    % 3.2 - Sets handle for main pgoram and build secondary axis panel 
        GUI.varwindow = fig;
        [h,hax] = Plotmenus(use,gui,fig,2);    
        GUI.secondary = hax; 

    % 3.4 - Build primary axis panel
        if ~isstruct(h) %Trips when no station warning is displayed prior
        else
            [h,hax,btn,pos] = Plotmenus(use,gui,fig,1);    
            GUI.primary = hax; 
            callback_press(btn,eventdata);
        end

    % 3.5 - Reposition window
        set(gui,'Units','centimeters');
        M = get(gui,'position');
        pos(1) = M(1) + M(3) + 0.5;
        pos(3) = pos(3) + 0.4;
        pos(4) = pos(4) + 1.2;
        pos(2) = M(2) + M(4) - pos(4);
        set(fig,'position',pos);

    % 3.6 - Return the window handle to the guidata
        guidata(gui,GUI);
        set(fig,'Resize','off');

catch
    mes = ['Error opening variable list (callback_varmenu.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: convert_units
function convert_units(use,gui)
% CONVERT_UNITS changes the units based on preferences settings

% 1 - Get information from the GUI
    h = guihandles(gui);
    GUI = guidata(gui);

% 2 - Determine the desired units based on preferences
    unit_num = GUI.settings.pref.units;
    if unit_num == 2; desired = 'english';
    else              desired = 'metric';
    end

% 3 - Cycle through each station and variables and change the units
    for i = 1:length(use);

        % 3.1 - Get the units for the current variable
        user = get(h.(use{i}),'UserData');
        var  = user.variables;

        % 3.2 - Cycle through variables
        fn = fieldnames(var);           % Names of variable
        for ii = 1:length(fn);
            unit = var.(fn{ii}).unit; % Unit of current variable
            data = var.(fn{ii}).data; % Data of current variables

            % Convert the unit and updata user data structure for the
            % current variable
            [data,unit] = getunit(unit,'convert',data,desired);
            var.(fn{ii}).unit = unit;
            var.(fn{ii}).data = data;
        end

        % Update the data structure for the current station
        user.variables = var;
        set(h.(use{i}),'UserData',user);
    end


%--------------------------------------------------------------------------
% CALLBACK: EXIT - closes the variable list
function exit(hObject,eventdata,fig)
    close(fig);
 
%--------------------------------------------------------------------------
% CALLBACK: CHECK - toggle the check mark for the unit override options    
function check(hObject,eventdata)
    c = get(hObject,'Checked');
    fig = findobj('Tag','variables');
    h = findobj(fig,'type','uicontrol','-and','Style','radiobutton');
    
    if strcmpi(c,'off') 
        set(hObject,'Checked','on'); callback_click(h(1),[]);
    else
        set(hObject,'Checked','off'); callback_clearbuttons([],[]);   
    end
    
%--------------------------------------------------------------------------
function callback_clearbuttons(hObject,eventdata)

fig = findobj('Tag','variables');
h = findobj(fig,'type','uicontrol','-and','Style','radiobutton','-and',...
    'value',1);

set(h,'value',0);
for i = 1:length(h); callback_click(h(i),[]); end

