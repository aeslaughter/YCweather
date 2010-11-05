function varargout = thermGUI(varargin)
%THERMGUI M-file for thermGUI.fig
%__________________________________________________________________________


%__________________________________________________________________________

% 1 - INITILIZATION CODE - DO NOT EDIT
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @thermGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @thermGUI_OutputFcn, ...
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

% 2 - EXECUTES JUST BEFORE RADTHERMGUI IS MADE VISIBLE.
function thermGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;   
    guidata(hObject, handles);
    
    % 2.1 - Set the handles structure for radtherm and program control gui
        r   = handles;
        h   = guihandles(varargin{1});

    % 2.2 - Set Update time callback
        set(r.updatetime,'Callback',{@updatetime,varargin{1}});
        updatetime(r.updatetime,1,varargin{1});

    % 2.3 - Initilize the stations menus
        s = {'Tinitial','LW','SW','albedo','windspd',...
            'airtemp','RH','bottom','airpress'};
        u = {'C','W/m^2','W/m^2','%','m/s','C','%','C','kpa'};
        use = [getselected(varargin{1},'all');'use constant'];
        for i = 1:length(s);
            set(r.(['sta',s{i}]),'String',use,...
                'Callback',{@callback_station},'UserData',{u{i},h});
            set(r.(s{i}),'Callback',{@callback_variable,h});
        end

    % 2.4 - Set Build RadTherm File and exit callback   
        set(r.build,'Callback',{@callback_buildfile});
        set(r.exit,'Callback',{@exit});

    % 2.5 - Set open/save *.rdt callbacks and open default file
        set(r.openfile,'Callback',{@callback_openthrm},...
            'UserData',varargin{1});
        callback_openthrm(r.openfile,1,'thermalmodel.mdl');
        set(r.savefile,'Callback',{@callback_savethrm},...
            'UserData',varargin{1});

% 3 -  OUTPUTS FROM THIS FUNCTION ARE RETURNED TO THE COMMAND LINE
function varargout = thermGUI_OutputFcn(hObject, eventdata, handles)
    varargout{1} = handles.output;
    
    %--------------------------------------------------------------------------
% CALLBACK: callback_savethrm
function callback_savethrm(hObject,eventdata)
% CALLBACK_SAVETHRM saves a *.mdl that stores the settings for GUI

% 1 - Extract SAVED path and build handle strings
    h    = guihandles(hObject);
    user = get(hObject,'UserData');
    GUI  = guidata(user);
    pth  = GUI.settings.paths.saved;
    A = {'Tinitial','LW','SW','albedo','windspd','airtemp','RH',...
        'bottom','airpress'};
        
% 2 - Determine the settings file to open
    [fn,pn] = uiputfile({'*.mdl','Themal Model Settings (*.mdl)'},...
    'Save Thermal Model Settings...',[pth,'*.mdl']);
    if fn == 0; return; end
    filename = [pn,fn];
 
% 3 - Extract information from GUI
    for i = 1:length(A);
        t{1} = ['sta',A{i}]; t{2} = A{i};   % Tags for weather/station menu
        for ii = 1:length(t);
            str = get(h.(t{ii}),'String');
            if strcmpi('edit',get(h.(t{ii}),'Style'))
                B.(t{ii}) = str;
            else
                B.(t{ii}) = str{get(h.(t{ii}),'Value')};
            end
        end
    end
    
% 4 - Write data not associate with popupmenus    
    A = {'depth','density','conductivity','specific','extinct','interval'};
    for i = 1:length(A);
        B.(A{i}) = get(h.(A{i}),'String');
    end

% 5 - Write file
    save(filename,'-mat','-struct','B');

%--------------------------------------------------------------------------
% CALLBACK: callback_openthrm
function callback_openthrm(hObject,eventdata,varargin)
% CALLBACK_OPENRDT opens a *.mdl that stores the settings for GUI

% 1 - Extract SAVED path and build handle strings
    h    = guihandles(hObject);
    user = get(hObject,'UserData');
    GUI  = guidata(user);
    pth  = GUI.settings.paths.saved;
        
% 2 - Determine the settings file to open
    % 2.1 - Determine the file to open
        if ~isempty(varargin);  filename = varargin{1};
        else
            [fn,pn] = uigetfile({'*.mdl','RadTherm Settings (*.mdl)'},...
                'Open Thermal Model Settings...',pth);
            filename = [pn,fn];
        end

    % 2.2 - Test the file exists
        if ~exist(filename); disp('File does not exist.'); return; end

    % 2.3 - Open/read the file
        B = load(filename,'-mat');

% 3 - Set variables
    fn = fieldnames(B);
    for i = 1:length(fn);
        
        % 3.1 - Case when popupmenus are incountered
        tst = fn{i}(1:2);
        tst2 = ['sta',fn{i}];
        if strcmpi(tst,'st') %|| ~isfield(h,tst2);
            str = get(h.(fn{i}),'string');
            idx = strmatch(B.(fn{i}),str) ;  
            if isempty(idx); idx = 1; end
            set(h.(fn{i}),'value',idx(1));
            if strmatch('str',fn{i}); callback_station(h.(fn{i}),[]); end
            
        % 3.2 - Case when constants are desired    
        else
            set(h.(fn{i}),'Style','edit','String',B.(fn{i}));
        end
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
    
% 3 - Gather the Tag of the associated data selection menu
    tag = get(hObject,'Tag'); 
    wx = tag(4:length(tag));
    
% 4 - Adjust for "use constant" option    
    if strcmpi(station,'use constant');
        set(r.(wx),'Style','edit','String','enter value');
        return;
    end

% 5 - Get the station data structure and group items to appropriate unit
    data = get(h.(station),'UserData');
    unit = user{1};
    if ~iscell(unit); unit = {unit}; end
    grp = group_items(data.variables,unit,'unit'); 
    set(r.(wx),'Style','popupmenu','String',[grp{:}],...
        'UserData',data,'Value',1);
    
    
    

%--------------------------------------------------------------------------
% CALLBACK: updatetime
function updatetime(hObject,eventdata,gui)    
    % hObject,eventdata - not used
    % gui - Program Control handle

    % 1 - Set the start and end dates
        r = guihandles(hObject);
        GUI = guidata(gui);
        S = GUI.time;
        set(r.strt,'String',datestr(S(1),'mmm-dd-yy HH:MM'));
        set(r.stop,'String',datestr(S(2),'mmm-dd-yy HH:MM'));

    % 2 - Set user data of save button to store times
        set(r.build,'UserData',S);
    
%--------------------------------------------------------------------------
% CALLBACK: callback_savefile
function callback_buildfile(hObject,eventdata)
% CALLBACK_BUILDFILE - executes when the user press build RadTherm button
    % hObject   - calling function handle
    % eventdata - not used
    
%try
% 1 - EXTRACT DATA FROM GUI
    r = guihandles(hObject);

% 2 - BUILD ARRAY OF SNOWPACK DATA
    % 2.1 - Insert thermocouple data
%         user = get(r.Tinitial,'UserData');
%         out  = user.output;
%         
%         % 2.1.1 - Case when data is constant, use depth from GUI
%             if isscalar(out);  
%                 d(:,1) = str2double(get(r.depth,'String'));
%                 d(:,2) = out;
%             else
%                 d = out;
%             end
% 
%         % 2.1.2 - Insert data into output array
%             snow(:,1) = d(:,1);
%             snow(:,5) = d(:,2);

    % 2.2 - Insert the remaining data
        s   = {'depth','density','conductivity','specific','Tinitial',...
            'extinct'};
        for i = 1:length(s);
            snow(:,i) = str2double(get(r.(s{i}),'String'));
        end

% 3 - BUILD ATMOSPHERIC DATA ARRAY
    % 3.1 - Build the time array for export
        time = get(r.build,'UserData');
        int  = str2double(get(r.interval,'String'));
        time = time(1):int/24/60:time(2)
        n    = length(time);

    % 3.2 - Insert data into a single array
    a = {'LW','SW','albedo','windspd','airtemp','RH','bottom','airpress'};
    for i = 1:length(a);
        user = get(r.(a{i}),'UserData');
        d    = user.output;

        % 3.2.1 - Case when a constant value is input
        if isscalar(d);    
            ATM(1:n,i) = d;
        
        % 3.2.2 - Case when non-constant data is input
        else
            x = d(:,1); Y = d(:,2); xi = time';
            yi = interp1(x,Y,xi,'linear');
            ATM(:,i) = yi;
        end
    end

    % 3.3 - Add the time data (hours) to the output array
        tm  = (time - time(1))*24;
        atm = [tm',ATM];

% 4 - TEST THAT THE DEPTH MATCHES THAT OF THE GUI
    depth = str2double(get(r.depth,'String'));
    r = size(snow,1);
    if snow(r,1) ~= depth;
        snow = [snow;snow(r,:)];
        snow(r+1,1) = depth;        % Total depth specified
        snow(r+1,5) = atm(1,8);     % Boundary condition initally
    end

% 5 - BUILD THE THERMAL MODEL EXCEL INPUT FILE
    % 5.1 - Determine the file to create
        GUI = guidata(hObject);
        saved = GUI.ProgramControl.settings.paths.saved;

        [fn,pn] = uiputfile({'*.xlsx','Excel 2007 (*.xlsx)'},...
            'Thermal model filename...',[saved,'*.xlsx']);
        if fn == 0; return; end
        filename = [pn,fn];

    % 5.2 - Copy the template file
        copyfile([cd,'\template.xls'],filename);

    % 5.3 - Insert the data into the new file
        xlswrite(filename,atm,'AtmosphericSettings','A4');
        xlswrite(filename,snow,'SnowProperties','A4');

% catch
%     mes = ['Error occured changing building thermal model excel file ',...
%             '(callback_exportTHERMAL.m > callback_build) ',...
%             'see errorlog.txt.'];
%     errorlog(mes);
% end

%--------------------------------------------------------------------------
function callback_variable(hObject,eventdata,h)
% CALLBACK_VARIABLE executes when a variable with a popup menu is changed

%try

h
% 1 - EXTRACT GUI AND USER DATA
    user = get(hObject,'UserData');
    str  = get(hObject,'String');
    val  = get(hObject,'Value');
    tag  = get(hObject,'Tag');
    sty  = get(hObject,'Style');

% 2 - EXTRACT DATA FROM GUI
    if strcmpi(tag,'Tinitial') && ~strcmpi(sty,'edit');
        user.output = getTCdata(hObject,user.data);
        wrt = str{val};
       
    elseif strcmpi(sty,'edit'); 
        user.output = str2double(str);
        wrt = str;
    else
        var = user.group{val};
        X = user.data.Time;
        Y = user.data.variables.(var).data;
        user.output = [X,Y];
        wrt = str{val};
    end

% 3 - INSERT DATA INTO USER DATA OF OBJECT
    user.write = wrt;
    set(hObject,'UserData',user);

% catch
%     mes = ['Error occured changing variable item in thermal GUI ',...
%             '(callback_exportTHERMAL.m > callback_variable) ',...
%             'see errorlog.txt.'];
%     errorlog(mes);
% end

%--------------------------------------------------------------------------
% SUBFUNCTION: getTCdata
function data = getTCdata(obj,S)
% GETTCDATA extract thermocouple data from station variable list

% 1 - DETERMINE THE DESIRED TC DATA
    str = get(obj,'String');
    TC  = str{get(obj,'Value')};

% 2 - SEPERATE THE THERMOCOUPLE DATA
    % 2.1 - Initilize output
        n = length(TC);
        fn = fieldnames(S.variables);
        k = 1; out = [];

    % 2.2 - Loop through data and extract the thermocouple data and the
    %       associated depths
        for i = 1:length(fn);
            test = '';
            if length(fn{i}) > n; test = fn{i}(1:n); end
            if strcmpi(test,TC); 
                out = [out,S.variables.(fn{i}).data]; 
                depth(k,1) = str2double((fn{i}(n+1:length(fn{i}))));
                k = k + 1;
        end,end

% 3 - SEPERATE DATA AT DESIRED TIME
    DATA = guidata(obj);
    idx = dsearchn(S.Time,DATA.time(1));
    Y = out(idx,:);
    X = depth;

% 4 - RETURN DATA TO OBJECT
    data = [X,Y'];
    
%--------------------------------------------------------------------------
% CALLBACK: exit 
function exit(hObject,eventedata)   
    h = guihandles(hObject); close(h.figure1);

