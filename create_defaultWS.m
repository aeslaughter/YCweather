function G = create_defaultWS
% CREATE_DEFAULTWS builds a the default.mat workspace if it does not exist

% 1 - GENERAL ITEMS
    G.version = 0;      G.verdata = '';     G.main = [];
    G.primary = [];     G.secondary = [];   G.varwindow = [];
    G.preferences = []; G.logview = [];     G.imageview = [];
    G.temp = [];        G.weather = [];     G.time = [now,now-2];
    G.season = ''; 

% 2 - SETTINGS
    % 2.1 - Pref
        p.primline = 1; p.primmarker = 1; p.secline = 1; p.secmarker = 1;
        p.width = 0.5; p.clear = 1; p.units = 2;
        p.figunits = 1; p.figwidth = 7; p.figheight = 5; p.log = 1;
        p.autoWx = 1; p.sidebarTC = 1; p.sidebarINPUT = 1; 
        p.sidebarSEARCH = 1; p.timetype = 3; p.timeoffset = 48;
        p.allowmesowest = 1;
        G.settings.pref = p;

    % 2.2 - Position
        ps.main = [0.02,0.5]; ps.varwindow = [0.3,0.2]; 
        ps.preferences = [0.4,0.5];
        G.settings.position = ps;

    % 2.3 - Paths
        % Get the users Documents path
        if (isunix)
            pth = getenv('HOME');
        else
            pth = getenv('USERPROFILE');
        end     
        
        % Use current directory if the above fail and check for Ubuntu One
        if isempty(pth)
            pt.database = [cd, filesep, 'database', filesep]; 
            pt.saved = [cd, filesep, 'saved', filesep]; 
        
        % Ubuntu One exists, use it    
        elseif exist([pth, filesep, 'Ubuntu One'], 'dir');
            pt.database = [pth, filesep,'Ubuntu One', filesep, 'YCweather',...
                filesep, 'database', filesep]; 
            pt.saved = [pth, 'Ubuntu One', filesep, 'YCweather',...
                filesep, 'saved', filesep];  
            
        % Create a YCweather directory in Documents
        else
            pt.database = [pth, filesep,'Documents', filesep, 'YCweather',...
                filesep, 'database', filesep]; 
            pt.saved = [pth, 'Documents', filesep, 'YCweather',...
                filesep, 'saved', filesep]; 
        end
        
        % Set the database property
        G.settings.paths = pt;
  
% 3 - OTHER ITEMS
    G.settings.stations = {};
    G.sidebar.alloff = [1.0000 1 12.5000 6.2000];