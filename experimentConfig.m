function cfg = experimentConfig(overrides)
    mcs=struct('modulation',{'QPSK','16QAM','64QAM'},'codeRate',{1/2,2/3,3/4}, ...
        'label',{'QPSK, R = 1/2','16QAM, R = 2/3','64QAM, R = 3/4'}, ...
        'fileTag',{'qpsk_r12','16qam_r23','64qam_r34'});
    cfg=struct('seed',7,'packetsPerPoint',2000,'snrAwgnDb',-4:14,'snrTdlDb',-4:2:18, ...
        'snrDb',-4:25,'modulations',{{'QPSK','16QAM','64QAM'}}, ...
        'delaySpreadsNs',[120 250 490],'mcs',mcs, ...
        'outputDir',fullfile(fileparts(mfilename('fullpath')),'results'),'verbose',true, ...
        'commonRandomNumbers',true,'checkpointEnabled',true, ...
        'legacyBerPackets',2000,'legacyBlerPackets',8000,'legacyMcsPackets',5000, ...
        'separateSnrDb',-4:22,'reportDelaySpreadNs',300, ...
        'legacy16qamDelaySpreadsNs',[30 80 150 280 500]);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    validateattributes(cfg.seed,{'numeric'},{'scalar','real','integer','nonnegative','<=',2^32-1});
    for name={'packetsPerPoint','legacyBerPackets','legacyBlerPackets','legacyMcsPackets'}
        validateattributes(cfg.(name{1}),{'numeric'},{'scalar','real','integer','positive','finite'});
    end
    for name={'snrAwgnDb','snrTdlDb','snrDb','separateSnrDb'}
        validateattributes(cfg.(name{1}),{'numeric'},{'vector','real','finite','nonempty'});
    end
    validateattributes(cfg.delaySpreadsNs,{'numeric'},{'vector','real','nonnegative','finite','nonempty'});
    validateattributes(cfg.legacy16qamDelaySpreadsNs,{'numeric'},{'vector','real','nonnegative','finite','nonempty'});
    validateattributes(cfg.reportDelaySpreadNs,{'numeric'},{'scalar','real','nonnegative','finite'});
    if ~iscell(cfg.modulations)||isempty(cfg.modulations)||~all(ismember(cfg.modulations,{'QPSK','16QAM','64QAM'})),error('project:Modulation','Invalid experiment modulations.');end
    if ~isstruct(cfg.mcs)||isempty(cfg.mcs)||~all(isfield(cfg.mcs,{'modulation','codeRate','label','fileTag'})),error('project:MCS','Invalid MCS table.');end
    for k=1:numel(cfg.mcs)
        if ~ismember(cfg.mcs(k).modulation,{'QPSK','16QAM','64QAM'}),error('project:MCS','Invalid modulation.');end
        validateattributes(cfg.mcs(k).codeRate,{'numeric'},{'scalar','real','positive','finite','<=',1});
    end
    validateattributes(cfg.commonRandomNumbers,{'logical','numeric'},{'scalar','binary'});
    validateattributes(cfg.checkpointEnabled,{'logical','numeric'},{'scalar','binary'});
    validateattributes(cfg.verbose,{'logical','numeric'},{'scalar','binary'});
    if ~ischar(cfg.outputDir)||isempty(cfg.outputDir),error('project:Output','outputDir must be a nonempty character path.');end
end
