%plotSecondLevelResults.m
%
%DESCRIPTION
% Plots a bar graph that summarizes the output of the second-level analysis
% toolbox script.
%
%
%HOW TO RUN
% 1) After running a second-level analysis toolbox script, make sure that
%    there is a file called 'SPM_ss_mROI.mat' in the output directory.
%
% 2) Configure the graphing options by editing the THINGS TO CHANGE section
%    of this script.
%
% 3) Call plotSecondLevelResults from the MATLAB command window.
%
%
%INPUT ARGUMENTS
% resultsDir
%   - the path to the directory that contains SPM_ss_mROI.mat (which was
%     generated from the second-level analysis sript)
%   - it's best to use fullfile to generate this string
%
%   - type: string
%   - ex:   fullfile(pwd, 'Toolbox', 'LHlangfROIsrespNonlitMet_20160420_RESULTS')
%
%
% brainSystem
%   - the system you're looking for the responses in
%   - as of 2016-04-21, 'LHlanguage', 'RHlanguage', 'MD', and 'ToM' are supported
%   - go to the 'ROI structure' section of this script (under THINGS TO
%     CHANGE) to add more system fROI labels
%
%   - type: string
%   - ex:   'LHlanguage'
%
%
% contrastToPlot (optional)
%   - the effect of interest contrasts you want to plot
%   - each one MUST be a contrast that was defined in the
%     EffectOfInterest_contrasts field of the ss struct during second-level
%     analysis
%   - leave it blank if you want to plot all of the contrasts
%
%   - type: a cell array where each element is a string
%   - ex:   {'lit' 'met'}
%
%
% graphTitle (optional)
%   - the title of the graph
%   - leave it blank if you want to use the default title (defined in the
%     THINGS TO CHANGE section of this script)
%
%   - type: string
%   - ex:   'NonlitMet Responses in Language fROIs'
%
%
%SOME EXAMPLE FUNCTION CALLS
%<initialize the results directories>
%   resutsDir_LHLang = fullfile(pwd, 'Toolbox', 'LHlangfROIsrespNonlitMet_RESULTS')
%   resultsDir_MD = fullfile(pwd, 'Toolbox', 'MDfROIsrespNonlitMet_RESULTS')
%   resultsDir_ToM = fullfile(pwd, 'Toolbox', 'ToMfROIsrespNonlitMet_RESULTS')
%
%<plot all contrasts in the LH language regions using the default graph>
%   plotSecondLevelResults(resutsDir_LHLang, 'LHlanguage')
%
%<plot 2 specific contrasts in the MD regions using the default graph title>
%   plotSecondLevelResults(resultsDir_MD, 'MD', {'met', 'lit'})
%
%<plot 2 specific contrasts in the MD regions using a custom graph title>
%   plotSecondLevelResults(resultsDir_MD, 'MD', {'met', 'met-lit'}, 'NonlitMet Responses in MD fROIs')
%
%<plot all contrasts in the ToM regions using a custom graph title>
%   plotSecondLevelResults(resultsDir_ToM, 'ToM', [], 'NonlitMet Responses in MD fROIs')
%
%
%CHANGE LOG
%   2016-04-20: created (Zach Mineroff - mineroff@mit.edu)
%
%

function plotSecondLevelResults(resultsDir, brainSystem, contrastsToPlot, graphTitle)
    %% THINGS TO CHANGE
    %%% Graph options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %title of graph if none is specified
    defaultGraphTitle = ['Responses in ' brainSystem ' system'];
    
    %where to save the graph
    %set equal to '' if you don't want to save it
    %saveDir = fullfile(resultsDir, 'figures');
    saveDir = fullfile(pwd, 'figures');
    
    %name of file where the graph will be saved (do not include an extension like .jpg)
    %set equal to '' to save it as <graphTitle>
    saveFilename = '';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%% ROI structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %specify the ROI names for each system and the order you want to plot them in
    ROIs.LHlanguage.names = {'LPostTemp', 'LAntTemp', 'LAngG', ...
                             'LIFG',      'LMFG',     'LIFGorb'};
    ROIs.LHlanguage.graphOrder = [6 4 5 2 1 3];
    
    
    
    ROIs.RHlanguage.names = {'RPostTemp', 'RAntTemp', 'RAngG', ...
                             'RIFG',      'RMFG',     'RIFGorb'};
    ROIs.RHlanguage.graphOrder = [6 4 5 2 1 3];
    
    
    
    ROIs.MD.names = {'LIFGop',  'RIFGop', 'LMFG',    'RMFG',    'LMFGorb', ...
                     'RMFGorb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula', ...
                     'LSMA',    'RSMA',   'LParInf', 'RParInf', 'LParSup', ...
                     'RParSup', 'LACC',   'RACC'};
	ROIs.MD.graphOrder = (1:length(ROIs.MD.names));
    
    
    
    ROIs.ToM.names = {'DMPFC', 'LTPJ',  'MMPFC', 'PC',...
                      'RTPJ',  'VMPFC', 'RSTS'};
    ROIs.ToM.graphOrder = (1:length(ROIs.ToM.names));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%% Don't change anything below this line unless you really want to %%%
    
    
    %% Choose which system to use for this plot
    if ~any(strcmp(brainSystem, fieldnames(ROIs)))
        error(['\nThe system ''%s'' is not defined in the ROI structure.'...
               '\n\tSee the ''ROI structure'' section of this script.'],...
               brainSystem);
    end
    
    roiNames = ROIs.(brainSystem).names;
    roiGraphOrder = ROIs.(brainSystem).graphOrder;
    
    if max(roiGraphOrder) > length(roiNames)
        error(['\nThe maximum value in ''ROIs.%s.graphOrder'' must be less '...
               'than or equal the number of elements in ''ROIs.%s.names'''...
               '\n\tSee the ''ROI structure'' section of this script.'],...
               brainSystem, brainSystem);
    end
    
    
    %% Load the results mat file
    resultsFilename = fullfile(resultsDir, 'SPM_ss_mROI.mat');
    if ~exist(resultsFilename, 'file')
        error(['\nCannot find file ''%s''.\n'...
               '\tThe first argument of this script should be the path '...
               'to the directory that contains the results of the '...
               'second-level toolbox analysis.'], resultsFilename);
    end
    
    %ss is also a MATLAB function, so you need to declare it as a variable before loading it
    ss = [];
    load(resultsFilename)
    
    
    %% Grab eveything we need from the ss structure to make the plot
    contrastNames = ss.EffectOfInterest_contrasts;
    if (nargin < 3 || isempty(contrastsToPlot))
        contrastsToPlot = contrastNames;
    end
    
    percSignalChanges = ss.evaluate{end}.con;
    percSignalChanges = squeeze(percSignalChanges)'; %makes plotting easier
    
    stdErrs = ss.evaluate{end}.stderr;
    stdErrs = squeeze(stdErrs)';
    
    if length(percSignalChanges) ~= length(stdErrs)
        error(['\nSomething went wrong during the toolbox scripts.\n'...
               '\tTake a look at the ss structure loaded from ''%s''.\n'...
               '\n\tThe dimensions of ''ss.evaluate{end}.con'' and '...
               '''ss.evaluate{end}.stderr'' should be the same.'],...
               resultsFilename);
    end
    
    numROIs = length(percSignalChanges);
    
    
    %% Only keep the contrasts we want to plot
    contrastInds = arrayfun(@(x)find(strcmp(contrastNames,x)),contrastsToPlot);
    
    percSignalChanges = percSignalChanges(:,contrastInds);
    stdErrs = stdErrs(:,contrastInds);
    
    
    %% Check consistency of user input and the ss structure
    %Make sure the user-inputed contrasts are all in the ss structure
    if ~all(ismember(contrastsToPlot,contrastNames))
        undefinedContrastInds = ~ismember(contrastsToPlot,contrastNames);
        undefinedContrasts = contrastsToPlot(undefinedContrastInds);
        undefinedContrasts = sprintf('\t%s\n', undefinedContrasts{:});
        
        possibleContrasts = sprintf('\t%s\n', contrastNames{:});
        
        
        error(['\nThe following contrasts were not found in the ss struct '...
               'loaded from ''%s'':\n\n%s\nPossible contrasts are:\n\n%s\n'...
               'Please check the ''contrastsToPlot'' input to this script (or'...
               ' leave it blank if you want to plot all possible contrasts).'],...
               resultsFilename, undefinedContrasts, possibleContrasts);
    end
    
    %Make sure that the number of ROIs line up
    if numROIs ~= length(roiNames)
        error(['\nThere are %d ROIs in the ss struct loaded from ''%s'','...
               ' but there are %d ROI names in the ROIs structure '...
               'defined in this script for system ''%s''. Please check '...
               'the ''ROI structure'' section of this script.'], ...
               numROIs, resultsFilename, length(roiNames), brainSystem);
    end
    
    
    %% Make the graph (mostly stolen from Brianna)
    figToSave = figure(1);
    clf(figToSave)
    set(figToSave,'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    hold on
    
    %Values
    percSignalChanges = percSignalChanges(roiGraphOrder, :); %%TOMODIFY
    stdErrs = stdErrs(roiGraphOrder, :); %%TOMODIFY
    roiNames = roiNames(roiGraphOrder); %%TOMODIFY
    barGraph = bar(percSignalChanges); %%TOMODIFY
    
    %Error bars
    numContrasts = length(contrastsToPlot); %%TOMODIFY
    groupwidth = min(0.8, numContrasts/(numContrasts+1.5));
    for i = 1:numContrasts
          % Based on barweb.m by Bolu Ajiboye from MATLAB File Exchange
          x = (1:numROIs) - groupwidth/2 + (2*i-1) * groupwidth / (2*numContrasts);  % Aligning error bar with individual bar
          errorbar(x, percSignalChanges(:,i), stdErrs(:,i), 'k', 'linestyle', 'none');
    end
    
    %Labels
    if (nargin < 4 || isempty(graphTitle))
        graphTitle = defaultGraphTitle;
    end
    
    title(graphTitle, 'FontSize', 16);
    xlabel('fROI', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('% BOLD signal change', 'FontSize', 12, 'FontWeight', 'bold');
    
    set(gca, 'XTick', 1:numROIs);
    set(gca, 'XTicklabel', roiNames);
    legend(contrastsToPlot);
    
    %Style
    set(barGraph,'BarWidth',1);
    set(gca,'YGrid', 'on');
    set(gca, 'GridLineStyle','-');
    
    
    %% Save the graph
    if isempty(saveFilename)
        saveFilename = genvarname(graphTitle);
    end
    
    [path, saveFilename, extension] = fileparts(saveFilename);
    
    if ~isempty(saveDir)
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        saveFilename = fullfile(saveDir, [saveFilename '.jpg']);
        
        save = 'Yes';
        if exist(saveFilename, 'file')
            question = sprintf(['This file already exists:\n%s\n\n' ... 
                                'Do you want to overwrite it?'], saveFilename);
            save = questdlg(question, 'File already exists', 'Yes', 'No', 'No');
        end
        
        if strcmp(save, 'Yes')
            saveas(figToSave, saveFilename);
            fprintf('Figure saved as:\n\t%s\n', saveFilename);
        end
    end
end

