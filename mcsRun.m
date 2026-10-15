function results = mcsRun(cfg)
    if nargin < 1, cfg = []; end
    cfg = config(cfg);
    mcs = cfg.experiment.mcs;
    cases = repmat(struct('label','','cfg',cfg),1,numel(mcs));
    for k = 1:numel(mcs)
        cases(k).label = mcs(k).label;
        cases(k).cfg.modulation = mcs(k).modulation;
        cases(k).cfg.coding.codeRate = mcs(k).codeRate;
    end
    results = experimentRun(cfg,cases,cfg.experiment.snrDb);
    results.kind = 'mcs';
end
