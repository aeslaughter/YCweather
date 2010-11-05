function varargout = radthermGUI(varargin)
% RADTHERMGUI M-file for radthermGUI.fig
%__________________________________________________________________________
% USAGE: [h] = radthermGUI(MAINgui,eventdata);
% 
% INPUT: MAINgui - handle to calling object on Program Control window
%        eventdata - not used, MATLAB required
%
% OUTPUT: h = gui handle for radtherm input figure
%
% This m-file is generated automatically by MATLAB's GUIDE program and then
% was modified.
%
% PROGRAM OUTLINE:
% 1 - INITILIZATION CODE - DO NOT EDIT
% 2 - EXECUTES JUST BEFORE RADTHERMGUI IS MADE VISIBLE.
% 3 - OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE.
% CALLBACK: callback_saverdt
% CALLBACK: callback_openrdt
% CALLBACK: callback_station
% CALLBACK: updatetime
% CALLBACK: callback_savefile
% CALLBACK: exit 
%__________________________________________________________________________

% 1 - INITILIZATION CODE - DO NOT EDIT
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @radthermGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @radthermGUI_OutputFcn, ...
                       'gui_LayoutFcn',  [], ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
       gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT

% 2 - EXECUTES JUST BEFORE RADTHERMGUI IS MADE VISIBLE
function radthermGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles);

    % 2.1 - Set the handles structure for radtherm and program control gui
        r   = handles;
        h   = guihandles(varargin{1});

      % 2.2 - Set Update time callback
        set(r.updatetime,'Callback',{@updatetime,varargin{1}});
        updatetime(r.updatetime,1,varargin{1});

    % 2.3 - Initilize the stations menus
        s = {'staAIRT','staSOLAR','staWIND','staHUMID','staLWIR',...
            'staWINDIR'};
        u = {{'C','F'},'W/m^2',{'m/s','mph'},'%','W/m^2','deg'};
        use = getselected(varargin{1},'all');

        for i = 1:length(s);
            set(r.(s{i}),'String',use,'Callback',{@callback_station},...
                'UserData',{u{i},h});
            callback_station(r.(s{i}),1);
        end

    % 2.4 - Set Build RadTherm File and exit callback   
        set(r.save,'Callback',{@callback_savefile});
        set(r.exit,'Callback',{@exit});

    % 2.5 - Set open/save *.rdt callbacks and open default file
        set(r.openfile,'Callback',{@callback_openrdt},...
            'UserData',varargin{1});
        callback_openrdt(r.openfile,1,'radtherm.rdt');
        set(r.savefile,'Callback',{@callback_saverdt},...
            'UserData',varargin{1});

% 3 -  OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE
function varargout = radthermGUI_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;


%--------------------------------------------------------------------------
% CALLBACK: callback_saverdt
function callback_saverdt(hObject,eventdata)
% CALLBACK_SAVERDT saves a *.rdt that stores the settings for GUI

% 1 - Extract SAVED path and build handle strings
    h    = guihandles(hObject);
    user = get(hObject,'UserData');
    GUI  = guidata(user);
    pth  = GUI.settings.paths.saved;
    A    = {'AIRT','SOLAR','WIND','HUMID','LWIR','WINDIR'};
        
% 2 - Determine the settings file to open
    [fn,pn] = uiputfile({'*.rdt','RadTherm Settings (*.rdt)'},...
    'Save RadTherm Settings...',[pth,'*.rdt']);
    if fn == 0; return; end
    filename = [pn,fn];
 
% 3 - Extract information from GUI
    for i = 1:length(A);
        t{1} = ['sta',A{i}]; t{2} = A{i};    % Tags for weather/station menu
        for ii = 1:length(t);
            str = get(h.(t{ii}),'String');
            B.(t{ii}) = str{get(h.(t{ii}),'Value')};
        end
    end

% 4 - Write file
    save(filename,'-mat','-struct','B');

%--------------------------------------------------------------------------
% CALLBACK: callback_openrdt
function callback_openrdt(hObject,eventdata,varargin)
% CALLBACK_OPENRDT opens a *.rdt that stores the settings for GUI

% 1 - Extract SAVED path and build handle strings
    h    = guihandles(hObject);
    user = get(hObject,'UserData');
    GUI  = guidata(user);
    pth  = GUI.settings.paths.saved;
        
% 2 - Determine the settings file to open
    % 2.1 - Determine the file to open
        if ~isempty(varargin);  filename = varargin{1};
        else
            [fn,pn] = uigetfile({'*.rdt','RadTherm Settings (*.rdt)'},...
                'Open RadTherm Settings...',pth);
            filename = [pn,fn];
        end

    % 2.2 - Test the file exists
        if ~exist(filename); disp('File does not exist.'); return; end

    % 2.3 - Open/read the file
        B = load(filename,'-mat');

% 3 - Set variables
    fn = fieldnames(B);
    for i = 1:length(fn);
        str = get(h.(fn{i}),'string');
        idx = strmatch(B.(fn{i}),str);
        if isempty(idx); idx = 1; end
        set(h.(fn{i}),'value',idx(1));
        if strmatch('str',fn{i}); callback_station(h.(fn{i}),[]); end
    end
        
%--------------------------------------------------------------------------
% CALLBACK: callback_station
function callback_station(hObject,eventdata)
% CALLBACK_STATION updates the weather variables if a station is selected.

% 1 - Get the user data from the station menu
    r = guihandles(hObject);
    user = get(hObject,'UserData');
    h = user{2};  % Handle to Program Control Window              

% 2 - Determine the station that was selected
    str = get(hObject,'String');
    station = str{get(hObject,'Value')};

% 3 - Get the station data structure and group items to appropriate unit
    data = get(h.(station),'UserData');
    unit = user{1};
    if ~iscell(unit); unit = {unit}; end
    grp = group_items(data.variables,unit,'unit'); 

% 4 - Updata the weather variable popup menu
    tag = get(hObject,'Tag'); 
    wx = tag(4:length(tag));
    set(r.(wx),'String',[grp{:}],'UserData',data,'Value',1);


%--------------------------------------------------------------------------
% CALLBACK: updatetime
function updatetime(hObject,eventdata,gui)    
    % hObject,eventdata - not used
    % gui - Program Control handle
    % rad - 

    % 1 - Set the start and end dates
        r = guihandles(hObject);
        GUI = guidata(gui);
        S = GUI.time;
        set(r.strt,'String',datestr(S(1),'mmm-dd-yy HH:MM'));
        set(r.stop,'String',datestr(S(2),'mmm-dd-yy HH:MM'));

    % 2 - Set user data of save button to store times
        set(r.save,'UserData',S);
    
    % 3 - Set the filename
        fname = ['w',datestr(S(1),'mmddyy'),'.txt'];
        set(r.fname,'String',fname);
    

%--------------------------------------------------------------------------
% CALLBACK: callback_savefile
function callback_savefile(hObject,eventdata)
% CALLBACK_SAVEFILE - executes when the user press build RadTherm button
    % hObject   - calling function handle
    % eventdata - not used
    
% 1 - EXTRACT DATA FROM MENU's
    % 1.1 - Handle tags of variable popup menus
        list = {'AIRT','SOLAR','WIND','HUMID','LWIR','WINDIR'};

    % 1.2 - Cycle through each variable option and extract data
        r = guihandles(hObject);
        for i = 1:length(list);
            user = get(r.(list{i}),'UserData');     % Complete station data
            str = get(r.(list{i}),'String');            
            item = str{get(r.(list{i}),'Value')};   % Selected variable

            data{i}(:,1) = user.Time;               % Time data
            temp = user.variables.(item).data;      % Variable data
            unit = user.variables.(item).unit;      % Variable data
            data{i}(:,2) = getunit(unit,'convert',temp,'metric');
        end

% 2 - BUILD DATA ARRAY's WITH EQUIVALENT TIMES
    % 2.1 - Build the time array for output file using interval 
        t = get(hObject,'UserData');
        int = str2double(get(r.interval,'String'));
        if isnan(int); int = 30; end
        time = t(1):1/1440*int:t(2);

    % 2.2 - Cycle through data and interpolate desired data
        for i = 1:length(data);
            x = data{i}(:,1); Y = data{i}(:,2); xi = time;
            RAD(:,i) = interp1(x,Y,xi,'pchip');
        end

% 3 - WRITE THE FILE TO A TEXT FILE
    % 3.1 - Build a numeric array containing all necessary data
        % 3.1.1 - Build time array and zeros array
            TM = str2double(cellstr((datestr(time,'HHMM'))));
            n = size(RAD,1); Z(1:n,1) = 0; 

        % 3.1.2 - Build complete data array and title row
            RAD = [TM,RAD(:,1:4),Z,RAD(:,5:6),Z]; 
            TITLE = {'TIME',list{1:4},'CLOUD',list{5:6},'RAINRATE'};
 
    % 3.2 - Output the data
        % 3.2.1 - Determine file for writing     
            fname = ['w',datestr(t(1),'mmddyy'),'.txt'];
            [fl,pth] = uiputfile(fname,'Save file as...');
            if fl == 0; return; end
            output = [pth,fl];

        % 3.2.2 - Write to file
            fid = fopen(output,'w'); 
            try
                % Format statements for header and data (space deliminated)
                headformat = '%4s %8s %8s %8s %8s %8s %8s %8s %8s\n';
                dataformat = ['%04.0f %8.3f %8.3f %8.3f %8.3f %8.3f ',...
                    '%8.3f %8.3f %8.3f\n'];

                % Write Data
                fprintf(fid,'%s\n','04');           % Print the '4' 
                fprintf(fid,headformat,TITLE{:});   % Print the headers
                fprintf(fid,dataformat,RAD');       % Print the data
                fclose(fid);                        % Closes file

        % 3.2.3 - Catch error if the above fails
            catch
                fclose(fid);
                errordlg('Problem writing file, check input file',...
                    'ERROR (radtherm.m)');
                return
            end

%--------------------------------------------------------------------------
% CALLBACK: exit 
function exit(hObject,eventedata)   
    h = guihandles(hObject); close(h.figure1);
