classdef Mog < handle
    %MOG Class to manage MOGs
    
    properties
        name
        date
        data        % raw data (MogData object)
        av          % index of air shot before survey
        ap          % index of air shot after survey
        Tx          % index of source borehole
        Rx          % index of receiver borehole
        tt          % traveltime vector
        et          % traveltime standard deviation vector
        tt_done     % 
        ttTx
        ttTx_done
        amp_tmin
        amp_tmax
        amp_done
        App
        fcentroid
        scentroid
        tauApp
        tauApp_et
        tauFce
        tauFce_et
        tauHyb
        tauHyb_et
        tau_params
        fw
        f_et
        amp_name_Ldc
        type
        Tx_z_orig
        Rx_z_orig
        fac_dt
        user_fac_dt
        in
        no_traces
        sorted
        TxCosDir
        RxCosDir
        pruneParams
        processParams
        useAirShots
        traces
        delta
        t0_merged
    end
    properties (SetAccess=private)
        ID
    end
    
    methods(Static,Access=private)
        function id = getID(varargin)
            persistent counter;
            if nargin==1
                if isempty(counter)
                    counter = varargin{1};
                else
                    if counter<varargin{1}
                        counter = varargin{1};
                    end
                end
            end
            if isempty(counter)
                counter = 1;
            else
                counter = counter + 1;
            end
            id = counter;
        end
    end
    methods
        function obj = Mog(n)
            if isstring(n) || ischar(n)
                obj.name = n;
                obj.date = '';
                obj.data = MogData.empty;
                obj.av = [];        % no du tir aerien pre acquisition
                obj.ap = [];        % no du tir aerien post acquisition
                obj.Tx = 1;         % no du Tx
                obj.Rx = 1;         % no du Rx
                obj.tau_params = [];
                obj.fw = [];                       % donnees filtrees par transf. ondelettes
                obj.f_et = 1;
                obj.amp_name_Ldc = {};
                obj.type = 1;                      % X-hole (1) ou VRP (2)
                obj.fac_dt = 1;
                obj.user_fac_dt = 0;
                obj.pruneParams.sautTx = 0;
                obj.pruneParams.sautRx = 0;
                obj.pruneParams.arrondi = 0;
                obj.pruneParams.use_SB = 0;
                obj.pruneParams.seuil_SB = 0;
                obj.pruneParams.zmin = -1e99;
                obj.pruneParams.zmax = 1e99;
                obj.pruneParams.thetaMin = -90;
                obj.pruneParams.thetaMax = 90;
                obj.pruneParams.skip_zeros = 1;
                obj.processParams.detrend = 0;
                obj.processParams.bandpass = 0;
                obj.processParams.lowcut = 10;
                obj.processParams.highcut = 200;
                obj.useAirShots = 0;
                obj.traces = [];
                obj.delta = false;
                obj.t0_merged = [];
            elseif isstruct(n)
                if isfield(n, 'name')
                    obj.name = n.name;
                elseif isfield(n, 'nom')
                    obj.name = n.nom;
                else
                    error('Invalid input')
                end
                obj.data = MogData(n.data);
                obj.traces = n.data.rdata;
                if ~isempty(n.av)
                    obj.av = AirShots(n.av);
                end
                if ~isempty(n.ap)
                    obj.ap = AirShots(n.ap);
                end
                obj.Tx = n.Tx;
                obj.Rx = n.Rx;
                obj.tt = n.tt;
                obj.et = n.et;
                if isfield(n, 'tt_done')
                    obj.tt_done = n.tt_done;
                elseif isfield(n, 'tt_fait')
                    obj.tt_done = n.tt_fait;
                end
                if isfield(n, 'ttTx')
                    obj.ttTx = n.ttTx;
                end
                if isfield(n, 'ttTx_done')
                    obj.ttTx_done = n.ttTx_done;
                elseif isfield(n, 'ttTx_fait')
                    obj.ttTx_done = n.ttTx_fait;
                end
                obj.amp_tmin = n.amp_tmin;
                obj.amp_tmax = n.amp_tmax;
                if isfield(n, 'amp_done')
                    obj.amp_done = n.amp_done;
                elseif isfield(n, 'amp_fait')
                    obj.amp_done = n.amp_fait;
                end
                obj.App = n.App;
                obj.fcentroid = n.fcentroid;
                obj.scentroid = n.scentroid;
                obj.tauApp = n.tauApp;
                obj.tauApp_et = n.tauApp_et;
                obj.tauFce = n.tauFce;
                obj.tauFce_et = n.tauFce_et;
                obj.tauHyb = n.tauHyb;
                obj.tauHyb_et = n.tauHyb_et;
                obj.tau_params = n.tau_params;
                obj.fw = n.fw;
                obj.f_et = n.f_et;
                if isfield(n, 'amp_name_Ldc')
                    obj.amp_name_Ldc = n.amp_name_Ldc;
                elseif isfield(n, 'amp_nom_Ldc')
                    obj.amp_name_Ldc = n.amp_nom_Ldc;
                end
                obj.type = n.type;
                obj.Tx_z_orig = n.Tx_z_orig;
                obj.Rx_z_orig = n.Rx_z_orig;
                obj.fac_dt = n.fac_dt;
                obj.user_fac_dt = n.user_fac_dt;
                obj.in = n.in;
                obj.no_traces = n.no_traces;
                if isfield(n, 'sorted')
                    obj.sorted = n.sorted;
                end
                obj.TxCosDir = n.TxCosDir;
                obj.RxCosDir = n.RxCosDir;
                if isfield(n, 'pruneParams')
                    obj.pruneParams = n.pruneParams;
                else
                    obj.pruneParams.sautTx = 0;
                    obj.pruneParams.sautRx = 0;
                    obj.pruneParams.arrondi = 0;
                    obj.pruneParams.use_SB = 0;
                    obj.pruneParams.seuil_SB = 0;
                    obj.pruneParams.zmin = -1e99;
                    obj.pruneParams.zmax = 1e99;
                    obj.pruneParams.thetaMin = -90;
                    obj.pruneParams.thetaMax = 90;
                    obj.pruneParams.skip_zeros = 1;
                end
                if isfield(n, 'processParams')
                    obj.processParams = n.processParams;
                else
                    obj.processParams.detrend = 0;
                    obj.processParams.bandpass = 0;
                    obj.processParams.lowcut = 10;
                    obj.processParams.highcut = 200;
                end

                if isfield(n, 'useAirShots')
                    obj.useAirShots = n.useAirShots;
                else
                    obj.useAirShots = 0;
                end
                obj.delta = false;
                obj.t0_merged = [];
            elseif isa(n, 'Mog')
                obj.name = n.name;
                obj.data = MogData(n.data);
                obj.traces = n.traces;
                obj.av = n.av;
                obj.ap = n.ap;
                obj.Tx = n.Tx;
                obj.Rx = n.Rx;
                obj.tt = n.tt;
                obj.et = n.et;
                obj.tt_done = n.tt_done;
                obj.ttTx = n.ttTx;
                obj.ttTx_done = n.ttTx_done;
                obj.amp_tmin = n.amp_tmin;
                obj.amp_tmax = n.amp_tmax;
                obj.amp_done = n.amp_done;
                obj.App = n.App;
                obj.fcentroid = n.fcentroid;
                obj.scentroid = n.scentroid;
                obj.tauApp = n.tauApp;
                obj.tauApp_et = n.tauApp_et;
                obj.tauFce = n.tauFce;
                obj.tauFce_et = n.tauFce_et;
                obj.tauHyb = n.tauHyb;
                obj.tauHyb_et = n.tauHyb_et;
                obj.tau_params = n.tau_params;
                obj.fw = n.fw;
                obj.f_et = n.f_et;
                obj.amp_name_Ldc = n.amp_name_Ldc;
                obj.type = n.type;
                obj.Tx_z_orig = n.Tx_z_orig;
                obj.Rx_z_orig = n.Rx_z_orig;
                obj.fac_dt = n.fac_dt;
                obj.user_fac_dt = n.user_fac_dt;
                obj.in = n.in;
                obj.no_traces = n.no_traces;
                obj.sorted = n.sorted;
                obj.TxCosDir = n.TxCosDir;
                obj.RxCosDir = n.RxCosDir;
                if ~isempty(n.pruneParams)
                    obj.pruneParams = n.pruneParams;
                else
                    obj.pruneParams.sautTx = 0;
                    obj.pruneParams.sautRx = 0;
                    obj.pruneParams.arrondi = 0;
                    obj.pruneParams.use_SB = 0;
                    obj.pruneParams.seuil_SB = 0;
                    obj.pruneParams.zmin = -1e99;
                    obj.pruneParams.zmax = 1e99;
                    obj.pruneParams.thetaMin = -90;
                    obj.pruneParams.thetaMax = 90;
                    obj.pruneParams.skip_zeros = 1;
                end
                if ~isempty(n.processParams)
                    obj.processParams = n.processParams;
                else
                    obj.processParams.detrend = 0;
                    obj.processParams.bandpass = 0;
                    obj.processParams.lowcut = 10;
                    obj.processParams.highcut = 200;
                end

                obj.useAirShots = n.useAirShots;
                obj.delta = n.delta;
                obj.t0_merged = n.t0_merged;
            else
                error('Invalid input')
            end
            obj.ID = Mog.getID();
        end
        function set.name(obj, n)
            if ischar(n)
                obj.name = n;
            else
                error('MOG name must be a string')
            end
        end
        function set.data(obj, d)
            if isa(d, 'MogData')
                obj.data = d;
                if ~isempty(d)
                    obj.traces = d.rdata;
                end
            else
                error('Data must be a MogData object')
            end
        end
        function [tt,t0] = getCorrectedTravelTimes(obj,air)
            if ~isa(air,'AirShots')
                error('air shot data should be instance of class AirShots')
            end
            if obj.data.synthetique==1
                tt = obj.tt;
                t0 = zeros(size(tt));
                return
            else
                airBefore = air(obj.av);
                airAfter = air(obj.ap);
                [t0,fac_dt_av,fac_dt_ap] = obj.corr_t0(length(obj.tt), ...
                    airBefore, airAfter);
            end
            if ~isempty(obj.av), air( obj.av ).fac_dt = fac_dt_av; end
            if ~isempty(obj.ap), air( obj.ap ).fac_dt = fac_dt_ap; end
            if obj.user_fac_dt==0
                if fac_dt_av~=1 && fac_dt_ap ~= 1
                    obj.fac_dt = 0.5*(fac_dt_av+fac_dt_ap);
                elseif fac_dt_av~=1
                    obj.fac_dt = fac_dt_av;
                elseif fac_dt_ap~=1
                    obj.fac_dt = fac_dt_ap;
                else
                    obj.fac_dt = 1;
                end
            end
            tt = obj.tt;
            
            t0 = obj.fac_dt*t0;
            tt(obj.tt_done) = obj.fac_dt*obj.tt(obj.tt_done) - t0(obj.tt_done);
        end
        function initialize(obj)
            if isempty(obj.data)
                return
            end
            obj.date = obj.data.date;
            
            obj.tt = -1*ones(1,obj.data.ntrace);        % temps d'arrivee
            obj.et = -1*ones(1,obj.data.ntrace);        % ecart-type du temps d'arrivee
            obj.tt_done = false(1,obj.data.ntrace);     % temps d'arrivee determine (booleen)
            if isempty(obj.data.tdata)
                obj.ttTx = [];
                obj.ttTx_done = [];
            else
                obj.ttTx = zeros(1,obj.data.ntrace);        % temps d'arrivee
                obj.ttTx_done = false(1,obj.data.ntrace);   % temps d'arrivee determine (booleen)
            end
            obj.amp_tmin = -1*ones(1,obj.data.ntrace);  % t min fenetre de determination Amplitude
            obj.amp_tmax = -1*ones(1,obj.data.ntrace);  % t max fenetre de determination Amplitude
            obj.amp_done = false(1,obj.data.ntrace);    % fenetre de determination Amplitude determinee (booleen)
            obj.App = zeros(1,obj.data.ntrace);         % Amp pic a pic
            obj.fcentroid = zeros(1,obj.data.ntrace);   % freq centroide
            obj.scentroid = zeros(1,obj.data.ntrace);   % variance centroide
            obj.tauApp = -1*ones(1,obj.data.ntrace);       % amplitudes corrigees - amplitude ratio
            obj.tauApp_et = -1*ones(1,obj.data.ntrace);    % ecart-type des amplitudes corrigees
            obj.tauFce = -1*ones(1,obj.data.ntrace);       % amplitudes corrigees - freq centroide
            obj.tauFce_et = -1*ones(1,obj.data.ntrace);    % ecart-type des amplitudes corrigees
            obj.tauHyb = -1*ones(1,obj.data.ntrace);       % amplitudes corrigees - meth. hybride
            obj.tauHyb_et = -1*ones(1,obj.data.ntrace);    % ecart-type des amplitudes corrigees
            obj.Tx_z_orig = obj.data.Tx_z;
            obj.Rx_z_orig = obj.data.Rx_z;
            obj.in = true(1,obj.data.ntrace);
            obj.pruneParams.zmin = min([obj.data.Tx_z obj.data.Rx_z]);
            obj.pruneParams.zmax = max([obj.data.Tx_z obj.data.Rx_z]);
            obj.traces = obj.data.rdata;
        end
        function sort_by_Tx(obj)
            uTx_z = sort(unique(obj.Tx_z_orig));
            ind = zeros(1, obj.data.ntrace);
            start = 0;
            for n=1:numel(uTx_z)
                nos = find(uTx_z(n) == obj.Tx_z_orig);
                nfound = numel(nos);
                ind(start+(1:nfound)) = nos;
                start = start+nfound;
            end
            obj.tt = obj.tt(ind);
            obj.et = obj.et(ind);
            obj.tt_done = obj.tt_done(ind);
            obj.ttTx = obj.ttTx(ind);
            obj.ttTx_done = obj.ttTx_done(ind);
            obj.amp_tmin = obj.amp_tmin(ind);
            obj.amp_tmax = obj.amp_tmax(ind);
            obj.amp_done = obj.amp_done(ind);
            obj.App = obj.App(ind);
            obj.fcentroid = obj.fcentroid(ind);
            obj.scentroid = obj.scentroid(ind);
            obj.tauApp = obj.tauApp(ind);
            obj.tauApp_et = obj.tauApp_et(ind);
            obj.tauFce = obj.tauFce(ind);
            obj.tauFce_et = obj.tauFce_et(ind);
            obj.tauHyb = obj.tauHyb(ind);
            obj.tauHyb_et = obj.tauHyb_et(ind);
            obj.Tx_z_orig = obj.Tx_z_orig(ind);
            obj.Rx_z_orig = obj.Rx_z_orig(ind);
            obj.in = obj.in(ind);
            obj.no_traces = obj.no_traces(ind);
            obj.TxCosDir = obj.TxCosDir(ind, :);
            obj.RxCosDir = obj.RxCosDir(ind, :);
            obj.data.rdata = obj.data.rdata(:, ind);
            obj.traces = obj.traces(:, ind);
            obj.data.Tx_x = obj.data.Tx_x(ind);
            obj.data.Tx_y = obj.data.Tx_y(ind);
            obj.data.Tx_z = obj.data.Tx_z(ind);
            obj.data.Rx_x = obj.data.Rx_x(ind);
            obj.data.Rx_y = obj.data.Rx_y(ind);
            obj.data.Rx_z = obj.data.Rx_z(ind);
        end
        
        function [t0,fac_dt_av,fac_dt_ap] = corr_t0(obj,ndata,before,after,varargin)
            if nargin>=5
                show = varargin{1};
            else
                show = false;
            end
            fac_dt_av = 1;
            fac_dt_ap = 1;
            if obj.useAirShots==0
                t0 = zeros(1,ndata);
                return
            elseif isempty(before) && isempty(after) && obj.useAirShots==1
                warndlg({'t0 correction not applied';
                    'Pick t0 before and t0 after for correction'})
                t0 = zeros(1,ndata);
                return
            end
            v_air = 0.2998;  % this correction for radar
            t0av = [];
            t0ap = [];
            if ~isempty(before)
                if strcmp(before.method, 'fixed_antenna')
                    t0av = Mog.get_t0_fixed(before, v_air);
                elseif strcmp(before.method, 'walkaway')
                    [t0av, fac_dt_av] = Mog.get_t0_wa(before, v_air, show);
                end
            end
            if ~isempty(after)
                if strcmp(after.method, 'fixed_antenna')
                    t0ap = Mog.get_t0_fixed(after, v_air);
                elseif strcmp(after.method, 'walkaway')
                    [t0ap, fac_dt_ap] = Mog.get_t0_wa(after, v_air, show);
                end
            end
            if isempty(t0av) && isempty(t0ap)
                t0 = zeros(1,ndata);
            elseif isempty(t0av)
                if isnan(t0ap)
                    warndlg({'t0 correction not applied';
                        'Pick t0 before and t0 after for correction'})
                    t0 = zeros(1,ndata);
                    return
                end
                t0 = t0ap*ones(1,ndata);
            elseif isempty(t0ap)
                if isnan(t0av)
                    warndlg({'t0 correction not applied';
                        'Pick t0 before and t0 after for correction'})
                    t0 = zeros(1,ndata);
                    return
                end
                t0 = t0av*ones(1,ndata);
            elseif isnan(t0av) || isnan(t0ap)
                warndlg({'t0 correction not applied';
                    'Pick t0 before and t0 after for correction'})
                t0 = zeros(1,ndata);
                return
            else
                dt0 = t0ap-t0av;
                ddt0 = dt0/(ndata-1);
                t0 = t0av+ddt0*(0:(ndata-1));
            end
        end
    end
    
    methods (Static)
        function obj = loadobj(a)
            obj = a;
            Mog.getID(obj.ID);  % we must update counter
        end
        function t0 = get_t0_fixed(tir, v)
            times = tir.tt(tir.tt_done);
            std_times = tir.et(tir.tt_done);
            ind = times~=-1;
            if all(std_times == -1)
                times = mean(times(ind));
            else
                times = sum(times(ind).*std_times(ind))/sum(std_times(ind));
            end
            t0 = times - tir.d_TxRx/v;
        end
        function [t0, fac] = get_t0_wa(tir, v, show)
            ind = tir.tt~=-1;
            times = tir.tt(tir.tt_done & ind)';
            std_times = tir.et(tir.tt_done & ind)';
            d = tir.d_TxRx(tir.tt_done & ind)';
            slown = 1/v;
            if all(std_times == -1)
                b = [d ones(size(d))]\times;
                t0 = b(2);
                %app_slowness = b(1);
                %fac = true_slowness/app_slowness;
                fac = slown/b(1);
                if show
                    figure('Name','Air shot')
                    plot(d,times,'o')
                    hold on
                    plot([0;d],b(1)*[0;d]+b(2),'k')
                    xlabel('Distance')
                    ylabel('Time')
                    title([tir.name,' - correction factor: ',num2str(fac)], 'Interpreter','none')
                    text(d(2), b(1), ['t_0 at ',num2str(t0)])
                    hold off
                end
            else
                W = diag(1./(std_times.^2));
                x = [d ones(size(d))];
                b = (x'*W*x)\(x'*W*times);
                t0 = b(2);
                fac = slown/b(1);
                if show
                    figure('Name','Air shot')
                    subplot(121)
                    plot([0;d],b(1)*[0;d]+b(2),'k','LineWidth',1)
                    hold on
                    errorbar(d,times,std_times,'o')
                    xlabel('Distance')
                    ylabel('Time')
                    title([tir.name,' - correction factor: ',num2str(fac)], 'Interpreter','none')
                    text(d(2), b(1), ['t_0 at ',num2str(t0)])
                    ylim=get(gca,'YLim');
                    ylim(1)=0;
                    set(gca,'YLim',ylim)
                    hold off
                    subplot(122)
                    plot([0;d],slown*[0;d]+b(2)*fac,'g','LineWidth',1)
                    hold on
                    errorbar(d,times*fac,std_times,'o')
                    xlabel('Distance')
                    ylabel('Time')
                    title('After \Delta t correction')
                    text(d(2), b(1), ['t_0 at ',num2str(t0*fac)])
                    ylim=get(gca,'YLim');
                    ylim(1)=0;
                    set(gca,'YLim',ylim)
                    hold off
                end
            end
        end
    end
    
end
        
