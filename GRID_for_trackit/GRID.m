function varargout = GRID(varargin)
% GRID MATLAB code for GRID.fig
%      GRID, by itself, creates a new GRID or raises the existing
%      singleton*.
%
%      H = GRID returns the handle to a new GRID or the handle to
%      the existing singleton*.
%
%      GRID('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRID.M with the given input arguments.
%
%      GRID('Property','Value',...) creates a new GRID or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GRID before GRID_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GRID_OpeningFcn via varargin.
%
%      *See GRID Options on GUIDE's Tools menu.  Choose "GRID allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GRID

% Last Modified by GUIDE v2.5 16-Feb-2024 11:06:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GRID_OpeningFcn, ...
    'gui_OutputFcn',  @GRID_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
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


% --- Executes just before GRID is made visible.
function GRID_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GRID (see VARARGIN)

% Choose default command line output for GRID
handles.output = hObject;

if numel(varargin)==1
    handles.data=varargin{1};
    set(handles.filestatus,'string','File Loaded as start parameter')
end

%Initialize variable to save last folder that has been selected by user
handles.lastfolder='.';
handles.lastFilename = '';

%Initialize variables to save timelapse curves and fit curves
handles.tlCurves = {};
handles.fitCurvesGRID = {};
handles.fitCurvesOneRate = {};
handles.fitCurvesTwoRates = {};
handles.fitCurvesThreeRates = {};

% Update handles structure
guidata(hObject, handles);

% Nice Buttons
set(handles.stopoptim,'BackgroundColor',[0.9 0.9 0.9])
set(handles.startopt,'BackgroundColor',[0.9 0.9 0.9])


% UIWAIT makes GRID wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GRID_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%Button Callbacks
%**************************************************************************
% Executes on button press "Start optimization!"
function startopt_Callback(hObject, ~, handles)

set(handles.stopoptim,'BackgroundColor','red')
setappdata(0,'optimstop', false);

%Fetch data
data=handles.data;
parabool=get(handles.paramtab2,'data');
parameter=getparameter(handles);

%Start Inverse Laplacetrafo
[result,output]=spectrumfitwrapper(parameter,data,0);

%Fix Bleaching Rates to Results of Laplce Trafo for the Multi-Exp-Fits
if not(parabool(1))
    %Perfrom 2x1,2,3 Fits for comparison
    [res1,err1]=multiexpwrapper(data,1,[inf,0,0],[result.a1,0,0]);
    [res2,err2]=multiexpwrapper(data,2,[inf,0,0],[result.a1,0,0]);
    [res3,err3]=multiexpwrapper(data,3,[inf,0,0],[result.a1,0,0]);
else %Do not fix bleaching
    %Perfrom 2x1,2,3 Fits for comparison
    [res1,err1]=multiexpwrapper(data,1,[inf,0,0],[]);
    [res2,err2]=multiexpwrapper(data,2,[inf,0,0],[]);
    [res3,err3]=multiexpwrapper(data,3,[inf,0,0],[]);
end
%Remember Results
handles.result=result;
handles.output=output;

%Mono-Exponential Results
result1.k=res1(1);
result1.S=1;
result1.a1=res1(2);

%Two-Exponential Results
result2.k=res2(1:2);
result2.S=res2(3:4);
result2.a1=res2(5);

%Three-Exponential Results
result3.k=res3(1:3);
result3.S=res3(4:6);
result3.a1=res3(7);

handles.resultmulti={result1,result2,result3,err1,err2,err3};


[~,tlCurves,fitCurvesGRID]=lsqobjcontrol(handles.result,data);
[~,~,fitCurvesOneRate]=lsqobjcontrol(result1,data);
[~,~,fitCurvesTwoRates]=lsqobjcontrol(result2,data);
[~,~,fitCurvesThreeRates]=lsqobjcontrol(result3,data);

handles.tlCurves = tlCurves;
handles.fitCurvesGRID = fitCurvesGRID;
handles.fitCurvesOneRate = fitCurvesOneRate;
handles.fitCurvesTwoRates = fitCurvesTwoRates;
handles.fitCurvesThreeRates = fitCurvesThreeRates;

plotresults([], [], handles)

set(handles.stopoptim,'BackgroundColor',[0.9 0.9 0.9])

%Update handles structure
guidata(hObject, handles);

% Executes on button press in "STOP"
function stopoptim_Callback(~,~,~)
%Abort calculations
setappdata(0,'optimstop', true);

% Executes when entered data in editable cell(s) in paramtab2.
function paramtab2_CellEditCallback(hObject, eventdata, handles)
if eventdata.Indices(1)==2
    if eventdata.NewData
        handles.paramtab3.Enable='on';
    else
        handles.paramtab3.Enable='off';
    end
end
%Update handles structure
guidata(hObject, handles);

%Plot toolbar Callbacks
%**************************************************************************
function plotresults(~, ~, handles)
%Fetch results
result=handles.result;
res1=handles.resultmulti{1};
res2=handles.resultmulti{2};
res3=handles.resultmulti{3};

%Clear axes
cla(handles.dispSpec);

%Set log/linear scale
if strcmp(handles.logplot.State,'on')
    set(handles.dispSpec,'XScale','log');
else
    set(handles.dispSpec,'XScale','linear');
end

%Calculate plots
yGRID=result.S;
y1exp=0.2;
y2exp=res2.S;
y3exp=res3.S;

%Apply Division by x
if strcmp(handles.dividebyx.State,'on')
    yGRID=result.S./result.k/sum(result.S./result.k);
    y1exp=0.2/res1.k;
    y2exp=y2exp./res2.k/sum(y2exp./res2.k);
    y3exp=y3exp./res3.k/sum(y3exp./res3.k);
end

%Cumulate
if strcmp(handles.cumspectrum.State,'on')
    yGRID=cumsum(yGRID);
    y1exp=cumsum(y1exp);
    y2exp=cumsum(y2exp);
    y3exp=cumsum(y3exp);
end

%Draw
hold(handles.dispSpec,'on')
stem(handles.dispSpec,result.k,yGRID,'Displayname','Spectrum',...
    'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],...
    'MarkerSize',3,...
    'LineWidth',1.3)
stem(handles.dispSpec,res1.k,y1exp,'--','Displayname','1 exp',...
    'MarkerSize',3,'LineWidth',1.3)
stem(handles.dispSpec,res2.k,y2exp,'--',...
    'Displayname','2 exp','MarkerSize',3,'LineWidth',1.3)
stem(handles.dispSpec,res3.k,y3exp,'--'...
    ,'Displayname','3 exp','MarkerSize',3,'LineWidth',1.3)

%Show Results in GRID GUI
legend(handles.dispSpec,'toggle')

%Show bleaching rates
text(handles.dispSpec,max(max(result.k))/2,0.6,['a_1=' num2str(result.a1)]);

%Files menu bar callbacks
%**************************************************************************

% Load file functions
function loadex_Callback(hObject, ~, handles)


searchpath = handles.lastfolder;

%Get file from user input
[file,path]=uigetfile({'*.*'},'Select a file',searchpath);

if file == 0
    %do nothing
else
    handles.lastfolder = path;

    [~,fileName,~] = fileparts(file);
    handles.lastFilename = fileName;

    data=provideData(path,file);
    set(handles.filestatus,'string',[path file])
    handles.data=data;

    %Update handles structure
    guidata(hObject, handles);
end

% Save Results to .mat file
function saveResultsToMatFile_Callback(~, ~, handles)
try
    %Get Results
    result=handles.result;
    output=handles.output;
    res1=handles.resultmulti{1};
    res2=handles.resultmulti{2};
    res3=handles.resultmulti{3};

    %Prapare Variables with explanations
    gridResults.spectrum=struct('dissociation_rates',result.k,'Spectrum',result.S,...
        'bleachingnumber_1',result.a1,'error_test',output.error);
    gridResults.monoexponential=struct('dissociation_rate',res1.k,...
        'bleachingnumber_1',res1.a1,...
        'Adj_R_Sqared',handles.resultmulti{4});
    gridResults.twoexponential=struct('dissociation_rates',res2.k,...
        'Amplitudes',res2.S,...
        'bleachingnumber_1',res2.a1,...
        'Adj_R_Sqared',handles.resultmulti{5});
    gridResults.threeexponential=struct('dissociation_rates',res3.k,...
        'Amplitudes',res3.S,...
        'bleachingnumber_1',res3.a1,...
        'Adj_R_Sqared',handles.resultmulti{6});

    tlDataAndFit.tlCurves = handles.tlCurves;
    tlDataAndFit.fitCurvesGRID = handles.fitCurvesGRID;
    tlDataAndFit.fitCurvesOneRate = handles.fitCurvesOneRate;
    tlDataAndFit.fitCurvesTwoRates = handles.fitCurvesTwoRates;
    tlDataAndFit.fitCurvesThreeRates = handles.fitCurvesThreeRates;

    dt=datestr(now,'mm_dd_yyyy_HH_MM_SS');

    %Get recently used folder
    startingPath = handles.lastfolder;

    filepath = fullfile(startingPath,['Results_' dt]);

    %Open file selection dialog
    [fileName, pathName] = uiputfile('*.mat','Choose filename for saving .mat file',filepath);

    if fileName == 0
        %User did not choose a file
        return
    end

    %Create new file suggestion
    save(fullfile(pathName,fileName),'gridResults','tlDataAndFit')

    handles.lastfolder = pathName;
catch
    disp('No results found')
end

% -Save Results to Matlab workspace
function saveResultsToWorkspace_Callback(~, ~, handles)

%Get Results
result=handles.result;
output=handles.output;
res1=handles.resultmulti{1};
res2=handles.resultmulti{2};
res3=handles.resultmulti{3};

%Prapare Variables with explanations
gridResults.spectrum=struct('dissociation_rates',result.k','Spectrum',result.S',...
    'bleachingnumber_1',result.a1,'error_test',output.error);
gridResults.monoexponential=struct('dissociation_rate',res1.k,...
    'bleachingnumber_1',res1.a1,...
    'Adj_R_Sqared',handles.resultmulti{4});
gridResults.twoexponential=struct('dissociation_rates',res2.k,...
    'Amplitudes',res2.S,...
    'bleachingnumber_1',res2.a1,...
    'Adj_R_Sqared',handles.resultmulti{5});
gridResults.threeexponential=struct('dissociation_rates',res3.k,...
    'Amplitudes',res3.S,...
    'bleachingnumber_1',res3.a1,...
    'Adj_R_Sqared',handles.resultmulti{6});


tlDataAndFit.tlCurves = handles.tlCurves;
tlDataAndFit.fitCurvesGRID = handles.fitCurvesGRID;
tlDataAndFit.fitCurvesOneRate = handles.fitCurvesOneRate;
tlDataAndFit.fitCurvesTwoRates = handles.fitCurvesTwoRates;
tlDataAndFit.fitCurvesThreeRates = handles.fitCurvesThreeRates;

assignin('base','gridResults',gridResults);
assignin('base','tlDataAndFit',tlDataAndFit);

%Results menu bar callbacks
%**************************************************************************


%Print results to command window callback
function printcom_Callback(~, ~, handles)
try
    %Print Results to command window
    result=handles.result;
    output=handles.output;
    res1=handles.resultmulti{1};
    res2=handles.resultmulti{2};
    res3=handles.resultmulti{3};

    %Prapare Variables with explanations
    spectrum=struct('dissociation_rates',result.k,'Spectrum',result.S,...
        'bleachingnumber_1',result.a1,'error_test',output.error);
    monoexponential=struct('dissociation_rate',res1.k,...
        'bleachingnumber_1',res1.a1,...
        'Adj_R_Sqared',handles.resultmulti{4});
    twoexponential=struct('dissociation_rates',res2.k,...
        'Amplitudes',res2.S,...
        'bleachingnumber_1',res2.a1,...
        'Adj_R_Sqared',handles.resultmulti{5});
    threeexponential=struct('dissociation_rates',res3.k,...
        'Amplitudes',res3.S,...
        'bleachingnumber_1',res3.a1,...
        'Adj_R_Sqared',handles.resultmulti{6});

    %Print to console
    dt=datestr(now,'mm_dd_yyyy_HH_MM');
    disp(dt)
    disp(get(handles.filestatus,'string'))
    disp(spectrum)
    disp(monoexponential)
    disp(twoexponential)
    disp(threeexponential)
catch
    disp('No results found')
end


% Print to figure callback
function printfigure_Callback(~, ~, handles)

h=figure;
ax=gca;
%Axes for ccompare data fit
ax1=axes(h,'Position',[0.65,0.65,0.3,0.3]);
box(ax1,'on')
handles.dispSpec=ax;

%Plot
plotresults([], [], handles)

tlCurves = handles.tlCurves;
fitCurves = handles.fitCurvesGRID;

ylim([10^-5 1])
hold(ax1,'on')
ax1.XScale='log';
ax1.YScale='log';
box(ax1,'on')
legend(ax1,'toggle')
xlabel('time (s)')
ylabel('survival function')

nTl = length(tlCurves);

for tlIdx = 1:nTl
    %Plot
    plot(ax1,tlCurves{tlIdx}(:,1),tlCurves{tlIdx}(:,2),'k')
    plot(ax1,fitCurves{tlIdx}(:,1),fitCurves{tlIdx}(:,2),'r')
end

legend(ax1,'Fit','Data')


% Compare data and fit by GRID/2exp/3exp callbacks
function comparesurvivals_Callback(hObject, ~, handles)
%Plot a figure that compares target and fit function
try

    tlCurves = handles.tlCurves;

    switch str2double(hObject.Tag(end))
        case 1
            fitCurves = handles.fitCurvesGRID;
        case 2
            fitCurves = handles.fitCurvesTwoRates;
        case 3
            fitCurves = handles.fitCurvesThreeRates;
    end

    compare_survivals(tlCurves, fitCurves)

catch
    disp('No results found')
end


%Tools menu bar callbacks
%**************************************************************************
% k-effective analysis callback
function keff_ana_Callback(~, ~, handles)
prompt = {'Enter number of exps','1 for framewise scaling 0 for tl scaling'};
title = 'keff settings';
dims = [1 60];
definput = {'2','2',};
cmd = inputdlg(prompt,title,dims,definput);
numberofresamplings=eval(cmd{1});
figure
ax=gca;
keffanalysis(ax,handles.data,eval(cmd{1}),eval(cmd{2}));

% Exclude data callback
function excludedata_Callback(~, ~, handles)
data_viewer(handles.data);



%Resampling menu bar callbacks
%**************************************************************************


% Perform resampling on current dataset callback
function resamplingCurrentData_Callback(~, ~, handles)


%Fetch data
data=handles.data;
%Get Settings
parameter=getparameter(handles);
%Get resamplimg parameters
prompt = {'Enter number of Resamplings','Percentage of Resampled data'};
title = 'Change Resampling settings';
dims = [1 60];
definput = {'1','0.8','MyResampling'};
cmd = inputdlg(prompt,title,dims,definput);
numberofresamplings=eval(cmd{1});
N=1;
percentage=eval(cmd{2});
%resamplingcurrentdata
disp('Resampling Started')
[result100,~]=spectrumfitwrapper(parameter,data,1);

for ridx=1:numberofresamplings
    tic
    [datanew]=dataresampler(data,percentage,N);
    [results(ridx),output]=spectrumfitwrapper(parameter,datanew,1);
    t=toc;
    if ridx==1
        disp(['Estimated time (min):' num2str(t*numberofresamplings/60)])
    end
end
%Save Results
disp('Resampling Ended')

answer = questdlg...
    ('Resampling finished. Do You wish to save the results?');
switch answer
    case 'Yes'
        %Get recently used folder
        startingPath = handles.lastfolder;
        lastFilename = handles.lastFilename;

        filepath = fullfile(startingPath,[lastFilename, '_resampling_n', num2str(numberofresamplings), '_perc', num2str(percentage)]);

        %Open file selection dialog
        [fileName, pathName] = uiputfile('*.mat','Choose filename for saving resampling results',filepath);

        if fileName == 0
            %User did not choose a file
            return
        end

        %Create new file suggestion
        save(fullfile(pathName,fileName),'results','result100')

        handles.lastfolder = pathName;
    case 'Cancel'
        return
end


resampling_viewer(results,result100, handles.lastFilename);

% Perform resampling on multiple files callback
function resampleMultipleFiles_Callback(~, ~, handles)

searchpath = handles.lastfolder;

%Open file dialog box
[fileNameListNew,pathName] = uigetfile({'*.*'},'Select files for resampling', 'MultiSelect', 'on',searchpath);

if isequal(fileNameListNew,0) %User didn't choose a file
    return
elseif ~iscell(fileNameListNew) %Check if only one file has been chosen
    fileNameListNew = {fileNameListNew};
end



%Get resamplimg parameters
prompt = {'Enter number of Resamplings','Percentage of Resampled data'};
title = 'Change Resampling settings';
dims = [1 60];
definput = {'1','0.8','MyResampling'};
cmd = inputdlg(prompt,title,dims,definput);
numberofresamplings=eval(cmd{1});

%Get Settings
parameter=getparameter(handles);

nFiles = length(fileNameListNew);


disp('Resampling Started')


for fileIdx = 1:nFiles

    disp(['Resampling file ', num2str(fileIdx), ' of ', num2str(nFiles)])

    curFilename = fileNameListNew{fileIdx};

    data = provideData(pathName,curFilename);

    percentage=eval(cmd{2});
    %resamplingcurrentdata
    [result100,~]=spectrumfitwrapper(parameter,data,1);

    for ridx=1:numberofresamplings
        tic
        [datanew]=dataresampler(data,percentage,1);
        [results(ridx),output]=spectrumfitwrapper(parameter,datanew,1);
        t=toc;
        if ridx==1
            disp(['Estimated time for current file (min):' num2str(t*numberofresamplings/60)])
        end
    end

    
    filepath = fullfile(pathName,[curFilename, '_resampling_n', num2str(numberofresamplings), '_perc', num2str(percentage),'.mat']);


    %Create new file suggestion
    save(filepath,'results','result100')


    resampling_viewer(results,result100,curFilename);

end


disp('Resampling Finished')

% Analyse resampling results callback
function resamplingplot_Callback(hObject, ~, handles)

startingPath = handles.lastfolder;

%Open file selection dialog
[fileName,pathName] = uigetfile('*.mat','Select .mat file containing resampling results',startingPath,'MultiSelect','off');

if isequal(fileName,0)
    %User didn't choose a file
    return
end

%Save folder as a starting path for next file dialog 
handles.lastfolder = pathName;

%Load from .mat file
fullFilePath = fullfile(pathName,fileName);
loadedFile = load(fullFilePath);

%Get batch and filesTable from the loaded mat file
results = loadedFile.results;
result100 = loadedFile.result100;


[~,fileName,~] = fileparts(fileName);


resampling_viewer(results,result100', fileName);


%Update handles structure
guidata(hObject, handles);

% Compare resampling results callback
function compareResampling_Callback(hObject, ~, handles)
% hObject    handle to compareResampling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


startingPath = handles.lastfolder;

%Open file selection dialog
[fileName1,pathName1] = uigetfile('*.mat','Select first .mat file containing resampling results',startingPath,'MultiSelect','off');

if isequal(fileName1,0)
    %User didn't choose a file
    return
end

%Open file selection dialog
[fileName2,pathName2] = uigetfile('*.mat','Select second .mat file containing resampling results',pathName1,'MultiSelect','off');

if isequal(fileName1,0)
    %User didn't choose a file
    return
end


%Save folder as a starting path for next file dialog 
handles.lastfolder = pathName2;

%Load from .mat file
fullFilePath1 = fullfile(pathName1,fileName1);
loadedFile1 = load(fullFilePath1);

%Get batch and filesTable from the loaded mat file
resultsFirst = loadedFile1.results;
resultsFirst100 = loadedFile1.result100;

%Load from .mat file
fullFilePath2 = fullfile(pathName2,fileName2);
loadedFile2 = load(fullFilePath2);

%Get batch and filesTable from the loaded mat file
resultsSecond = loadedFile2.results;
resultsSecond100 = loadedFile2.result100;


[~,fileName1,~] = fileparts(fileName1);


resampling_comparer(resultsFirst,resultsFirst100',resultsSecond,resultsSecond100', fileName1, fileName2);


%Update handles structure
guidata(hObject, handles);




%Other minor things
%**************************************************************************

% ----------------------------------------------------------------------
function parameter=getparameter(handles)
%Get Settings
paraval=get(handles.paramtab,'data');
parabool=get(handles.paramtab2,'data');
table=get(handles.kSpektrum,'data');

%Define GRID
if table(1,3)==0
    k=linspace(table(2,1),table(2,2),table(2,3));
else
    k=logspace(table(1,1),table(1,2),table(1,3));
end

%Define parameter struct with empirical parameter
parameter=struct('kSpec',k,'E',paraval(1),'lbq',0,'ubq',inf,'x0',0,'b',[]);

%Should bleaching be fitted?
if parabool(2)==1
    parameter.lbq=get(handles.paramtab3,'data');
    parameter.ubq=get(handles.paramtab3,'data');
else
    parameter.ubq=3;
end

% ----------------------------------------------------------------------
function [data]=provideData(path,file)
id='MATLAB:load:variableNotFound';
warning('off',id)
%load excel specificied by user
if file(end-3:end)=='.mat'
    eval0=load([path file],'data');
    eval1=load([path file],'batch');
    if and(isempty(fieldnames(eval0)),not(isempty(fieldnames(eval1))))

        batch = eval1.batch;

        [subRegionChoice, canceled] = sub_region_choice_dialog(batch);

        if canceled
            data = [];
            disp('No data loaded')
        else
            data = create_grid_data_from_batch_file(batch, subRegionChoice);
        end

    end
    if and(isempty(fieldnames(eval1)),not(isempty(fieldnames(eval0))))
        data = eval0.data;
    end
    if and(isempty(fieldnames(eval0)),isempty(fieldnames(eval1)))
        disp('Error no data found')
        data=[];
    end
else
    data=gettimelapses([path file]);
end
warning('on',id)


