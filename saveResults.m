function [matPath, runDir] = saveResults(results, outputDir, tag)
    if nargin < 2 || isempty(outputDir), outputDir = results.cfg.experiment.outputDir; end
    if nargin < 3 || isempty(tag), tag = 'experiment'; end
    if ~ischar(outputDir) || isempty(outputDir), error('course:OutputDir','outputDir must be a character path.'); end
    if ~ischar(tag) || isempty(regexp(tag,'^[A-Za-z0-9_-]+$','once'))
        error('course:OutputTag','tag may contain letters, numbers, underscores and hyphens.');
    end
    if ~exist(outputDir,'dir'), [ok,msg] = mkdir(outputDir); if ~ok,error('course:OutputDir','%s',msg);end,end
    [~,suffix] = fileparts(tempname(outputDir));
    runDir = fullfile(outputDir,[tag '_' datestr(now,'yyyymmdd_HHMMSS') '_' suffix]);
    if exist(runDir,'file'), error('course:OutputExists','Refusing to overwrite %s.',runDir); end
    [ok,msg] = mkdir(runDir); if ~ok,error('course:OutputDir','%s',msg);end
    matPath = fullfile(runDir,'results.mat');
    results.result_file = matPath;
    results.figures_dir = runDir;
    cfg = results.cfg;
    save(matPath,'results','cfg','-v7');
end
