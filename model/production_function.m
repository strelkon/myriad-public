function Y_i=production_function(Q_s_i,alpha_bar_i,N_i,kappa_i,K_i,Y_m,prod_cache)

Y_i_=min(Q_s_i,min(N_i*1.5.*alpha_bar_i,K_i.*kappa_i));

num_fg = numel(prod_cache.idx_fg_flat);
Y_fg_ = zeros(1, num_fg);
for fg=1:num_fg
    inds = prod_cache.idx_fg_flat{fg};
    if ~isempty(inds)
        Y_fg_(fg)=sum(Y_i_(inds));
    end
end

m=zeros(prod_cache.G,1);
for g=1:prod_cache.G
    inds = prod_cache.idx_g_m{g};
    m(g)=sum(Y_m(inds));
end

Y_fg=computeFeasibleOutput(Y_fg_',prod_cache.A,m,prod_cache.C)';

HC_fg=Y_fg./Y_fg_;

if any(HC_fg<1)
    Y_i=Y_i_;
    for fg=1:num_fg
        inds = prod_cache.idx_fg_flat{fg};
        Y_i(inds)=HC_fg(fg).*Y_i_(inds);
    end
else
    Y_i=Y_i_;
end
end

function x = computeFeasibleOutput(x_plan, A, m, C)
% computeFeasibleOutput Computes a feasible industry output vector given:
%
%   - Planned industry outputs x_plan (n_i x 1),
%   - A product-by-industry technological coefficients matrix A (n_p x n_i),
%     where A(i,j) is the amount of product i required per unit output in industry j.
%   - Product-level imports m (n_p x 1),
%   - A mapping matrix C (n_p x n_i) that aggregates industry outputs into products.
%
% The function finds x (n_i x 1) by solving the linear program:
%
%   maximize    sum(x)
%   subject to  x <= x_plan,
%               C*x + m >= A*x,  i.e., (C-A)*x >= -m,
%               x >= 0.
%
% This is reformulated for linprog (which minimizes) as:
%
%   minimize    -sum(x)
%   subject to  x <= x_plan,
%               - (C-A)*x <= m,
%               x >= 0.
%

% Number of industries and products
n_i = length(x_plan);   % number of industries

% Objective: maximize sum(x) is equivalent to minimizing -sum(x)
persistent f_template Aineq1_template lb_template options_template cached_n_i
if isempty(cached_n_i) || cached_n_i ~= n_i
    f_template = -ones(n_i, 1);
    Aineq1_template = eye(n_i);
    lb_template = zeros(n_i, 1);
    options_template = optimoptions('linprog','Display','none');
    cached_n_i = n_i;
end

f = f_template;
Aineq1 = Aineq1_template;
bineq1 = x_plan;

% Constraint 2: Product-level feasibility:
% We require: C*x + m >= A*x, which is equivalent to:
%       (C-A)*x >= -m,
% or
%       - (C-A)*x <= m.
Aineq2 = - (C - A);
bineq2 = m;

% Combine inequality constraints.
Aineq = [Aineq1; Aineq2];
bineq = [bineq1; bineq2];

% Lower bounds: x >= 0.
lb = lb_template;

% Options for linprog (suppress output).
options = options_template;

% Solve the linear program.
[x, ~, exitflag] = linprog(f, Aineq, bineq, [], [], lb, [], options);

if exitflag ~= 1
    error('Linear program did not converge.');
end

end
