function output_options = resolve_output_options(output_options)
if nargin < 1 || isempty(output_options)
    output_options = struct();
elseif islogical(output_options) && isscalar(output_options)
    output_options = struct('include_heavy_diagnostics', output_options);
elseif ~isstruct(output_options)
    error('Output options must be empty, a logical scalar, or a struct.');
end

if ~isfield(output_options, 'include_heavy_diagnostics') || isempty(output_options.include_heavy_diagnostics)
    output_options.include_heavy_diagnostics = true;
else
    output_options.include_heavy_diagnostics = logical(output_options.include_heavy_diagnostics);
end
end
