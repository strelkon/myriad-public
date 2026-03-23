function cache = build_simulation_cache(year, quarter, scenario, scale, T)
base_dir = fileparts(mfilename('fullpath'));
scale_str = ['_', num2str(round(1/scale))];

data_dir = iResolveDataDir(base_dir, year, quarter, scale_str);

parameters = load(fullfile(data_dir, 'parameters', [num2str(year), 'Q', num2str(quarter), scale_str, '.mat']), ...
    'T', 'T_max', 'S', 'G', 'H_act', 'H_inact', 'J', 'L', 'tau_INC', 'tau_FIRM', 'tau_VAT', 'tau_SIF', 'tau_SIW', ...
    'tau_EXPORT', 'tau_CF', 'tau_G', 'theta_UB', 'psi', 'psi_H', 'theta_DIV', 'theta', 'mu', 'r_G', 'zeta', ...
    'zeta_LTV', 'zeta_b', 'I_sr', 'alpha_sr', 'beta_sr', 'kappa_sr', 'delta_sr', 'w_sr', 'tau_Y_sr', 'tau_K_sr', ...
    'b_CF_g', 'b_CFH_g', 'b_HH_g', 'c_G_g', 'c_E_g', 'c_I_g', 'a_sg', 'T_prime', 'pi_star', 'alpha_gamma_G', ...
    'beta_gamma_G', 'alpha_gamma_E', 'beta_gamma_E', 'alpha_gamma_I', 'beta_gamma_I', 'alpha_pi_G', 'beta_pi_G', ...
    'alpha_pi_E', 'beta_pi_E', 'alpha_pi_I', 'beta_pi_I', 'C', 'F', 's_a_ffsg', 's_CF_ffg', 's_CFH_ffg', ...
    's_HH_ffg', 's_G_ffg', 's_E_fg');

initial_conditions = load(fullfile(data_dir, 'initial_conditions', [num2str(year), 'Q', num2str(quarter), scale_str, '.mat']), ...
    'D_H', 'D_I', 'D_RoW', 'E_CB', 'E_k', 'K_H', 'L_G', 'L_I', 'omega', 'sb_inact', 'sb_other', 'w_UB', 'N_sr', ...
    'Y', 'gamma', 'pi', 'P', 'r_bar', 'gamma_G', 'C_G', 'pi_G', 'P_G', 'gamma_E', 'C_E', 'pi_E', 'P_E', 'gamma_I', ...
    'Y_I', 'pi_I', 'P_I', 'Y_f', 'gamma_f', 'pi_f', 'P_f');

if ~strcmp(scenario, 'S0')
    shock = load(fullfile(data_dir, 'shock', [scenario, '.mat']));
else
    shock = struct();
end

F = parameters.F;
G = 62;
I_sr = parameters.I_sr;
I = sum(I_sr, 'all');

G_i = zeros(1, I);
F_i = zeros(1, I);
idx_fg_i = cell(F, G);
idx_f_i = cell(1, F);
idx_fg_flat = cell(1, F * G);

cursor = 1;
for f = 1:F
    idx_f_i{f} = zeros(1, sum(I_sr(:, f)));
end
f_cursor = ones(1, F);

for g = 1:G
    for f = 1:F
        count = I_sr(g, f);
        if count > 0
            inds = cursor:(cursor + count - 1);
            G_i(inds) = g;
            F_i(inds) = f;
            idx_fg_i{f, g} = inds;
            f_inds = f_cursor(f):(f_cursor(f) + count - 1);
            idx_f_i{f}(f_inds) = inds;
            f_cursor(f) = f_cursor(f) + count;
            cursor = cursor + count;
        else
            idx_fg_i{f, g} = zeros(1, 0);
        end
    end
end

flat_idx = 1;
for f = 1:F
    for g = 1:G
        idx_fg_flat{flat_idx} = idx_fg_i{f, g};
        flat_idx = flat_idx + 1;
    end
end

alpha_bar_i = zeros(1, I);
beta_i = zeros(1, I);
kappa_i = zeros(1, I);
w_bar_i = zeros(1, I);
delta_i = zeros(1, I);
tau_Y_i = zeros(1, I);
tau_K_i = zeros(1, I);
for f = 1:F
    for g = 1:G
        inds = idx_fg_i{f, g};
        if isempty(inds)
            continue;
        end
        alpha_bar_i(inds) = parameters.alpha_sr(g, f);
        beta_i(inds) = parameters.beta_sr(g, f);
        kappa_i(inds) = parameters.kappa_sr(g, f);
        w_bar_i(inds) = parameters.w_sr(g, f);
        delta_i(inds) = parameters.delta_sr(g, f);
        tau_Y_i(inds) = parameters.tau_Y_sr(g, f);
        tau_K_i(inds) = parameters.tau_K_sr(g, f);
    end
end

I_ms = max(1, round(nansum(I_sr, 2) ./ nansum(parameters.alpha_sr .* initial_conditions.N_sr, 2) .* parameters.c_I_g * initial_conditions.Y_I(parameters.T_prime)));
N_ms = max(1, round(nansum(initial_conditions.N_sr, 2) ./ nansum(parameters.alpha_sr .* initial_conditions.N_sr, 2) .* parameters.c_I_g * initial_conditions.Y_I(parameters.T_prime)));

M = sum(I_ms);
G_m = zeros(1, M);
idx_g_m = cell(1, G);
cursor = 1;
for g = 1:G
    inds = cursor:(cursor + I_ms(g) - 1);
    G_m(inds) = g;
    idx_g_m{g} = inds;
    cursor = cursor + I_ms(g);
end

prod_A = zeros(G, F * G);
prod_C = zeros(G, F * G);
flat_idx = 1;
for f = 1:F
    for g = 1:G
        if ~isempty(idx_fg_i{f, g})
            prod_A(:, flat_idx) = parameters.a_sg(:, g, f) ./ parameters.beta_sr(g, f);
        end
        prod_C(g, flat_idx) = 1;
        flat_idx = flat_idx + 1;
    end
end

gamma_K_gr = zeros(T, F, G);
gamma_X_i = zeros(T, I);
gamma_X_I = zeros(T, G);
if ~strcmp(scenario, 'S0')
    if isfield(shock, 'gamma_K_gr')
        t_shock = min(T, size(shock.gamma_K_gr, 1));
        gamma_K_gr(1:t_shock, :, :) = shock.gamma_K_gr(1:t_shock, :, :);
    end
    if isfield(shock, 'gamma_X_gr')
        t_shock = min(T, size(shock.gamma_X_gr, 1));
        for f = 1:F
            for g = 1:G
                inds = idx_fg_i{f, g};
                if ~isempty(inds)
                    gamma_X_i(1:t_shock, inds) = repmat(shock.gamma_X_gr(1:t_shock, f, g), 1, numel(inds));
                end
            end
        end
    end
    if isfield(shock, 'gamma_X_I')
        t_shock = min(T, size(shock.gamma_X_I, 1));
        gamma_X_I(1:t_shock, :) = shock.gamma_X_I(1:t_shock, :);
    end
end

cache = struct();
cache.G = G;
cache.F = F;
cache.I_sr = I_sr;
cache.parameters = parameters;
cache.initial_conditions = initial_conditions;
cache.G_i = G_i;
cache.F_i = F_i;
cache.idx_fg_i = idx_fg_i;
cache.idx_f_i = idx_f_i;
cache.idx_fg_flat = idx_fg_flat;
cache.idx_g_m = idx_g_m;
cache.FG_linear = sub2ind([F, G], F_i, G_i);
cache.alpha_bar_i = alpha_bar_i;
cache.beta_i = beta_i;
cache.kappa_i = kappa_i;
cache.w_bar_i = w_bar_i;
cache.delta_i = delta_i;
cache.tau_Y_i = tau_Y_i;
cache.tau_K_i = tau_K_i;
cache.I_ms = I_ms;
cache.N_ms = N_ms;
cache.G_m = G_m;
cache.gamma_K_gr = gamma_K_gr;
cache.gamma_X_i = gamma_X_i;
cache.gamma_X_I = gamma_X_I;
cache.prod_cache = struct();
cache.prod_cache.A = prod_A;
cache.prod_cache.C = prod_C;
cache.prod_cache.C_minus_A = prod_C - prod_A;
cache.prod_cache.idx_fg_flat = idx_fg_flat;
cache.prod_cache.idx_g_m = idx_g_m;
cache.prod_cache.G = G;
end

function data_dir = iResolveDataDir(base_dir, year, quarter, scale_str)
filename = [num2str(year), 'Q', num2str(quarter), scale_str, '.mat'];
local_path = fullfile(base_dir, 'parameters', filename);
if exist(local_path, 'file')
    data_dir = base_dir;
    return;
end

home_dir = getenv('HOME');
home_path = fullfile(home_dir, 'parameters', filename);
if ~isempty(home_dir) && exist(home_path, 'file')
    data_dir = home_dir;
    return;
end

error('build_simulation_cache:MissingDataDir', ...
    'Could not find %s under %s or %s.', filename, base_dir, home_dir);
end
