function cfg = coding_config(overrides)
    defaults=codingConfig();
    cfg=struct('enabled',defaults.enabled,'backend',defaults.backend,'turbo_num_iter',defaults.turboNumIter);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    validateattributes(cfg.enabled,{'logical','numeric'},{'scalar','real','finite','binary'});
    cfg.enabled=logical(cfg.enabled);
    if ~ischar(cfg.backend)||~ismember(lower(cfg.backend),{'manual','toolbox'}),error('manualLTE:Config','backend must be manual or toolbox.');end
    cfg.backend=lower(cfg.backend);
    validateattributes(cfg.turbo_num_iter,{'numeric'},{'scalar','real','finite','integer','>=',1,'<=',30});
end
