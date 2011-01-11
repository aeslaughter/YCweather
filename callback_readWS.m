function callback_readWS(hObject,eventdata,varargin)
% READSLA - opens YCweather workspace *.mat file.
%__________________________________________________________________________
% USAGE: readWS(hObject,eventdata,varargin)
%
% INPUT: 
%   hObject = current object (not used)
%   eventdata = reserved for future use (MATLAB required)
%   varargin{1} = if it is empty then the program prompts the user
%               = filename - opens the desired filename
%
% PROGRAM OUTLINE:
% 1 - DETERMINE THE FILE TO OPEN
% 2 - ACTIVIATE THE NECESSARY SETTINGS
% SUBFUNCTION: readWS
% SUBFUNCTION: set_times
% SUBFUNCTION: build_plot
% SUBFUNCTION: set_window_position
% SUFUNCTION: verifyposition
%__________________________________________________________________________
try
% 1 - DETERMINE THE FILE TO OPEN
    % 1.1 - Utilize the user defined filename
    if ~isempty(varargin);
        filename = varargin{1};

    % 1.2 - Determine the workspace filename
    else
        % 1.2.1 - Use that last used directory, otherwise the saved folder
        GUI = guidata(hObject);
        if ~isfield(GUI,'currentdir');
            if ~exist(GUI.settings.paths.saved,'dir');
                mkdir(GUI.settings.paths.saved); 
            end
            GUI.currentdir = GUI.settings.paths.saved;
        end

        % 1.2.2 - Prompt the user for the file
        [file,pth] = uigetfile([GUI.currentdir,'*.mat'],'Open file...');
        if file == 0; return; end
        filename = [pth,file];    
        GUI.currentdir = pth;
    end

    % 1.3 - Open the saved *.mat file
        GUIold = guidata(hObject);
        GUI = load(filename,'-mat'); 
        GUI = comparewithdefault(GUI);
        GUI.main = findobj('Tag','YCweather');
        
    % 1.4 - Maintain the current handles
        if ~isempty(GUIold);
            p = {'primary','secondary','varwindow','preferences',...
            'logview','imageview'};
            for i = 1:length(p); 
                if ishandle( GUIold.(p{i}));
                    GUI.(p{i}) = GUIold.(p{i}); 
        end,end,end
  
    % 1.5 - Update the open recent option and current directory
        guidata(hObject,GUI);
        callback_recent(hObject,[],filename);

% 2 - ACTIVIATE THE NECESSARY SETTINGS
    applyWS(GUI.main,GUIold,filename);

catch
    mes = ['An error occured reading the *.mat file (callback_readWS)',...
            ', see errorlog.txt.'];
    errorlog(mes);
end

%--------------------------------------------------------------------------
% SUBFUNCTION: applyWS
function applyWS(hObject,GUIold,filename)
% applyWS applies the open *.mat file containing the YCweather data
% structure
%__________________________________________________________________________
% USAGE: applyWS(hObject)
% 
% INPUT: hObject = Handle of object in program control window
%        GUIold  = Data structure currently in use
%__________________________________________________________________________

% 1 - SET SEASON AND PROGRAM CONTROL POSITION
    GUI = guidata(hObject);
    h = guihandles(hObject);

    % 1.1 - Initilize folder list
        % 1.1.1 - Extract existing folders from database directory,
        % eliminating the '.' and '..' directories
            yr = struct2cell(dir(GUI.settings.paths.database));
            yr = yr(1,:); yr(strmatch('.',yr)) = []; 

        % 1.1.2 - Initilizes the folder list
            if isempty(yr);
                warndlg('No weather stations located.','!! WARNING !!');
                return;
            else
                set(h.season,'String',yr); 
            end

    % 1.2 - Attempt to match folder with input from *.mat file
        val = strmatch(GUI.season,yr,'exact');
        if isempty(val); val = length(yr); end
        set(h.season,'Value',val);

% 2 -UPDATE STATION PANEL AND CHECK WINDOW POSITION
    % 2.1 - Update data structures and get handles 
        % 2.1.1 - Define a tigger to load the season data, trig == 1 causes
        % the data to be open, "getselected" gathers all available station
        % buttons, which are then all deselected.
            trig = 1; 
            use = getselected(hObject,'all');
            for i = 1:length(use); set(h.(use{i}),'Value',0); end

        % 2.1.2 - First compare the current database folder and season, if
        % they are the same the data does not need to be reloaded.
        % However, if "use = []" then the program is opening for the first
        % time and thus the data needs to be loaded
        if ~isempty(GUIold); 
            Dold = GUIold.settings.paths.database; Sold = GUIold.season; 
            D = GUI.settings.paths.database; S = GUI.season;
            if strcmp(Dold,D) && strcmp(Sold,S); trig = 0; end
            if isempty(use); trig = 1; end
        end

        if trig == 1; callback_season(hObject,1); end
        h = guihandles(hObject);
       
    % 2.2 - Reposition the windows
        p = {'main','varwindow','preferences'};
        for i = 1:length(p);
            if ishandle(GUI.(p{i}));
                 set_window_position(GUI.(p{i}),...
                        GUI.settings.position.(p{i}));
        end,end

% 3 - SET START/END TIMES
    % 3.1 - Force default.mat to always use current time
        [~,f] = fileparts(filename);
        if strcmpi(f,'default'); GUI.settings.pref.timetype = 1; end

    % 3.2 - Prompt user for type of time, if selected
        if GUI.settings.pref.timetype == 3;
            mes = ['Would you like to use the current time',...
                    'or the absolute time?'];
            q = questdlg(mes,'Type of time?','Current','Stored','Current');
            switch q
                case 'Current'; GUI.settings.pref.timetype = 1;
                otherwise; GUI.settings.pref.timetype = 2;
            end
        end

    % 3.3 - Build time string if the current time is desired
        if GUI.settings.pref.timetype == 1;
            use = getselected(hObject,'all');
            if isempty(use); t = now; end;

            for i = 1:length(use);
                d = get(h.(use{i}),'UserData');
                t(i) = max(d.Time);
            end 
            os = GUI.settings.pref.timeoffset;
            GUI.time = [floor(max(t)-os/24),max(t)];
        end
        
    % 3.4 - Insert the times into the GUI
        set_times(h,GUI.time(1),'strt'); 
        set_times(h,GUI.time(2),'end');

    % 3.5 - Insert the time into GUI data
        callback_settime(hObject,1);  

% 4 - SET THE STATION BUTTONS
    btn = GUI.settings.stations;
    for i = 1:length(btn);
        if isfield(h,btn{i}); set(h.(btn{i}),'Value',1); end
    end

% 5 - READ/PLOT GRAPHS
    if isfield(GUI,'plot') && ~isempty(GUI.plot)...
                                        && ~isempty(GUI.plot(1).data)     
        callback_varmenu(hObject,1); 
        set_window_position(GUI.varwindow,GUI.settings.position.varwindow);
        pause(1);
        for i = 1:length(GUI.plot);
            build_plot(hObject,GUI.plot(i).data,GUI.plot(i).position);
        end
    end

%--------------------------------------------------------------------------
% SUBFUNCTION: set_times
function set_times(h,time,label)
% SET_TIMES sets the time popupmenus

% 1 - Read input time string
    t = datevec(time);

% 2 - Set month, day, hour, minute
    m = h.([label,'month']); set(m,'Value',t(2));
    set(h.([label,'day']),'Value',t(3));
    set(h.([label,'hr']),'Value',t(4)+1);
    set(h.([label,'min']),'Value',t(5)+1);

% 3 - Set the year
    y = h.([label,'year']);
    str = get(y,'String');
    set(y,'Value',strmatch(num2str(t(1)),str));

%--------------------------------------------------------------------------
% SUBFUNCTION: build_plot
function build_plot(h,tag,pos)
% BUILD_PLOT constructs graphs of selected variables

% 1 - Get handles and variable menu tags
    GUI = guidata(h);
    vh  = guihandles(GUI.varwindow);

% 2 - Select the desired variable buttons/listboxes
    k = 1;
    while k <= length(tag);
        switch get(vh.(tag{k}),'Style');
            case 'radiobutton'
                set(vh.(tag{k}),'Value',1);   
                callback_click(vh.(tag{k}),1);k = k + 1;
            case 'listbox';
                val = tag{k+1};
                set(vh.(tag{k}),'Value',val); 
                callback_click(vh.(tag{k}),1);k = k + 2;
    end,end

% 3 - Plot the data and reposition window
    callback_plotdata(h,1);
    set(gcf,'Position',pos);

% 4 - Deselect the variable buttons/listboxs
k = 1;
while k <= length(tag);
    switch get(vh.(tag{k}),'Style');
        case 'radiobutton'
            set(vh.(tag{k}),'Value',0);  
            callback_click(vh.(tag{k}),1); k = k + 1;
        case 'listbox';
            val = tag{k+1};
            set(vh.(tag{k}),'Value',1);  
            callback_click(vh.(tag{k}),1); k = k + 2;
end,end

%--------------------------------------------------------------------------
% SUBFUNCTION: set_window_position
function set_window_position(handle,P)
% SET_WINDOW_POSITION - set the window positions

% Proceed if the window exists
if ishandle(handle);
    loc = get(handle,'position');
    loc(1) = P(1); loc(2) = P(2);
    set(handle,'position',loc);
    movegui(handle,'onscreen');
end

%--------------------------------------------------------------------------
function GUI = comparewithdefault(GUI)
%COMPAREWITHDEFAULT compares the GUI loaded with the default, adds missing

DEF = create_defaultWS; 
    
% Check primary fields
    GUI = checkfields(GUI,DEF);
    GUI.sidebar = checkfields(GUI.sidebar,DEF.sidebar);
    
% Check settings
    GUI.settings = checkfields(GUI.settings,DEF.settings);
    GUI.settings.pref = checkfields(GUI.settings.pref,DEF.settings.pref);
    GUI.settings.position = checkfields(GUI.settings.position,...
        DEF.settings.position);
    
%--------------------------------------------------------------------------   
function S1 = checkfields(S1,S2)
% CHECKFIELDS inserts missing fields from S1 based on S2
fn = fieldnames(S2);    
for i = 1:length(fn);
    if ~isfield(S1,fn{i});
        S1.(fn{i}) = S2.(fn{i});
    end
end
        