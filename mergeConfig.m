function cfg = mergeConfig(cfg, overrides)
    if isempty(overrides),return;end
    if ~isstruct(overrides)||~isscalar(overrides),error('project:Config','Expected a scalar configuration struct.');end
    names=fieldnames(overrides);
    for k=1:numel(names)
        name=names{k};
        if ~isfield(cfg,name),error('project:Config','Unknown configuration field: %s',name);end
        if isstruct(cfg.(name))&&isscalar(cfg.(name))&&isstruct(overrides.(name))&&isscalar(overrides.(name))
            cfg.(name)=mergeConfig(cfg.(name),overrides.(name));
        else
            cfg.(name)=overrides.(name);
        end
    end
end
