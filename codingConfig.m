function cfg = codingConfig(overrides)
    cfg=struct('enabled',true,'backend','manual','turboNumIter',4,'tbLength',1000, ...
        'crcPoly','24A','codeRate',2/3,'rv',0);
    if nargin>0,cfg=mergeConfig(cfg,overrides);end
    validateattributes(cfg.enabled,{'logical','numeric'},{'scalar','real','finite','binary'});
    cfg.enabled=logical(cfg.enabled);
    if ~ischar(cfg.backend)||~ismember(lower(cfg.backend),{'manual','toolbox'}),error('project:Coding','backend must be manual or toolbox.');end
    cfg.backend=lower(cfg.backend);
    validateattributes(cfg.turboNumIter,{'numeric'},{'scalar','real','finite','integer','>=',1,'<=',30});
    validateattributes(cfg.tbLength,{'numeric'},{'scalar','real','integer','positive','finite'});
    if ~ismember(cfg.tbLength,[16 1000]),error('project:Block','Supported information lengths: 16 and 1000.');end
    if ~strcmp(cfg.crcPoly,'24A'),error('project:CRC','Only CRC24A is supported.');end
    validateattributes(cfg.codeRate,{'numeric'},{'scalar','real','positive','finite','<=',1});
    validateattributes(cfg.rv,{'numeric'},{'scalar','real','integer','>=',0,'<=',3});
end
